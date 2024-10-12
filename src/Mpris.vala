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
    [GtkCallback]
    public string art_url(string url) {
        if (url == null) {
            return "";
        } else {
            return url.substring(7);
        }
    }
    [GtkCallback]
    public string current_pos(double pos) {
        int minutes =(int) (pos / 60);
        int seconds =(int) (pos % 60);
        if (seconds < 10) {
            return @"$minutes:0$seconds";
        } else {
            return @"$minutes:$seconds";
        }
    }
    [GtkCallback]
    public string total_pos(double len) {
        int minutes =(int) (len / 60);
        int seconds =(int) (len % 60);
        if (seconds < 10) {
            return @"$minutes:0$seconds";
        } else {
            return @"$minutes:$seconds";
        }
    }

    [GtkChild]
    public unowned Gtk.Image art_image;
    [GtkChild]
    public unowned Gtk.Adjustment media_len_adjust;

    [GtkChild]
    public unowned Gtk.Scale mpris_slider;

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

        this.player.bind_property("position", media_len_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 50);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 5);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 5);

        GtkLayerShell.set_namespace(this, namespace);
    }

    public void present_layer() {
        this.present();
        this.set_visible(false);
    }
}