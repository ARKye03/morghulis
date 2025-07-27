[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	public AstalNetwork.Network network { get; set; }
	private NM.DeviceWifi _wifi_dev;
	private HashTable<string, QNetworkItem> network_items_map;

	[GtkChild]
	private unowned Gtk.ListBox wifi_list;

	construct {
		network = AstalNetwork.get_default();
		network_items_map = new HashTable<string, QNetworkItem>(str_hash, str_equal);
		_wifi_dev = network.wifi.device;

		// Set up sorting function for ListBox
		wifi_list.set_sort_func(sort_network_items);

		// Connect to NM signals for efficient access point tracking
		_wifi_dev.access_point_added.connect(on_access_point_added);
		_wifi_dev.access_point_removed.connect(on_access_point_removed);

		// Listen for active connection changes and update all items
		network.wifi.notify["active-access-point"].connect(update_active_states);

		// Initial population
		network.wifi.access_points.foreach(add_access_point);
		update_active_states();
	}

	private int sort_network_items(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = (QNetworkItem)row1;
		var item2 = (QNetworkItem)row2;

		return item1.compare_to(item2);
	}

	private void add_access_point(AstalNetwork.AccessPoint ap) {
		if (ap.ssid == null || ap.ssid == "") {
			return;
		}

		// Check if we already have this access point
		if (network_items_map.contains(ap.ssid)) {
			return;
		}

		var item = new QNetworkItem(ap, network);
		network_items_map.set(ap.ssid, item);
		wifi_list.append(item);
	}

	private void on_access_point_added(GLib.Object nm_ap_obj) {
		var nm_ap = (NM.AccessPoint)nm_ap_obj;

		if (nm_ap == null) {
			return;
		}

		var ssid_bytes = nm_ap.get_ssid();
		if (ssid_bytes == null) {
			return;
		}

		var ssid = (string)ssid_bytes.get_data();
		if (ssid == null || ssid == "") {
			return;
		}

		// Find the corresponding AstalNetwork.AccessPoint

		if (network_items_map.contains(ssid)) {
			return;
		} else {
			add_access_point(network_items_map.get(ssid).access_point);
		}
	}

	private void on_access_point_removed(GLib.Object nm_ap_obj) {
		var nm_ap = nm_ap_obj as NM.AccessPoint;

		if (nm_ap == null) {
			return;
		}

		var ssid_bytes = nm_ap.get_ssid();
		if (ssid_bytes == null) {
			return;
		}

		var ssid = (string)ssid_bytes.get_data();
		if (ssid != null && ssid != "") {
			var item = network_items_map.get(ssid);
			if (item != null) {
				network_items_map.remove(ssid);
				wifi_list.remove(item);
			}
		}
	}

	private void update_active_states() {
		var active_ap = network.wifi.active_access_point;

		if (active_ap == null) {
			return;
		}

		network_items_map.foreach((ssid, item) => {
			item.update_active_state(active_ap.ssid);
		});

		// Trigger resort since active state affects sorting
		wifi_list.invalidate_sort();
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
		// After scanning, new access points will be automatically added via signals
		// and removed ones will be automatically removed
		update_active_states();
		wifi_list.invalidate_sort();
	}
}
