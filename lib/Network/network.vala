private enum SignalStrength {
	WEAK = 30,
	OK = 55,
	GOOD = 80,
	EXCELLENT = 100
}

public class NetworkManager : GLib.Object {
	private static NetworkManager _instance;
	private NM.DeviceWifi? _wifi_device;
	private string? _active_ssid;
	private NM.Client _client;
	private bool _wireless_enabled;
	private GLib.HashTable<string, AccessPoint> _access_points;
	private AccessPoint? _active_access_point;

	public signal void access_point_added(AccessPoint ap);
	public signal void access_point_removed(AccessPoint ap);
	public signal void active_ap_changed(AccessPoint? ap);
	public signal void connection_state_changed(NM.ActiveConnectionState state, uint reason);

	public static NetworkManager get_default() {
		if (_instance == null) {
			_instance = new NetworkManager();
		}
		return _instance;
	}

	public AccessPoint? active_ap {
		get {
			return _active_access_point;
		}
	}

	public bool wireless_enabled {
		get {
			return _client.wireless_enabled;
		}
		set {
			if (_wireless_enabled != value) {
				_client.wireless_enabled = value;
				_wireless_enabled = value;
			}
		}
	}

	public unowned string icon_name {
		get {
			if (active_ap == null) {
				return "network-wireless-offline-symbolic";
			}

			return active_ap.icon_name;
		}
	}

	private NetworkManager() {
		_access_points = new GLib.HashTable<string, AccessPoint>(str_hash, str_equal);

		try {
			_client = new NM.Client();
			_client.device_added.connect(check_wifi_device);
			_client.device_removed.connect(check_wifi_device);
			_client.notify["wireless-enabled"].connect(() => {
				notify_property("wireless-enabled");
			});

			// Monitor active connections
			_client.active_connection_added.connect(connection_added);
			_client.active_connection_removed.connect(connection_removed);

			check_wifi_device();
		} catch (Error e) {
			critical("Failed to create NM.Client: %s", e.message);
		}
	}

	private void connection_added(NM.ActiveConnection connection) {
		connection.notify["state"].connect((s, p) => {
			update_active_connection_state(connection);
		});
		update_active_connection_state(connection);
	}

	private void connection_removed(NM.ActiveConnection connection) {
		// Nothing to do here, handled by device state changes
	}

	private void update_active_connection_state(NM.ActiveConnection connection) {
		if (connection.get_devices().length < 1) {
			return;
		}

		foreach (var device in connection.get_devices()) {
			if (device == _wifi_device) {
				connection_state_changed(connection.get_state(), connection.get_state_reason());
				break;
			}
		}
	}

	public unowned string active_ap_ssid {
		get {
			if (active_ap == null) {
				return "";
			}
			return active_ap.ssid;
		}
	}

	private void check_wifi_device() {
		_wifi_device = find_wifi_device();

		if (_wifi_device != null) {
			_wifi_device.access_point_added.connect((device, ap_obj) => {
				var ap = AccessPoint.@for(ap_obj as NM.AccessPoint);
				_access_points.insert(ap.ssid, ap);
				access_point_added(ap);
			});
			_wifi_device.access_point_removed.connect((device, ap_obj) => {
				var ap = AccessPoint.@for(ap_obj as NM.AccessPoint);
				_access_points.remove(ap.ssid);
				access_point_removed(ap);
			});
			_wifi_device.notify["active-access-point"].connect(() => {
				update_active_ap();
			});

			scan_access_points();
			update_active_ap();
		}
	}

	private NM.DeviceWifi? find_wifi_device() {
		NM.DeviceWifi? result = null;
		_client.get_devices().foreach((device) => {
			if (device.get_device_type() == NM.DeviceType.WIFI) {
				result = device as NM.DeviceWifi;
				return;
			}
		});
		return result;
	}

	private void update_active_ap() {
		var nm_ap = _wifi_device?.get_active_access_point();
		var new_ap = nm_ap != null? AccessPoint.@for(nm_ap) : null;

		if (_active_access_point != new_ap) {
			_active_access_point = new_ap;
			_active_ssid = null;
			active_ap_changed(_active_access_point);
		}
	}

	public void scan_access_points() {
		if (_wifi_device != null) {
			try {
				_wifi_device.request_scan_async.begin(null);
			} catch (Error e) {
				warning("Failed to request wireless scan: %s", e.message);
			}

			// Update the access points collection
			var aps = _wifi_device.get_access_points();
			if (aps != null) {
				for (int i = 0; i < aps.length; i++) {
					var ap = AccessPoint.@for(aps.get(i) as NM.AccessPoint);
					_access_points.insert(ap.ssid, ap);
				}
			}
		}
	}

	public List<weak AccessPoint> get_access_points() {
		List<weak AccessPoint> result = new List<weak AccessPoint>();
		_access_points.foreach((key, value) => {
			result.append(value);
		});
		return result.copy();
	}

	// Connection handling
	public async void connect_to_ap(AccessPoint ap, string? password = null) throws Error {
		if (_wifi_device == null) {
			throw new IOError.FAILED("No WiFi device available");
		}

		// Check if we already have a connection for this AP
		var connection = find_connection_for_ap(ap.nm_ap);

		if (connection == null) {
			// Create a new connection
			connection = NM.SimpleConnection.new();

			// Wireless settings
			var s_wireless = new NM.SettingWireless();
			s_wireless.ssid = ap.nm_ap.get_ssid();
			connection.add_setting(s_wireless);

			// Connection settings
			var s_con = new NM.SettingConnection();
			s_con.id = ap.ssid;
			s_con.type = "802-11-wireless";
			connection.add_setting(s_con);

			// Security settings if needed
			if (ap.is_secure && password != null) {
				var s_wsec = new NM.SettingWirelessSecurity();
				s_wsec.key_mgmt = "wpa-psk";
				s_wsec.psk = password;
				connection.add_setting(s_wsec);
			}
		}

		// Activate the connection
		yield _client.activate_connection_async(connection, _wifi_device, null, null);
	}

	public async void disconnect_wifi() throws Error {
		if (_wifi_device == null) {
			return;
		}

		_wifi_device.disconnect_async.begin(null);
	}

	private NM.Connection? find_connection_for_ap(NM.AccessPoint ap) {
		foreach (var conn in _client.get_connections()) {
			var settings_wireless = conn.get_setting_wireless();
			if (settings_wireless != null && settings_wireless.get_ssid().compare(ap.get_ssid()) == 0) {
				return conn;
			}
		}
		return null;
	}
}
