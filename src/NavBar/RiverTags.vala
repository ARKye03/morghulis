// register-if: river
public class RiverTags : Rolltop {
    private AstalRiver.River _river;
    private AstalRiver.Output _output;
    private uint _total_tags;
    private List<WorkspaceItem> _tags = new List<WorkspaceItem>();
    private const string SHIFTTAGS_PREV = "river-shifttags --occupied --shifts -1";
    private const string SHIFTTAGS_NEXT = "river-shifttags --occupied";

    public RiverTags(AstalRiver.River river, uint max_tags = 9) {
        this._river = river;
        this._total_tags = max_tags;
        this._output = river.focused_output;

        initialize_items();

        _output.notify.connect(update_css);
        update_css();

        setup_scroll_handler();
    }

    protected override void setup_items_container(Gtk.Box container) {
        for (int i = 0; i < _total_tags; i++) {
            int tag_index = i;

            var tag_button = new WorkspaceItem(
                () => {
                this._output.focused_tags = 1 << tag_index;
            },
                null,
                () => {
                this._output.focused_tags ^= 1 << tag_index;
            }
                             ) {
                child = new Gtk.Image.from_icon_name(NavBar.icon_names[i]) {
                    pixel_size = 20
                }
            };
            tag_button.add_css_class("empty");

            add_workspace_item(container, tag_button);
            _tags.append(tag_button);
        }
    }

    private void setup_scroll_handler() {
        bool shifttags_available = check_shifttags();

        if (shifttags_available) {
            var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
            scroll_controller.scroll.connect((delta_x, delta_y) => {
                string command = delta_y > 0 ? SHIFTTAGS_PREV : SHIFTTAGS_NEXT;
                try {
                    Process.spawn_command_line_async(command);
                } catch (SpawnError e) {
                    warning("Failed to execute %s: %s", command, e.message);
                }
                return true;
            });
            this.add_controller(scroll_controller);
        } else {
            warning("River-shifttags not found, please install it to use the tags feature");
        }
    }

    private bool check_shifttags() {
        try {
            string standard_output;
            string standard_error;
            int wait_status;
            Process.spawn_command_line_sync("which river-shifttags",
                                            out standard_output,
                                            out standard_error,
                                            out wait_status);
            return wait_status == 0;
        } catch (SpawnError e) {
            warning("Failed to check for command river-shifttags: %s", e.message);
            return false;
        }
    }

    private void update_css() {
        int index = 0;
        int focused_index = -1;

        foreach (var tag_button in _tags) {
            uint occupied_tags = _output.occupied_tags;
            uint focused_tags = _output.focused_tags;
            uint urgent_tags = _output.urgent_tags;

            if ((focused_tags & (1 << index)) != 0) {
                tag_button.set_css_classes({ "accent" });
                focused_index = index;
            } else if ((urgent_tags & (1 << index)) != 0) {
                tag_button.set_css_classes({ "urgent" });
            } else if ((occupied_tags & (1 << index)) != 0) {
                tag_button.set_css_classes({ "occupied" });
            } else {
                tag_button.set_css_classes({ "empty" });
            }
            index++;
        }

        if (focused_index >= 0) {
            update_underline_position(focused_index);
        }
    }
}
