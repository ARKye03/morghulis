[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	private NM.DeviceWifi _net_dev;

	public AstalNetwork.Network network { get; set; }

	[GtkChild]
	private unowned Gtk.ListBox wifi_list;

	construct {
		network = AstalNetwork.get_default();
		_net_dev = network.wifi.device;

		wifi_list.set_sort_func(sort_network_items);

		_net_dev.access_point_added.connect(on_added_ap);
		_net_dev.access_point_removed.connect(on_removed_ap);
		network.wifi.notify["active-access-point"].connect(update_active_states);

		network.wifi.access_points.foreach(add_astal_ap);
		update_active_states();
	}

	private void on_added_ap(Object ap) {
		if (ap == null || ap.get_type() != typeof(NM.AccessPoint)) {
			return;
		}
		var nap = (NM.AccessPoint)ap;
		var nap_ssid = (string)nap.ssid.get_data();
		debug(@"Adding AP $(nap_ssid)");
		network.wifi.access_points.foreach((ap) => {
			if (ap.ssid == nap_ssid) {
				add_astal_ap(ap);
			}
		});
	}

	private void add_astal_ap(AstalNetwork.AccessPoint ap) {
		var item = new QNetworkItem(ap, network);

		wifi_list.append(item);
	}

	private void on_removed_ap(Object ap) {
		if (ap == null || ap.get_type() != typeof(NM.AccessPoint)) {
			return;
		}
		var nap_ssid = (string)((NM.AccessPoint)ap).ssid.get_data();
		debug(@"Removing AP $(nap_ssid)");

		var current = (QNetworkItem)wifi_list.get_first_child();

		while (current != null) {
			if (current.access_point.ssid == nap_ssid) {
				wifi_list.remove(current);
				return;
			}
			current = (QNetworkItem)current.get_next_sibling();
		}
	}

	private int sort_network_items(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = (QNetworkItem)row1;
		var item2 = (QNetworkItem)row2;

		return item1.compare_to(item2);
	}

	private void update_active_states() {
		var active_ap_ssid = network.wifi.active_access_point.ssid;

		if (active_ap_ssid == null || active_ap_ssid == "") {
			return;
		}

		var current = (QNetworkItem)wifi_list.get_first_child();

		while (current != null) {
			if (current.access_point.ssid == active_ap_ssid) {
				current.active = true;
				break;
			} else {
				current.active = false;
			}
			current = (QNetworkItem)current.get_next_sibling();
		}

		wifi_list.invalidate_sort();
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
	}
}
