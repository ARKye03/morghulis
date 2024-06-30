using AstalHyprland;
[GtkTemplate(ui = "/org/gtk/com.github.ARKye03.zoore_layer/ui/NavBar.ui")]
public class NavBar : Gtk.Window {
    AstalMpris.Mpris mpris;
    AstalHyprland.Hyprland hyprland;

    [GtkChild]
    public unowned Gtk.Label mpris_label;

    [GtkChild]
    public unowned Gtk.Box workspaces;

    public NavBar(Gtk.Application app) {
        Object(application: app);

        WorkspaceRenderer();
        MprisRenderer();
    }

    void WorkspaceRenderer() {
        hyprland = new AstalHyprland.Hyprland();
        var wicons = new string[] {
            "  ",
            "  ",
            " 󰨞 ",
            "  ",
            "  ",
            " 󰭹 ",
            "  ",
            "  ",
            " 󰊖 ",
            "  ",
        };

        for (var i = 1; i <= 10; i++) { // Assuming you want to create 10 buttons for workspaces 1 to 10
            var workspace_button = new Gtk.Button.with_label(wicons[i - 1]); // Adjust index if necessary
            connect_button_to_workspace(workspace_button, i);
            workspace_button.valign = Gtk.Align.CENTER;
            workspace_button.halign = Gtk.Align.CENTER;
            workspaces.append(workspace_button);
        }

        // var active_worskpace = hyprland.focused_workspace;
    }

    // Function to create a lambda function with the current value of i
    void connect_button_to_workspace(Gtk.Button button, int workspaceNumber) {
        button.clicked.connect(() => {
            // Execute process command `hyprctl dispatch workspace ${workspaceNumber}`
            hyprland.dispatch("workspace", workspaceNumber.to_string());
        });
    }

    void MprisRenderer() {
        mpris = new AstalMpris.Mpris();
        AstalMpris.Player? mpd = null;

        foreach (var player in mpris.players) {
            if (player.bus_name == "org.mpris.MediaPlayer2.mpd")
                mpd = player;
        }
        if (mpd != null) {
            // Bind the label of mpris_label to the title property of mpd
            mpris_label.label = mpd.title;
            mpd.bind_property("title", mpris_label, "label", GLib.BindingFlags.DEFAULT);
        } else {
            mpris_label.label = "oops";
        }
    }
}