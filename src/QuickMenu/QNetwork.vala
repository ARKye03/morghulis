[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	private GLib.List<Gtk.ListBoxRow> network_items = new GLib.List<Gtk.ListBoxRow>();

	public AstalNetwork.Network network { get; set; }

	[GtkChild]
	public unowned Gtk.ListBox items_list;

	construct {
		network = AstalNetwork.get_default();
		create_items();

		network.wifi.notify["access-points"].connect(refresh_items);
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
	}

	private void create_items() {
		network.wifi.access_points.foreach((ap) => {
			var lbr_btn = new Gtk.ListBoxRow();
			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
			lbr_btn.set_child(box);
			Gtk.Image img = new Gtk.Image();
			img.icon_name = ap.icon_name;
			img.pixel_size = 25;
			ap.bind_property("icon_name", img, "icon-name");
			box.append(img);
			box.append(new Gtk.Label(ap.ssid));
			box.add_css_class("qnetwork_item");

			network_items.prepend(lbr_btn);
			items_list.prepend(lbr_btn);
		});
	}

	private void refresh_items() {
		network_items.foreach((lbr) => {
			items_list.remove(lbr);
		});
		create_items();
	}
}
