using AstalHyprland;
using GtkLayerShell;
using AstalWp;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/StatusBar.ui")]
public class StatusBar : Gtk.Window, LayerWindow {
    public AstalMpris.Mpris mpris = AstalMpris.Mpris.get_default();
    public AstalHyprland.Hyprland hyprland = AstalHyprland.Hyprland.get_default();
    public List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();
    private AstalWp.Endpoint speaker = AstalWp.get_default().audio.default_speaker;
    public string namespace { get; set; }

    [GtkChild]
    public unowned Gtk.Label mpris_label;

    [GtkChild]
    public unowned Gtk.Box workspaces;

    [GtkChild]
    public unowned Gtk.Button mpris_button;

    [GtkChild]
    public unowned Gtk.Button apps_button;

    [GtkChild]
    public unowned Gtk.Label client_label;

    [GtkChild]
    public unowned Gtk.Label clock;

    [GtkChild]
    public unowned Gtk.Label volume;

    public StatusBar(Gtk.Application app) {
        Object(application: app);
        init_layer_properties();
        this.name = "StatusBar";
        this.namespace = "StatusBar";

        apps_button.clicked.connect(() => {
            Morghulis.Instance.ToggleWindow("VRunner");
        });
        Volume();
        FocusedClient();
        Workspaces();
        Mpris();
        Clock();
    }

    public void Volume() {
        speaker.bind_property("volume", volume, "label", GLib.BindingFlags.SYNC_CREATE, (_, src, ref trgt) => {
            var p = Math.round(src.get_double() * 100);
            trgt.set_string(@"$p%");
            return true;
        });
    }

    public void FocusedClient() {
        hyprland.notify["focused-client"].connect(() => {
            client_label.label = hyprland.focused_client.title;
        });
        if (hyprland.focused_client != null) {
            client_label.label = hyprland.focused_client.title;
        }
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, 5);
        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 5);
        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 5);

        GtkLayerShell.auto_exclusive_zone_enable(this);
    }

    public void present_layer() {
        this.present();
    }

    void UpdateClock() {
        var clockT = new DateTime.now_local();
        clock.label = clockT.format("%I:%M %p %b %e");
    }

    void Clock() {
        UpdateClock();
        GLib.Timeout.add(30000, () => {
            UpdateClock();
            return true;
        });
    }

    void Workspaces() {
        var wicons = new string[] {
            " ", " ", "󰨞 ",
            " ", " ", "󰭹 ",
            " ", " ", "󰊖 ",
            " ",
        };

        for (var i = 1; i <= 10; i++) {
            var workspace_button = new Gtk.Button.with_label(wicons[i - 1]);
            connect_button_to_workspace(workspace_button, i);
            workspace_button.valign = Gtk.Align.CENTER;
            workspace_button.halign = Gtk.Align.CENTER;
            workspaces.append(workspace_button);
            workspace_buttons.append(workspace_button);
        }
        UpdateWorkspaces();
        hyprland.notify["focused-workspace"].connect(UpdateWorkspaces);
        hyprland.client_added.connect(UpdateWorkspaces);
        hyprland.client_removed.connect(UpdateWorkspaces);
        hyprland.client_moved.connect(UpdateWorkspaces);
    }

    void UpdateWorkspaces() {
        var focused_workspace_id = hyprland.focused_workspace.id;

        int index = 0;
        workspace_buttons.foreach((button) => {
            if (button != null) {
                if (index + 1 == focused_workspace_id) {
                    button.set_css_classes(new string[] { "focused" });
                } else if (workspace_has_windows(index + 1)) {
                    button.set_css_classes(new string[] { "has-windows" });
                } else {
                    button.set_css_classes(new string[] { "empty" });
                }
            }
            index++;
        });
    }

    void connect_button_to_workspace(Gtk.Button button, int workspaceNumber) {
        button.clicked.connect(() => {
            hyprland.dispatch("workspace", workspaceNumber.to_string());
        });
    }

    bool workspace_has_windows(int workspaceNumber) {
        var WindowCount = hyprland.get_workspace(workspaceNumber).clients.length();
        return WindowCount > 0;
    }

    void Mpris() {
        AstalMpris.Player? mpd = null;

        mpris_button.clicked.connect(() => {
            // mpd.play_pause();
            Morghulis.Instance.ToggleWindow("Mpris");
        });
        mpris_button.tooltip_text = "Play/Pause";

        foreach (var player in mpris.players) {
            if (player.bus_name == "org.mpris.MediaPlayer2.mpd")
                mpd = player;
        }
        if (mpd != null) {
            mpris_label.label = mpd.title;
            mpd.bind_property("title", mpris_label, "label", GLib.BindingFlags.DEFAULT);
        } else {
            mpris_label.label = "oops";
        }
    }
}