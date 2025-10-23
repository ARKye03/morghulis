[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/ScreenRecord.ui")]
public class ScreenRecord : MorghulWindow {
    private AstalNotifd.Notifd _notifd;
    private uint _timer_id = 0;
    private uint _focus_timeout_id = 0;
    private const string APP_ICON_NAME = "dialog-information-symbolic";
    private int _focused_button_index = 0;
    private Gtk.Button[] _buttons;

    public ScreenRecorder screen_rec { get; private set; }

    [GtkChild]
    private unowned Gtk.Label status_label;

    [GtkChild]
    private unowned Gtk.Image status_icon;

    [GtkChild]
    private unowned Gtk.Button screenshot_interactive_btn;

    [GtkChild]
    private unowned Gtk.Button screenshot_full_btn;

    [GtkChild]
    private unowned Gtk.Button toggle_record_btn;

    [GtkChild]
    private unowned Gtk.Box main_box;

    construct {
        this.screen_rec = ScreenRecorder.get_default();
        this._notifd = AstalNotifd.Notifd.get_default();
        var monitor_geometry = Morghulis.primary_monitor.get_geometry();

        this.default_width = monitor_geometry.width;
        this.default_height = monitor_geometry.height;

        _buttons = { screenshot_interactive_btn, screenshot_full_btn, toggle_record_btn };

        screen_rec.notify["is-recording"].connect(() => {
            if (screen_rec.is_recording) {
                start_timer();
                status_icon.add_css_class("is_recording");
            } else {
                status_icon.remove_css_class("is_recording");
                stop_timer();
            }
        });

        this.notify["visible"].connect(() => {
            if (this.visible) {
                focus_button(0);
            }
        });
    }

    [GtkCallback]
    private async void on_screenshot_interactive() {
        this.visible = false;
        screen_rec.take_screenshot.begin(true, null, (obj, res) => {
            string? path = screen_rec.take_screenshot.end(res);
            if (path != null) {
                debug("Screenshot saved to: %s", path);
                send_screenshot_notification(path);
            }
        });
    }

    [GtkCallback]
    private async void on_screenshot_full() {
        this.visible = false;
        screen_rec.take_screenshot.begin(false, null, (obj, res) => {
            string? path = screen_rec.take_screenshot.end(res);
            if (path != null) {
                debug("Screenshot saved to: %s", path);
                send_screenshot_notification(path);
            }
        });
    }

    private void send_screenshot_notification(string path) {
        var n = new AstalNotifd.Notification() {
            app_name = "Morghulis ScreenRecord",
            body = "Screenshot saved to: %s".printf(path),
            app_icon = APP_ICON_NAME,
        };

        var copy_action = new AstalNotifd.Action("copy", "Copy");

        copy_action.invoked.connect(() => {
            copy_image_to_clipboard(path);
        });

        var open_action = new AstalNotifd.Action("open", "Open Directory");
        open_action.invoked.connect(() => {
            open_image_directory(path);
        });

        n.add_action(copy_action);
        n.add_action(open_action);

        AstalNotifd.send_notification.begin(n);
    }

    private void copy_image_to_clipboard(string path) {
        try {
            var file = File.new_for_path(path);
            var texture = Gdk.Texture.from_file(file);
            var clipboard = Gdk.Display.get_default().get_clipboard();
            clipboard.set_texture(texture);
            debug("Image copied to clipboard: %s", path);
        } catch (Error e) {
            critical("Failed to copy image to clipboard: %s", e.message);
        }
    }

    private void open_image_directory(string path) {
        try {
            var file = File.new_for_path(path);
            var parent = file.get_parent();
            if (parent != null) {
                AppInfo.launch_default_for_uri(parent.get_uri(), null);
                debug("Opened directory: %s", parent.get_path());
            }
        } catch (Error e) {
            critical("Failed to open directory: %s", e.message);
        }
    }

    [GtkCallback]
    private async void on_toggle_record() {
        if (_screen_rec.is_recording) {
            screen_rec.stop_record();
            AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
                app_name = "Morghulis ScreenRecord",
                body = "Screen recording stopped.",
                app_icon = APP_ICON_NAME,
            });
        } else {
            this.visible = false;
            screen_rec.start_record(false, null);
        }
    }

    private void start_timer() {
        if (_timer_id != 0) {
            Source.remove(_timer_id);
        }
        _timer_id = Timeout.add(100, () => {
            update_status_label();
            return true;
        });
        update_status_label();
    }

    private void stop_timer() {
        if (_timer_id != 0) {
            Source.remove(_timer_id);
            _timer_id = 0;
        }
        status_label.label = "00:00";
    }

    private void update_status_label() {
        double duration = screen_rec.get_recording_duration();
        int total_seconds = (int)duration;
        int hours = total_seconds / 3600;
        int minutes = (total_seconds % 3600) / 60;
        int seconds = total_seconds % 60;

        if (hours > 0) {
            status_label.label = "%02d:%02d:%02d".printf(hours, minutes, seconds);
        } else {
            status_label.label = "%02d:%02d".printf(minutes, seconds);
        }
    }

    [GtkCallback]
    private string get_status_icon(bool is_recording) {
        if (is_recording) {
            return "media-playback-stop-symbolic";
        } else {
            return "media-record-symbolic";
        }
    }

    private void focus_button(int index) {
        if (index < 0 || index >= _buttons.length) {
            return;
        }

        for (int i = 0; i < _buttons.length; i++) {
            _buttons[i].remove_css_class("suggested-action");
        }

        _focused_button_index = index;
        _buttons[index].add_css_class("suggested-action");
        main_box.add_css_class("keyboard-focused");

        reset_focus_timeout();
    }

    private void reset_focus_timeout() {
        if (_focus_timeout_id != 0) {
            Source.remove(_focus_timeout_id);
        }

        _focus_timeout_id = Timeout.add_seconds(5, () => {
            main_box.remove_css_class("keyboard-focused");
            _focus_timeout_id = 0;
            return false;
        });
    }

    [GtkCallback]
    public void key_released(uint keyval, uint _, Gdk.ModifierType __) {
        if (keyval == Gdk.Key.Escape) {
            this.visible = false;
        } else if (keyval == Gdk.Key.Left) {
            int new_index = _focused_button_index - 1;
            if (new_index < 0) {
                new_index = _buttons.length - 1;
            }
            focus_button(new_index);
        } else if (keyval == Gdk.Key.Right) {
            int new_index = (_focused_button_index + 1) % _buttons.length;
            focus_button(new_index);
        } else if (keyval == Gdk.Key.Return || keyval == Gdk.Key.space) {
            _buttons[_focused_button_index].activate();
        }
    }

    ~ScreenRecord() {
        if (_focus_timeout_id != 0) {
            Source.remove(_focus_timeout_id);
        }
    }
}
