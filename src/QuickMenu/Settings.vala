[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Settings.ui")]
public class Settings : Adw.Bin {
	public AstalNetwork.Network network { get; private set; }
	public AstalBluetooth.Bluetooth bluetooth { get; private set; }
	public AstalPowerProfiles.PowerProfiles power_profiles { get; private set; }
	public AstalMpris.Mpris mpris { get; private set; }
	public AstalNotifd.Notifd notifd { get; private set; }

	construct {
		network = AstalNetwork.get_default();
		bluetooth = AstalBluetooth.get_default();
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		notifd = AstalNotifd.get_default();
		notifd.notify["dont-disturb"].connect(dnd);
		dnd();

		mpris = AstalMpris.get_default();
		mpris.players.@foreach((p) => on_player_added(p));
		mpris.player_added.connect((p) => on_player_added(p));
		mpris.player_closed.connect((p) => on_player_removed(p));
	}

	private void dnd() {
		if (notifd.dont_disturb) {
			notif_button.active = false;
			notif_button.status = "Don't disturb";
			notif_button.icon = "notifications-disabled-symbolic";
		} else {
			notif_button.active = true;
			notif_button.status = "Enabled";
			notif_button.icon = "preferences-system-notifications-symbolic";
		}
	}

	[GtkChild]
	public unowned Adw.NavigationView quick_settings_navigation_view;

	[GtkCallback]
	public void network_clicked() {
		this.network.wifi.enabled = !this.network.wifi.enabled;
	}

	[GtkCallback]
	public void network_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("network");
	}

	[GtkCallback]
	public string conn_status(bool connected) {
		return connected
			   ? "Connected"
			   : "Off";
	}

	[GtkCallback]
	public string network_identity(string? identity) {
		if (identity != null && identity != "") {
			return identity;
		} else {
			return "Wifi";
		}
	}

	[GtkCallback]
	public void bluetooth_clicked() {
		this.bluetooth.adapter.powered = !this.bluetooth.adapter.powered;
	}

	[GtkCallback]
	public void bluetooth_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("bluetooth");
	}

	[GtkCallback]
	public string bluetooth_icon_name(bool connected) {
		return connected
			   ? "bluetooth-active-symbolic"
			   : "bluetooth-disabled-symbolic";
	}

	[GtkCallback]
	public string bluetooth_identity(string? identity) {
		if (identity != null && identity != "") {
			return identity;
		} else {
			return "Bluetooth";
		}
	}

	[GtkChild]
	public unowned QButton notif_button;

	[GtkCallback]
	public void notifications_clicked() {
		notifd.dont_disturb = !notifd.dont_disturb;
	}

	[GtkCallback]
	public void notifications_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("notifications");
	}

	[GtkCallback]
	public bool ppd_present(AstalPowerProfiles.PowerProfiles? power_profiles) {
		return power_profiles == null;
	}

	[GtkCallback]
	public void power_profiles_clicked() {
		TODO();
	}

	[GtkCallback]
	public void power_profiles_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("power_profiles");
	}

	[GtkCallback]
	public void TODO() {
		stdout.printf("TODO!\n");
	}

	[GtkChild]
	private unowned Adw.Carousel players;

	private void on_player_added(AstalMpris.Player player) {
		var mpris_widget = new Mpris(player);

		this.players.append(mpris_widget);
	}

	private void on_player_removed(AstalMpris.Player player) {
		for (int i = 0; i < this.players.n_pages; i++) {
			Mpris p = (Mpris)this.players.get_nth_page(i);
			if (p.player == player) {
				this.players.remove(p);
				break;
			}
		}
	}
}
