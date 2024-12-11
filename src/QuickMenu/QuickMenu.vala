using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu.ui")]
public class QuickMenu : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }
	public AstalMpris.Mpris mpris { get; private set; }

	public QuickMenu() {
		Object(
			anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
	}

	construct {
		mpris = AstalMpris.get_default();
		mpris.players.@foreach((p) => on_player_added(p));
		mpris.player_added.connect((p) => on_player_added(p));
		mpris.player_closed.connect((p) => on_player_removed(p));
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
