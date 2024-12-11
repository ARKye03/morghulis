[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Settings.ui")]
public class Settings : Gtk.Grid {
	public AstalNetwork.Network network { get; set; }
	public AstalBluetooth.Bluetooth bluetooth { get; set; }

	construct {
		network = AstalNetwork.get_default();
		bluetooth = AstalBluetooth.get_default();
	}

	[GtkCallback]
	public void network_clicked() {
		this.network.wifi.enabled = !this.network.wifi.enabled;
	}

	[GtkCallback]
	public string conn_status(bool connected) {
		return connected
			   ? "Connected"
			   : "Off";
	}

	[GtkCallback]
	public string network_identity(string ?identity) {
		if (identity != null && identity != "") {
			return identity;
		}
		else {
			return "Wifi";
		}
	}

	[GtkCallback]
	public void bluetooth_clicked() {
		this.bluetooth.adapter.powered = !this.bluetooth.adapter.powered;
	}

	[GtkCallback]
	public void bluetooth_clicked_extras() {
		//TODO
	}

	[GtkCallback]
	public string bluetooth_icon_name(bool connected) {
		return connected
			   ? "bluetooth-active-symbolic"
			   : "bluetooth-disabled-symbolic";
	}

	[GtkCallback]
	public string bluetooth_identity(string ?identity) {
		if (identity != null && identity != "") {
			return identity;
		}
		else {
			return "Bluetooth";
		}
	}

	[GtkCallback]
	public void TODO() {
		stdout.printf("TODO!\n");
	}
}
