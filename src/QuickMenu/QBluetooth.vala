[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QBluetooth.ui")]
public class QBluetooth : Gtk.Box {
	public AstalBluetooth.Bluetooth bluetooth { get; set; }
	private GLib.ListStore device_store;

	[GtkChild]
	public unowned Gtk.ListView blue_list;

	construct {
		bluetooth = AstalBluetooth.get_default();
		device_store = new GLib.ListStore(typeof(AstalBluetooth.Device));

		var factory = setup_factory();
		var selection = new Gtk.NoSelection(device_store);
		blue_list.set_factory(factory);
		blue_list.set_model(selection);

		bluetooth.devices.@foreach(dev => on_added(dev));
		bluetooth.device_added.connect((_, device) => on_added(device));
		bluetooth.device_removed.connect((_, device) => on_removed(device));
	}

	private Gtk.SignalListItemFactory setup_factory() {
		var factory = new Gtk.SignalListItemFactory();

		factory.setup.connect((factory, obj) => {
			var list_item = (Gtk.ListItem)obj;
			var button = new QBluetoothItem(null);
			list_item.activatable = false;
			list_item.selectable = false;
			list_item.set_child(button);
		});

		factory.bind.connect((factory, obj) => {
			var list_item = (Gtk.ListItem)obj;
			var button = (QBluetoothItem)list_item.get_child();
			var device = (AstalBluetooth.Device)list_item.get_item();
			button.device = device;
		});

		return factory;
	}

	private void on_added(AstalBluetooth.Device device) {
		for (uint i = 0; i < device_store.get_n_items(); i++) {
			var stored_device = (AstalBluetooth.Device)device_store.get_item(i);
			if (stored_device.address == device.address) {
				return;
			}
		}
		device_store.append(device);
	}

	private void on_removed(AstalBluetooth.Device device) {
		for (uint i = 0; i < device_store.get_n_items(); i++) {
			var stored_device = (AstalBluetooth.Device)device_store.get_item(i);
			if (stored_device.address == device.address) {
				device_store.remove(i);
				break;
			}
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
