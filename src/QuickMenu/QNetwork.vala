[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QNetwork.ui")]
public class QNetwork : Gtk.Box {
	public AstalNetwork.Network network { get; set; }

	[GtkChild]
	public unowned Gtk.ListBox items_list;

	construct {
		network = AstalNetwork.get_default();

		var APs = network.wifi.access_points;
		foreach (var ap in APs) {
			var item = new Gtk.ListBoxRow();
			item.set_child(new Gtk.Label(ap.ssid));
			items_list.append(item);
		}
	}
}
