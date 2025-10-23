public class WorkspaceItem : Gtk.Button {
    public delegate void ClickCallback();

    private ClickCallback? left_click_callback;
    private ClickCallback? middle_click_callback;
    private ClickCallback? right_click_callback;

    public WorkspaceItem(
        owned ClickCallback? on_left_click = null,
        owned ClickCallback? on_middle_click = null,
        owned ClickCallback? on_right_click = null
    ) {
        Object();

        this.left_click_callback = (owned)on_left_click;
        this.middle_click_callback = (owned)on_middle_click;
        this.right_click_callback = (owned)on_right_click;

        setup_click_handlers();
    }

    private void setup_click_handlers() {
        var gesture = new Gtk.GestureClick() {
            button = 0
        };

        gesture.pressed.connect((n_press, x, y) => {
            uint button = gesture.get_current_button();

            switch (button) {
                    case Gdk.BUTTON_PRIMARY:
                        if (left_click_callback != null) {
                            left_click_callback();
                        }
                    break;

                    case Gdk.BUTTON_MIDDLE:
                        if (middle_click_callback != null) {
                            middle_click_callback();
                        }
                    break;

                    case Gdk.BUTTON_SECONDARY:
                        if (right_click_callback != null) {
                            right_click_callback();
                        }
                    break;
            }
        });

        this.add_controller(gesture);
    }

    public void set_left_click_callback(owned ClickCallback callback) {
        this.left_click_callback = (owned)callback;
    }

    public void set_middle_click_callback(owned ClickCallback callback) {
        this.middle_click_callback = (owned)callback;
    }

    public void set_right_click_callback(owned ClickCallback callback) {
        this.right_click_callback = (owned)callback;
    }
}
