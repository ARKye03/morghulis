using AstalHyprland;
[GtkTemplate (ui = "/org/gtk/com.github.ARKye03.zoore_layer/ui/NavBar.ui")]
public class NavBar : Gtk.Window {

    public string currentSong;

    public NavBar (Gtk.Application app) {
        Object (application: app);
        var hyprland = new AstalHyprland.Hyprland ();
        var a = hyprland.focused_workspace.name;
        currentSong = a;
    }
}