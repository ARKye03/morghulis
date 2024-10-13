using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/QuickSettings.ui")]
public class QuickSettings : Gtk.Window, ILayerWindow {
public AstalWp.Endpoint speaker { get; set; }
public AstalNetwork.Network network { get; set; }
public AstalBluetooth.Bluetooth bluetooth { get; set; }
public AstalNotifd.Notifd notifd {get; private set;}
public AstalMpris.Mpris mpris {get; private set;}
public string namespace { get; set; }


public QuickSettings () {
	Object (
		name: "QuickSettings",
		namespace : "QuickSettings"
		);
	init_layer_properties ();

	speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

}
construct {
	speaker = AstalWp.get_default ().audio.default_speaker;
	network = AstalNetwork.get_default ();
	mpris = AstalMpris.get_default ();
	bluetooth = AstalBluetooth.get_default ();
	this.mpris.players.@foreach ((p) => this.on_player_added (p));
	this.mpris.player_added.connect ((p) => this.on_player_added (p));
	this.mpris.player_closed.connect ((p) => this.on_player_removed (p));

	uptime ();
}

private static string stdout;
private void uptime () {
	update_uptime ();
	GLib.Timeout.add (60000, () => {
			update_uptime ();
			return true;
		});
}
private void update_uptime () {
	try {
		Process.spawn_command_line_sync ("uptime -p", out stdout);
	} catch (Error e) {
		warning ("Failed to get uptime: %s", e.message);
	}
	uptime_label.label = stdout.strip ();
}

[GtkChild]
public unowned Gtk.Adjustment vol_adjust;

[GtkCallback]
public string current_volume (double volume) {
	return @"$(Math.round(volume * 100))%";
}

[GtkCallback]
public void network_clicked () {
	this.network.wifi.enabled = !this.network.wifi.enabled;
}
[GtkCallback]
public void bluetooth_clicked () {
	this.bluetooth.adapter.powered = !this.bluetooth.adapter.powered;
}
[GtkCallback]
public void bluetooth_clicked_extras () {
	//TODO
}
[GtkCallback]
public string bluetooth_icon_name (bool connected) {
	return connected
	    ? "bluetooth-active-symbolic"
	    : "bluetooth-disabled-symbolic";
}
[GtkCallback]
public string active_vpn (AstalNetwork.Network network) {
	return network.wifi.active_connection.vpn ? "network-vpn-symbolic" : "network-vpn-disabled-symbolic";
}
[GtkCallback]
public void toggle_vpn () {
	try {
		if (network.wifi.active_connection.vpn)
			Process.spawn_command_line_async ("protonvpn-cli d");
		else
			Process.spawn_command_line_async ("protonvpn-cli c --cc US -p udp");
	} catch (GLib.Error e) {
		print ("Error executing command: %s\n", e.message);
	}
}

[GtkCallback]
public string dont_disturb_icon (bool dnd) {
	return dnd
	? "notifications-disabled-symbolic"
	: "user-available-symbolic";
}
[GtkCallback]
public void toggle_disturb () {
	this.notifd.dont_disturb = !this.notifd.dont_disturb;
}

[GtkCallback]
public void on_notif_arrow_clicked () {
	//  nav_view.push_by_tag("notifications");
}
[GtkChild]
private unowned Adw.Carousel players;

private void on_player_added (AstalMpris.Player player) {
	var mpris_widget = new Mpris (player);
	this.players.append (mpris_widget);

	player.notify["playback-status"].connect( () => {
			reorder_players ();
		});

	reorder_players ();
}

private void on_player_removed (AstalMpris.Player player) {
	for (int i = 0; i < this.players.n_pages; i++) {
		Mpris p = (Mpris) this.players.get_nth_page (i);
		if (p.player == player) {
			this.players.remove (p);
			break;
		}
	}
}

private void reorder_players () {
	Mpris? playing_widget = null;
	int playing_index = -1;

	for (int i = 0; i < this.players.n_pages; i++) {
		Mpris mpris_widget = (Mpris) this.players.get_nth_page (i);
		if (mpris_widget.player.playback_status == AstalMpris.PlaybackStatus.PLAYING) {
			playing_widget = mpris_widget;
			playing_index = i;
			break;
		}
	}

	if (playing_widget != null && playing_index > 0) {
		this.players.remove (playing_widget);
		this.players.insert (playing_widget, 0);
		this.players.scroll_to (playing_widget, true);
	}
}
[GtkChild]
public unowned Gtk.Label uptime_label;

[GtkCallback]
public void shutdown () {
	try {
		Process.spawn_command_line_async ("systemctl poweroff");
	} catch (Error e) {
		warning ("Failed to shutdown: %s", e.message);
	}
}
[GtkCallback]
public void reboot () {
	try {
		Process.spawn_command_line_async ("systemctl reboot");
	} catch (Error e) {
		warning ("Failed to reboot: %s", e.message);
	}
}
[GtkCallback]
public void suspend () {
	try {
		Process.spawn_command_line_async ("systemctl suspend");
	} catch (Error e) {
		warning ("Failed to suspend: %s", e.message);
	}
}
[GtkCallback]
public void hibernate () {
	try {
		Process.spawn_command_line_async ("systemctl hibernate");
	} catch (Error e) {
		warning ("Failed to hibernate: %s", e.message);
	}
}
[GtkCallback]
public void lock () {
	try {
		Process.spawn_command_line_async ("loginctl lock-session");
	} catch (Error e) {
		warning ("Failed to lock: %s", e.message);
	}
}


public void init_layer_properties () {
	GtkLayerShell.init_for_window (this);
	GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

	GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 5);
	GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 5);
	//    GtkLayerShell.set_namespace (this, namespace); <- For some reason this breaks uncrustify HARD newlines_cleanup_braces(4995): Missing BRACE_OPEN after namespaceorig line is 206, orig col is 44
}
public void present_layer () {
	this.present ();
	this.visible = false;
}
}
