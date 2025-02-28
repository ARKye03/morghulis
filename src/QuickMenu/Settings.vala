[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Settings.ui")]
public class Settings : Adw.Bin {
	private AstalMpris.Mpris _mpris;

	public AstalNetwork.Network network { get; private set; }
	public AstalBluetooth.Bluetooth bluetooth { get; private set; }
	public AstalNotifd.Notifd notifd { get; private set; }
	public AstalPowerProfiles.PowerProfiles power_profiles { get; private set; }
	public AstalWp.Wp? wp { get; private set; }
	public static Adw.NavigationView settings_navigation { get; private set; }

	[GtkChild]
	public unowned Adw.NavigationView quick_settings_navigation_view;

	[GtkChild]
	public unowned QButton notif_button;

	construct {
		network = AstalNetwork.get_default();
		bluetooth = AstalBluetooth.get_default();
		wp = AstalWp.get_default();
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		notifd = AstalNotifd.get_default();

		_mpris = AstalMpris.get_default();
		_mpris.players.@foreach((p) => on_player_added(p));
		_mpris.player_added.connect((p) => on_player_added(p));
		_mpris.player_closed.connect((p) => on_player_removed(p));

		settings_navigation = quick_settings_navigation_view;
	}

	[GtkCallback]
	public string notif_status(bool dnd) {
		return dnd
			   ? "Don't disturb"
			   : "Enabled";
	}

	[GtkCallback]
	public string notif_icon(bool dnd) {
		return dnd
			   ? "notifications-disabled-symbolic"
			   : "preferences-system-notifications-symbolic";
	}

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

	[GtkCallback]
	public void audio_clicked() {
		wp.audio.default_speaker.mute = !wp.audio.default_speaker.mute;
	}

	[GtkCallback]
	public void audio_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("audio");
	}

	[GtkCallback]
	public string audio_status(bool muted) {
		return muted
			   ? "Muted"
			   : "Unmuted";
	}

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
		if (power_profiles == null) {
			return false;
		}
		bool present = power_profiles?.version != null;

		message("Power profiles %s present", present ? "" : "not");
		return present;
	}

	[GtkCallback]
	public void power_profiles_clicked() {
		TODO();
	}

	[GtkCallback]
	public void power_profiles_clicked_extras() {
		quick_settings_navigation_view.push_by_tag("power_profiles");
	}

	public void TODO() {
		message("TODO!");
	}

	[GtkChild]
	private unowned Adw.Carousel players;

	[GtkCallback]
	public string mpris_stack(uint n_pages) {
		return (n_pages > 0) ? "mpris" : "no_mpris";
	}

	private void on_player_added(AstalMpris.Player player) {
		var mpris_widget = new MprisPlayer(player);

		this.players.append(mpris_widget);
	}

	private void on_player_removed(AstalMpris.Player player) {
		MprisPlayer current = (MprisPlayer)this.players.get_first_child();

		while (current != null) {
			if (current.player == player) {
				this.players.remove(current);
				break;
			}
			current = (MprisPlayer)current.get_next_sibling();
		}
	}
}
