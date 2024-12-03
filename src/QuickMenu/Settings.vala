[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Settings.ui")]
public class Settings : Gtk.Grid {
	public AstalNetwork.Network network { get; set; }
	public AstalBluetooth.Bluetooth bluetooth { get; set; }
	public AstalMpris.Mpris mpris { get; private set; }

	construct {
		network = AstalNetwork.get_default();
		mpris = AstalMpris.get_default();
		bluetooth = AstalBluetooth.get_default();
		mpris.players.@foreach((p) => on_player_added(p));
		mpris.player_added.connect((p) => on_player_added(p));
		mpris.player_closed.connect((p) => on_player_removed(p));
	}

	[GtkCallback]
	public void network_clicked() {
		this.network.wifi.enabled = !this.network.wifi.enabled;
	}

	[GtkCallback]
	public string network_connected(bool connected) {
		return connected
			   ? "Connected"
			   : "Off";
	}

	[GtkCallback]
	public string network_ssid(string identity) {
		if (identity != "") {
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
	public string bluetooth_identity(string identity) {
		if (identity != "") {
			return identity;
		}
		else {
			return "Bluetooth";
		}
	}

	[GtkChild]
	private unowned Adw.Carousel players;

	private void on_player_added(AstalMpris.Player player) {
		var mpris_widget = new Mpris(player);

		this.players.append(mpris_widget);

		player.notify["playback-status"].connect(() => {
			reorder_players();
		});

		reorder_players();
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

	private void reorder_players() {
		Mpris ?playing_widget = null;
		int playing_index = -1;

		for (int i = 0; i < this.players.n_pages; i++) {
			Mpris mpris_widget = (Mpris)this.players.get_nth_page(i);
			if (mpris_widget.player.playback_status == AstalMpris.PlaybackStatus.PLAYING) {
				playing_widget = mpris_widget;
				playing_index = i;
				break;
			}
		}

		if (playing_widget != null && playing_index > 0) {
			this.players.remove(playing_widget);
			this.players.insert(playing_widget, 0);
			this.players.scroll_to(playing_widget, true);
		}
	}

	[GtkCallback]
	public void TODO() {
		stdout.printf("TODO!\n");
	}
}
