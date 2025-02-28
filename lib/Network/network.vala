public class NetworkManager : Object {
	private static NetworkManager _instance;
	private NM.DeviceWifi? _wifi_device;
	private NM.AccessPoint? _active_ap;
	private string? _active_ssid;
	private NM.Client _client;
	private bool _wireless_enabled;

	private enum SignalStrength {
		WEAK = 30,
		OK = 55,
		GOOD = 80,
		EXCELLENT = 100
	}

	public signal void access_point_added(NM.AccessPoint ap);
	public signal void access_point_removed(NM.AccessPoint ap);
	public signal void active_ap_changed();

	public static NetworkManager get_default() {
		if (_instance == null) {
			_instance = new NetworkManager();
		}
		return _instance;
	}

	private NetworkManager() {
		try {
			_client = new NM.Client();
			_client.device_added.connect(check_wifi_device);
			_client.device_removed.connect(check_wifi_device);
			_client.notify["wireless-enabled"].connect(() => {
				notify_property("wireless-enabled");
			});
			check_wifi_device();
		} catch (Error e) {
			critical("Failed to create NM.Client: %s", e.message);
		}
	}

	public bool wireless_enabled {
		get {
			_wireless_enabled = _client.wireless_enabled;
			return _wireless_enabled;
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
			if (_active_ap == null) {
				return "network-wireless-offline-symbolic";
			}

			return get_icon_for_strength(_active_ap.get_strength());
		}
	}

	private unowned string get_icon_for_strength(uint8 strength) {
		if (strength > SignalStrength.GOOD) {
			return "network-wireless-signal-excellent-symbolic";
		} else if (strength > SignalStrength.OK) {
			return "network-wireless-signal-good-symbolic";
		} else if (strength > SignalStrength.WEAK) {
			return "network-wireless-signal-ok-symbolic";
		}
		return "network-wireless-signal-weak-symbolic";
	}

	public unowned string ssid {
		get {
			if (_active_ap == null) {
				_active_ssid = "";
			} else if (_active_ssid == null) {
				_active_ssid = NM.Utils.ssid_to_utf8(_active_ap.get_ssid().get_data());
			}
			return _active_ssid;
		}
	}

	public NM.AccessPoint? active_ap {
		get { return _active_ap; }
	}

	private void check_wifi_device() {
		_wifi_device = find_wifi_device();

		if (_wifi_device != null) {
			_wifi_device.access_point_added.connect((device, ap_obj) => {
				var ap = ap_obj as NM.AccessPoint;
				if (ap != null) {
					access_point_added(ap);
				}
			});
			_wifi_device.access_point_removed.connect((device, ap_obj) => {
				var ap = ap_obj as NM.AccessPoint;
				if (ap != null) {
					access_point_removed(ap);
				}
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
		var new_ap = _wifi_device.get_active_access_point();
		if (_active_ap != new_ap) {
			_active_ap = new_ap;
			_active_ssid = null;
			active_ap_changed();
		}
	}

	public void scan_access_points() {
		if (_wifi_device != null) {
			_wifi_device.request_scan_async.begin(null);
		}
	}

	public List<weak NM.AccessPoint> get_access_points() {
		var result = new List<weak NM.AccessPoint>();
		if (_wifi_device != null) {
			var array = _wifi_device.get_access_points();
			for (int i = 0; i < array.length; i++) {
				result.append(array.get(i) as unowned NM.AccessPoint);
			}
		}
		return result;
	}
}
