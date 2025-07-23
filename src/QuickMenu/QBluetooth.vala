[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QBluetooth.ui")]
public class QBluetooth : Gtk.Box {
	public AstalBluetooth.Bluetooth bluetooth { get; set; }

	[GtkChild]
	public unowned Gtk.ListBox blue_list;

	construct {
		bluetooth = AstalBluetooth.get_default();

		bluetooth.devices.@foreach(dev => on_added(dev));
		bluetooth.device_added.connect((_, dev) => on_added(dev));
		bluetooth.device_removed.connect((_, dev) => on_removed(dev));
		this.blue_list.set_sort_func(sfunc);
		this.blue_list.invalidate_sort();
	}

	public int sfunc(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
		QBluetoothItem a = (QBluetoothItem)la;

		return a.device.connected ? -1 : 1;
	}

	private void on_added(AstalBluetooth.Device device) {
		blue_list.append(new QBluetoothItem(device));
		this.blue_list.invalidate_sort();
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
		this.blue_list.invalidate_sort();
	}

	[GtkCallback]
	public void toggle_discover() {
		if (bluetooth.adapter.discovering) {
			try {
				bluetooth.adapter.stop_discovery();
			} catch (Error e) {
				critical("Error: %s", e.message);
			}
		} else {
			try {
				bluetooth.adapter.start_discovery();
			} catch (Error e) {
				critical("Error: %s", e.message);
			}
		}
	}
}
