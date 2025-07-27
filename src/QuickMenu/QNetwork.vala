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
		network.wifi.notify["access-points"].connect(refresh_items);

		// Initial population
		refresh_items();
	}

	private int sort_network_items(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = (QNetworkItem)row1;
		var item2 = (QNetworkItem)row2;

		return item1.compare_to(item2);
	}

	private void refresh_items() {
		// Clear existing items
		clear_list();

		// Add new items
		network.wifi.access_points.foreach((ap) => {
			if (ap.ssid != null && ap.ssid != "") {
				var item = new QNetworkItem(ap, network);
				network_items.add(item);
				wifi_list.append(item);
			}
		});

		// Trigger resort
		wifi_list.invalidate_sort();
	}

	private void clear_list() {
		// Remove all children from ListBox
		var child = wifi_list.get_first_child();

		while (child != null) {
			var next = child.get_next_sibling();
			wifi_list.remove(child);
			child = next;
		}

		// Clear our tracking list
		network_items.remove_range(0, network_items.length);
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
	}
}
