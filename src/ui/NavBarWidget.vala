using AstalHyprland;
using PulseAudio;

[GtkTemplate (ui = "/org/gtk/com.github.ARKye03.zoore_layer/ui/NavBar.ui")]
public class NavBar : Gtk.Window {
    public AstalMpris.Mpris mpris = AstalMpris.Mpris.get_default ();
    public AstalHyprland.Hyprland hyprland = AstalHyprland.Hyprland.get_default ();
    public List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();


    [GtkChild]
    public unowned Gtk.Label mpris_label;

    [GtkChild]
    public unowned Gtk.Box workspaces;

    [GtkChild]
    public unowned Gtk.Button mpris_button;

    [GtkChild]
    public unowned Gtk.Label clock;

    [GtkChild]
    public unowned Gtk.Label volume;

    public NavBar (Gtk.Application app) {
        Object (application: app);

        WorkspaceRenderer ();
        MprisRenderer ();
        ClockRenderer ();
        VolumeRenderer ();
    }

    void VolumeRenderer () {
        // TODO
    }

    void UpdateClock () {
        var clockT = new DateTime.now_local ();
        clock.label = clockT.format ("%I:%M %p %b %e");
    }

    void ClockRenderer () {
        UpdateClock ();
        GLib.Timeout.add (30000, () => {
            UpdateClock ();
            return true;
        });
    }

    void WorkspaceRenderer () {
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
        // print ("Focused workspace ID: %d", focused_workspace_id);
        for (var i = 1; i <= 10; i++) {
            var workspace_button = new Gtk.Button.with_label (wicons[i - 1]);

            connect_button_to_workspace (workspace_button, i);
            workspace_button.valign = Gtk.Align.CENTER;
            workspace_button.halign = Gtk.Align.CENTER;
            workspaces.append (workspace_button);
            workspace_buttons.append (workspace_button);
        }
        UpdateWorkspaces ();
        hyprland.notify["focused-workspace"].connect (UpdateWorkspaces);
    }

    void UpdateWorkspaces () {
        var focused_workspace_id = hyprland.focused_workspace.id;

        int index = 0;
        workspace_buttons.foreach ((button) => {
            if (button != null) {
                if (index + 1 == focused_workspace_id) {
                    button.set_css_classes (new string[] { "focused" });
                } else if (workspace_has_windows (index + 1)) {
                    button.set_css_classes (new string[] { "has-windows" });
                } else {
                    button.set_css_classes (new string[] { "empty" });
                }
            }
            index++;
        });
    }

    // Function to create a lambda function with the current value of i
    void connect_button_to_workspace (Gtk.Button button, int workspaceNumber) {
        button.clicked.connect (() => {
            // Execute process command `hyprctl dispatch workspace ${workspaceNumber}`
            hyprland.dispatch ("workspace", workspaceNumber.to_string ());
        });
    }

    bool workspace_has_windows (int workspaceNumber) {
        var WindowCount = hyprland.get_workspace (workspaceNumber).clients.length ();
        return WindowCount > 0;
    }

    void MprisRenderer () {
        AstalMpris.Player? mpd = null;

        mpris_button.clicked.connect (() => {
            mpd.play_pause ();
        });

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