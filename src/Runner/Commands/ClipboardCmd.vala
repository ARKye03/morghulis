// Clipboard history picker: activating an entry re-publishes it as the current
// selection and closes the Runner; typing filters by preview text.
public class ClipboardCmd : Gtk.Box, ICommand, IResultProvider {
    private Clipboard _clipboard;
    private Gtk.SingleSelection _selection;
    private Gtk.CustomFilter _filter;
    private string _query = "";

    public string icon_name { get { return "edit-paste-symbolic"; } }

    construct {
        this.orientation = Gtk.Orientation.VERTICAL;
        _clipboard = Clipboard.get_default();

        _filter = new Gtk.CustomFilter((obj) => {
            if (_query == "") {
                return true;
            }
            var entry = obj as ClipboardEntry;
            return entry != null && entry.preview.down().contains(_query.down());
        });
        var filter_model = new Gtk.FilterListModel(_clipboard.history, _filter);
        _selection = new Gtk.SingleSelection(filter_model) {
            autoselect = true,
            can_unselect = false,
        };

        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((obj) => {
            var item = (Gtk.ListItem) obj;
            item.child = new Gtk.Label(null) {
                xalign = 0,
                ellipsize = Pango.EllipsizeMode.END,
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 10,
                margin_end = 10,
            };
        });
        factory.bind.connect((obj) => {
            var item = (Gtk.ListItem) obj;
            var entry = (ClipboardEntry) item.item;
            ((Gtk.Label) item.child).label = entry.preview;
        });

        var list_view = new Gtk.ListView(_selection, factory) {
            single_click_activate = true,
        };
        list_view.add_css_class("runner-results");
        list_view.activate.connect((pos) => {
            run_entry(_selection.get_item(pos) as ClipboardEntry);
        });

        var scrollable = new Gtk.ScrolledWindow() {
            max_content_height = 400,
            propagate_natural_height = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true,
            child = list_view,
        };
        scrollable.add_css_class("bg_transparent");
        this.append(scrollable);
    }

    private void run_entry(ClipboardEntry? entry) {
        if (entry != null) {
            _clipboard.copy(entry);
        }
        Runner.instance.visible = false;
    }

    public void handle_input(string input) {
        _query = input.strip();
        _filter.changed(Gtk.FilterChange.DIFFERENT);
    }

    public void on_activate() {
        handle_input("");
    }

    public void select_next() {
        uint n = _selection.get_n_items();
        if (n == 0) {
            return;
        }
        uint cur = _selection.selected;
        if (cur == Gtk.INVALID_LIST_POSITION) {
            _selection.selected = 0;
        } else if (cur + 1 < n) {
            _selection.selected = cur + 1;
        }
    }

    public void select_prev() {
        uint cur = _selection.selected;
        if (cur == Gtk.INVALID_LIST_POSITION) {
            if (_selection.get_n_items() > 0) {
                _selection.selected = 0;
            }
        } else if (cur > 0) {
            _selection.selected = cur - 1;
        }
    }

    public bool activate_selected() {
        run_entry(_selection.selected_item as ClipboardEntry);
        return true;
    }
}
