// Clipboard history picker: activating an entry re-publishes it as the current
// selection and closes the Runner; typing filters by preview text.
[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Commands/ClipboardCmd.ui")]
public class ClipboardCmd : Gtk.Box, ICommand, IResultProvider {
    private const int THUMB_PX = 256;

    private Clipboard _clipboard;
    private Gtk.SingleSelection _selection;
    private Gtk.CustomFilter _filter;
    private string _query = "";
    private GLib.HashTable<ClipboardEntry, Gdk.Texture> _thumbs;

    public string icon_name { get { return "edit-paste-symbolic"; } }

    [GtkChild]
    private unowned Gtk.ListView list_view;

    construct {
        _clipboard = Clipboard.get_default();
        _thumbs = new GLib.HashTable<ClipboardEntry, Gdk.Texture>(direct_hash, direct_equal);
        _clipboard.history.items_changed.connect(prune_thumbs);

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
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);

            box.append(new Gtk.Picture() {
                content_fit = Gtk.ContentFit.SCALE_DOWN,
                halign = Gtk.Align.START,
                can_shrink = true,
                height_request = 40,
                width_request = 40,
                visible = false,
            });

            var text = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
                valign = Gtk.Align.CENTER,
                hexpand = true,
            };
            text.append(new Gtk.Label(null) {
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END,
            });
            text.append(new Gtk.Label(null) {
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "dim-label" },
                visible = false,
            });
            box.append(text);
            item.child = box;
        });
        factory.bind.connect((obj) => {
            var item = (Gtk.ListItem) obj;
            bind_entry(item, (ClipboardEntry) item.item);
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

    private void bind_entry(Gtk.ListItem item, ClipboardEntry entry) {
        var box = (Gtk.Box) item.child;
        var thumb = (Gtk.Picture) box.get_first_child();
        var text = (Gtk.Box) box.get_last_child();
        var title = (Gtk.Label) text.get_first_child();
        var meta = (Gtk.Label) text.get_last_child();

        if (entry.is_text) {
            thumb.visible = false;
            thumb.paintable = null;
            meta.visible = false;
            title.label = entry.preview;
            return;
        }

        title.label = entry.mime;
        meta.label = "%s KB".printf((entry.data.length / 1024).to_string());
        meta.visible = true;

        var cached = _thumbs.get(entry);
        if (cached != null) {
            apply_thumb(thumb, cached);
            return;
        }

        thumb.visible = false;
        thumb.paintable = null;
        ImageLoader.from_bytes.begin(entry.data, THUMB_PX, null, (o, res) => {
            var tex = ImageLoader.from_bytes.end(res);
            if (tex == null) {
                return;
            }
            _thumbs.set(entry, tex);
            // Guard against ListItem recycling: only paint if still the same entry.
            if (item.item == entry) {
                apply_thumb(thumb, tex);
            }
        });
    }

    private static void apply_thumb(Gtk.Picture thumb, Gdk.Texture tex) {
        thumb.paintable = tex;
        thumb.visible = true;
    }

    private void prune_thumbs() {
        if (_thumbs.length == 0) {
            return;
        }
        var live = new GenericSet<ClipboardEntry>(direct_hash, direct_equal);
        for (uint i = 0; i < _clipboard.history.get_n_items(); i++) {
            live.add((ClipboardEntry) _clipboard.history.get_item(i));
        }
        _thumbs.foreach_remove((entry, tex) => !live.contains(entry));
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
