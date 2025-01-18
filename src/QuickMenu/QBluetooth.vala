[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QBluetooth.ui")]
public class QBluetooth : Gtk.Box {
	public AstalBluetooth.Bluetooth bluetooth { get; set; }

	[GtkChild]
	public unowned Gtk.ListBox blue_list;

	construct {
		bluetooth = AstalBluetooth.get_default();

		bluetooth.devices.@foreach(dev => on_added(dev));
		bluetooth.device_added.connect((_, device) => on_added(device));
		bluetooth.device_removed.connect((_, device) => on_removed(device));
	}

	private void on_added(AstalBluetooth.Device device) {
		blue_list.append(new QBluetoothItem(device));
	}

	private void on_removed(AstalBluetooth.Device device) {
		var current = (QBluetoothItem)blue_list.get_first_child();

		while (current != null) {
			if (current.device == device) {
				blue_list.remove(current);
				break;
			}

			current = (QBluetoothItem)current.get_next_sibling();
		}
	}

	[GtkCallback]
	public void refresh() {
		try {
			bluetooth.adapter.start_discovery();
		} catch (Error e) {
			critical("Error: %s", e.message);
		}
	}
}
