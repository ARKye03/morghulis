[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	public NetworkManager network { get; set; }

	[GtkChild]
	private unowned Gtk.ListBox wifi_list;

	construct {
		network = NetworkManager.get_default();

		// Set up ListBox sorting by signal strength
		wifi_list.set_sort_func((row1, row2) => {
			var item1 = ((WifiRow)row1).wifi_item;
			var item2 = ((WifiRow)row2).wifi_item;
			return item2.access_point.strength - item1.access_point.strength;                                                             // Higher strength first
		});

		// Connect signals for access point changes
		network.access_point_added.connect(add_access_point);
		network.access_point_removed.connect(remove_access_point);

		// Initial population
		refresh_items();
	}

	private void add_access_point(AccessPoint ap) {
		// Check if we already have this AP in the list
		var current = (WifiRow)wifi_list.get_first_child();

		while (current != null) {
			if (current.wifi_item.access_point.ssid == ap.ssid) {
				// Update the existing item
				current.wifi_item.access_point = ap;
				wifi_list.invalidate_sort();
				return;
			}
			current = (WifiRow)current.get_next_sibling();
		}

		var item = new WifiItem(ap);
		var row = new WifiRow(item);
		wifi_list.append(row);
		wifi_list.invalidate_sort();
	}

	private void remove_access_point(AccessPoint ap) {
		var current = (WifiRow)wifi_list.get_first_child();

		while (current != null) {
			if (current.wifi_item.access_point.ssid == ap.ssid) {
				wifi_list.remove(current);
				return;
			}
			current = (WifiRow)current.get_next_sibling();
		}
	}

	private void refresh_items() {
		var current = wifi_list.get_first_child();

		while (current != null) {
			var next = current.get_next_sibling();
			wifi_list.remove(current);
			current = next;
		}
	}

	[GtkCallback]
	public void refresh() {
		network.scan_access_points();
	}
}

public class WifiItem : Object {
	public string ssid { get; set; }
	public string icon_name { get; set; }
	public AccessPoint access_point { get; set; }

	public WifiItem(AccessPoint ap) {
		Object();
		this.ssid = ap.ssid;
		this.icon_name = ap.icon_name;
		this.access_point = ap;
	}
}

// New class for ListBox rows
public class WifiRow : Gtk.ListBoxRow {
	public WifiItem wifi_item { get; private set; }

	private Gtk.Image icon;
	private Gtk.Label label;

	public WifiRow(WifiItem item) {
		this.wifi_item = item;

		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		box.add_css_class("padding_10");

		icon = new Gtk.Image();
		icon.set_from_icon_name(item.icon_name);
		icon.pixel_size = 25;

		label = new Gtk.Label(item.ssid);
		label.halign = Gtk.Align.START;
		label.hexpand = true;

		box.append(icon);
		box.append(label);

		this.set_child(box);

		// Update UI when access point properties change
		item.access_point.notify["strength"].connect(() => {
			icon.set_from_icon_name(item.access_point.icon_name);
			((Gtk.ListBox)get_parent()).invalidate_sort();
		});
	}
}
