using AstalMpris;
using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Mpris.ui")]
public class Mpris : Gtk.Window, ILayerWindow {

    public AstalMpris.Mpris mpris = AstalMpris.Mpris.get_default();
    public AstalMpris.Player player { get; set; }
    private Gtk.CssProvider cssProvider;
    public string namespace { get; set; }

    [GtkCallback]
    public void next() {
        this.player.next();
    }

    [GtkCallback]
    public void prev() {
        this.player.previous();
    }

    [GtkCallback]
    public void play_pause() {
        this.player.play_pause();
    }

    // [GtkCallback]
    // public void open_player() {
    // try {
    // Process.spawn_command_line_async("ncmpcpp");
    // } catch (GLib.SpawnError e) {
    // warning("Failed to open player: %s", e.message);
    // }
    // }

    [GtkCallback]
    public string pause_icon(AstalMpris.PlaybackStatus status) {
        switch (status) {
        case AstalMpris.PlaybackStatus.PLAYING:
            return "media-playback-pause-symbolic";
        case AstalMpris.PlaybackStatus.PAUSED:
        case AstalMpris.PlaybackStatus.STOPPED:
        default:
            return "media-playback-start-symbolic";
        }
    }

    [GtkChild]
    public unowned Gtk.Adjustment media_len_adjust;

    [GtkChild]
    public unowned Gtk.Scale mpris_slider;

    [GtkChild]
    public unowned Gtk.Box image_box;

    public Mpris() {
        Object();
        this.namespace = "Mpris";
        init_layer_properties();

        foreach (var item in mpris.players) {
            if (item.bus_name == "org.mpris.MediaPlayer2.mpd") {
                this.player = item;
                break;
            }
        }

        this.player.notify["art-url"].connect(() => {
            UpdateArt();
        });
        this.cssProvider = new Gtk.CssProvider();
        this.get_style_context()
         .add_provider(this.cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        UpdateArt();

        this.player.bind_property("position", media_len_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    }

    public void UpdateArt() {
        string style = "* { background-image: linear-gradient(rgba(0, 0, 0, 0), "
            + "alpha(@view_bg_color, 0.9)),"
            + "url(\"" + this.player.art_url + "\");"
            + "background-size: cover; }";

        try {
            this.cssProvider.load_from_string(style);
        } catch (Error err) {
            warning(err.message);
        }
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 50);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 5);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 5);

        GtkLayerShell.set_namespace(this, namespace);
    }

    public void present_layer() {
        this.present();
        this.set_visible(false);
    }
}