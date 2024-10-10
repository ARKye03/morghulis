using AstalHyprland;
using GtkLayerShell;
using AstalWp;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/StatusBar.ui")]
public class StatusBar : Gtk.Window, ILayerWindow {
    private AstalMpris.Mpris mpris { get; set; }
    private AstalHyprland.Hyprland hyprland { get; set; }
    private List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();

    public AstalMpris.Player mpd { get; set; }
    public AstalWp.Endpoint speaker { get; set; }

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

    [GtkChild]
    public unowned Gtk.Button volume_button;


    public StatusBar(Gtk.Application app) {
        Object(application: app);
        speaker = AstalWp.get_default().audio.default_speaker;
        mpris = AstalMpris.Mpris.get_default();
        hyprland = AstalHyprland.Hyprland.get_default();

        init_layer_properties();
        this.name = "StatusBar";
        this.namespace = "StatusBar";

        apps_button.clicked.connect(() => {
            Morghulis.Instance.ToggleWindow("VRunner");
        });
        Volume();
        hyprland.notify["focused-client"].connect(() => {
            FocusedClient();
        });
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
        var scroll = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.BOTH_AXES);
        scroll.scroll.connect((delta_x, delta_y) => {
            if (delta_y < 0) {
                speaker.volume += 0.05;
            } else {
                speaker.volume -= 0.05;
            }
            return true;
        });
        volume_button.add_controller(scroll);
        volume_button.clicked.connect(() => {
            speaker.mute = !speaker.mute;
        });
    }

    public void FocusedClient() {
        if (hyprland.focused_client != null) {
            client_label.label = hyprland.focused_client.title;
        }
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
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
        foreach (var player in mpris.players) {
            if (player.bus_name == "org.mpris.MediaPlayer2.mpd")
                mpd = player;
        }

        mpris_button.clicked.connect(() => {
            Morghulis.Instance.ToggleWindow("Mpris");
        });

        var right_click = new Gtk.GestureClick();
        right_click.set_button(Gdk.BUTTON_SECONDARY);
        right_click.pressed.connect(() => {
            if (mpd != null) {
                mpd.play_pause();
            }
        });
        mpris_button.add_controller(right_click);

        mpris_button.tooltip_text = mpd.identity;
    }
}