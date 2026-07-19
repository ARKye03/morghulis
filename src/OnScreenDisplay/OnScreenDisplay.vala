[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/OnScreenDisplay/OnScreenDisplay.ui")]
public class OnScreenDisplay : MorghulWindow {
    private uint _hide_timeout_id = 0;
    private GSound.Context _scontext;
    private uint _osd_timeout = 3000;

    public static OnScreenDisplay instance { get; private set; }
    public AstalWp.Endpoint speaker { get; private set; }
    public AstalBattery.Device battery { get; private set; }
    public Backlight backlight { get; private set; }

    [GtkChild]
    public unowned Gtk.Stack stack_osd;

    construct {
        if (instance == null) {
            instance = this;
        } else {
            this.destroy();
        }

        try {
            this._scontext = new GSound.Context();
            this._scontext.init();
        } catch (Error e) {
            warning("Failed to create sound context: %s", e.message);
        }

        speaker = AstalWp.get_default().audio.default_speaker;
        backlight = Backlight.get_default();
        battery = AstalBattery.Device.get_default();
        if (battery.is_present) {
            battery.notify["state"].connect(() => {
                stack_osd.visible_child_name = "battery_osd";
                this.visible = true;
                handle_timeout();
            });
        }

        _osd_timeout = Morghulis.gsettings.get_uint("osd-timeout");

#if hyprland
        // "Long ass name" ahh function name
        if (Morghulis.is_hyprland) {
            setup_hypr_keyboard_layout_osd();
        }
#endif
    }

#if hyprland
    private void setup_hypr_keyboard_layout_osd() {
        var _hyprland = AstalHyprland.get_default();
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
            css_classes = { "background", "rounded", "padding_10" }
        };

        var keyboard_layout_variant_label = new Gtk.Label("Variant") {
            halign = Gtk.Align.CENTER,
            css_classes = { "title-2" }
        };
        var keyboard_layout_label = new Gtk.Label("Keyboard Layout") {
            halign = Gtk.Align.CENTER,
            css_classes = { "title-4", "dim-label" }
        };

        box.append(keyboard_layout_variant_label);
        box.append(keyboard_layout_label);

        _hyprland.keyboard_layout.connect((layout, variant) => {
            keyboard_layout_label.label = layout ?? "";
            // Tweak to show us-intl correctly as it is named incorrectly in Hyprland?
            keyboard_layout_variant_label.label = variant == "English (US"
                        ? "English (us-intl)"
                        : variant ?? "";

            stack_osd.visible_child_name = "keyboard_layout_osd";
            this.visible = true;
            handle_timeout();
        });

        this.stack_osd.add_named(box, "keyboard_layout_osd");
    }
#endif

    private void handle_timeout() {
        // Remove the existing timeout if it exists
        if (_hide_timeout_id != 0) {
            GLib.Source.remove(_hide_timeout_id);
            _hide_timeout_id = 0;
        }

        // Set a new timeout
        _hide_timeout_id = GLib.Timeout.add(_osd_timeout, () => {
            this.visible = false;
            _hide_timeout_id = 0;
            return false;
        });
    }

    public void change_volume() {
        play_notification_sound.begin();
        if (!this.visible) {
            this.visible = true;
        }
        this.stack_osd.visible_child_name = "volume_osd";
        handle_timeout();
    }

    public void change_brightness() {
        play_notification_sound.begin();
        if (!this.visible) {
            this.visible = true;
        }
        this.stack_osd.visible_child_name = "brightness_osd";
        handle_timeout();
    }

    private async void play_notification_sound() {
        try {
            yield this._scontext.play_full(
                null,
                GSound.Attribute.EVENT_ID,
                "audio-volume-change"
            );
        } catch (Error e) {
            warning("Failed to play sound: %s", e.message);
        }
    }

    [GtkCallback]
    public string get_battery_state(AstalBattery.State bstate) {
        string state;

        switch (bstate) {
            case AstalBattery.State.CHARGING:
                state = "Charging";
            break;

            case AstalBattery.State.DISCHARGING:
                state = "Discharging";
            break;

            case AstalBattery.State.FULLY_CHARGED:
                state = "Fully Charged";
            break;

            case AstalBattery.State.PENDING_CHARGE:
                state = "Pending Charge";
            break;

            case AstalBattery.State.PENDING_DISCHARGE:
                state = "Pending Discharge";
            break;

            default:
                state = "Unknown";
            break;
        }
        return state;
    }

    ~OnScreenDisplay() {
        if (_hide_timeout_id != 0) {
            GLib.Source.remove(_hide_timeout_id);
            _hide_timeout_id = 0;
        }
        instance = null;
    }
}
