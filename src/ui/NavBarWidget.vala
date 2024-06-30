using AstalHyprland;
[GtkTemplate (ui = "/org/gtk/com.github.ARKye03.zoore_layer/ui/NavBar.ui")]
public class NavBar : Gtk.Window {

    [GtkChild]
    public unowned Gtk.Label mpris_label;

    public NavBar (Gtk.Application app) {
        Object (application: app);
        var mpris = new AstalMpris.Mpris ();
        AstalMpris.Player? mpd = null;

        foreach (var player in mpris.players) {
            if (player.bus_name == "org.mpris.MediaPlayer2.mpd")
                mpd = player;
        }
        if (mpd != null) {
            // Bind the label of mpris_label to the title property of mpd
            mpris_label.label = mpd.title;
            mpd.bind_property ("title", mpris_label, "label", GLib.BindingFlags.DEFAULT);
        } else {
            mpris_label.label = "oops";
        }
    }
}