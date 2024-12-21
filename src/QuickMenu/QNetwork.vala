[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	public AstalNetwork.Network network { get; set; }
	private GLib.ListStore wifi_store;

	[GtkChild]
	private unowned Gtk.ListView wifi_list;

	construct {
		network = AstalNetwork.get_default();
		wifi_store = new GLib.ListStore(typeof(WifiItem));

		var factory = setup_factory();
		var selection = new Gtk.NoSelection(wifi_store);
		wifi_list.set_factory(factory);
		wifi_list.set_model(selection);

		network.wifi.notify["access-points"].connect(refresh_items);
		refresh_items();
	}

	private Gtk.SignalListItemFactory setup_factory() {
		var factory = new Gtk.SignalListItemFactory();

		factory.setup.connect((factory, obj) => {
			var list_item = (Gtk.ListItem)obj;
			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
			box.append(new Gtk.Image());
			box.append(new Gtk.Label(null));
			list_item.set_child(box);
		});

		factory.bind.connect((factory, obj) => {
			var list_item = (Gtk.ListItem)obj;
			var box = (Gtk.Box)list_item.get_child();
			var image = (Gtk.Image)box.get_first_child();
			var label = (Gtk.Label)box.get_last_child();
			var item = (WifiItem)list_item.get_item();

			image.set_from_icon_name(item.icon_name);
			image.pixel_size = 25;
			label.label = item.ssid;
		});

		return factory;
	}

	private void refresh_items() {
		wifi_store.remove_all();
		network.wifi.access_points.foreach((ap) => {
			wifi_store.append(new WifiItem(ap));
		});
	}

	[GtkCallback]
	public void refresh() {
		network.wifi.scan();
	}
}

public class WifiItem : Object {
	public string ssid { get; set; }
	public string icon_name { get; set; }
	public AstalNetwork.AccessPoint access_point { get; set; }

	public WifiItem(AstalNetwork.AccessPoint ap) {
		Object();
		this.ssid = ap.ssid;
		this.icon_name = ap.icon_name;
		this.access_point = ap;
	}
}
