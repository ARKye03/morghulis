// Clipboard history picker: activating an entry re-publishes it as the current
// selection and closes the Runner; typing filters by preview text.
[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Commands/ClipboardCmd.ui")]
public class ClipboardCmd : Gtk.Box, ICommand, IResultProvider {
    private Clipboard _clipboard;
    private Gtk.SingleSelection _selection;
    private Gtk.CustomFilter _filter;
    private string _query = "";

    public string icon_name { get { return "edit-paste-symbolic"; } }

    [GtkChild]
    private unowned Gtk.ListView list_view;

    construct {
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

        list_view.model = _selection;
        list_view.factory = factory;
        list_view.activate.connect((pos) => {
            run_entry(_selection.get_item(pos) as ClipboardEntry);
        });
    }

    private void run_entry(ClipboardEntry? entry) {
        if (entry != null) {
            _clipboard.copy(entry);
        }
        Runner.instance.visible = false;
    }

    private void scroll_to_selected() {
        uint sel = _selection.selected;
        if (sel != Gtk.INVALID_LIST_POSITION) {
            list_view.scroll_to(sel, Gtk.ListScrollFlags.NONE, null);
        }
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
        scroll_to_selected();
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
        scroll_to_selected();
    }

    public bool activate_selected() {
        run_entry(_selection.selected_item as ClipboardEntry);
        return true;
    }
}
