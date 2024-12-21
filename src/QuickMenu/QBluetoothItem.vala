[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QBluetoothItem.ui")]
public class QBluetoothItem : Gtk.Button {
	public AstalBluetooth.Device device { get; construct set; }

	public QBluetoothItem(AstalBluetooth.Device? device) {
		Object(
			device: device
			);
	}

	[GtkCallback]
	public void switch_connection() {
		if (this.device.connected) {
			this.device.disconnect_device.begin();
		} else {
			this.device.connect_device.begin();
		}
	}

	[GtkCallback]
	public string device_icon(string? icon) {
		if (icon == null) {
			return "bluetooth-active";
		}
		return icon;
	}
}
