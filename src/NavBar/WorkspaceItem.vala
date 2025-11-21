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
        setup_drag_and_drop();
    }

    private void setup_drag_and_drop() {
        var drop_target = new Gtk.DropTarget(typeof(File), Gdk.DragAction.MOVE);

        drop_target.enter.connect(() => {
            if (left_click_callback != null) {
                left_click_callback();
            }

            return Gdk.DragAction.MOVE;
        });

        this.add_controller(drop_target);
    }

    private void setup_click_handlers() {
        var gesture = new Gtk.GestureClick() {
            button = 0,
            propagation_phase = Gtk.PropagationPhase.CAPTURE
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
