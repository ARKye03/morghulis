[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/OnScreenDisplay.ui")]
public class OnScreenDisplay : MorghulWindow {
    private uint _hide_timeout_id = 0;

    public static OnScreenDisplay instance { get; private set; }
    public AstalWp.Endpoint speaker { get; private set; }
    public Backlight backlight { get; private set; }

    [GtkChild]
    public unowned Gtk.Stack stack_osd;

    construct {
        if (instance == null) {
            instance = this;
        } else {
            this.destroy();
        }
        speaker = AstalWp.get_default().audio.default_speaker;
        backlight = Backlight.get_default();
    }

    private void handle_timeout() {
        // Remove the existing timeout if it exists
        if (_hide_timeout_id != 0) {
            GLib.Source.remove(_hide_timeout_id);
            _hide_timeout_id = 0;
        }

        // Set a new timeout
        _hide_timeout_id = GLib.Timeout.add(3000, () => {
            this.visible = false;
            _hide_timeout_id = 0;
            return false;
        });
    }

    public void change_volume() {
        this.visible = true;
        this.stack_osd.visible_child_name = "volume_osd";
        handle_timeout();
    }

    public void change_brightness() {
        this.visible = true;
        this.stack_osd.visible_child_name = "brightness_osd";
        handle_timeout();
    }
}
