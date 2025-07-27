[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	public AstalNetwork.Network network { get; set; }
	private GenericArray<QNetworkItem> network_items;

	[GtkChild]
	private unowned Gtk.ListBox wifi_list;

	construct {
		network = AstalNetwork.get_default();
		network_items = new GenericArray<QNetworkItem>();

		// Set up sorting function for ListBox
		wifi_list.set_sort_func(sort_network_items);

		// Listen for access point changes
		//  network.wifi.notify["access-points"].connect(refresh_items);

		// Listen for active connection changes and update all items
		network.wifi.notify["active-access-point"].connect(update_active_states);

		// Initial population
		refresh_items();
	}

	private int sort_network_items(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = (QNetworkItem)row1;
		var item2 = (QNetworkItem)row2;

		return item1.compare_to(item2);
	}

	// Absolute rubbish
	private void refresh_items() {
		wifi_list.remove_all();
		network_items.remove_range(0, network_items.length);

		// Add new items
		network.wifi.access_points.foreach((ap) => {
			if (ap.ssid != null && ap.ssid != "") {
				var item = new QNetworkItem(ap, network);
				network_items.add(item);
				wifi_list.append(item);
			}
		});

		// Update active states for all items
		update_active_states();

		// Trigger resort
		wifi_list.invalidate_sort();
	}

	private void update_active_states() {
		var active_ap = network.wifi.active_access_point;

		for (uint i = 0; i < network_items.length; i++) {
			network_items[i].update_active_state(active_ap);
		}

		// Trigger resort since active state affects sorting
		wifi_list.invalidate_sort();
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
		refresh_items();
	}
}
