// File search view backed by the GNOME Nautilus SearchProvider2 over DBus.
public class FilesCmd : Gtk.Box, ICommand, IResultProvider {
    private GnomeSearchProvider _provider;
    private Gtk.SingleSelection _selection;
    private uint _debounce = 0;

    public string icon_name { get { return "folder-symbolic"; } }

    construct {
        this.orientation = Gtk.Orientation.VERTICAL;

        _provider = new GnomeSearchProvider("org.gnome.Nautilus.search-provider.ini");
        _selection = new Gtk.SingleSelection(_provider.results) {
            autoselect = true,
            can_unselect = false,
        };

        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((obj) => {
            var item = (Gtk.ListItem) obj;
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            box.append(new Gtk.Image() { icon_size = Gtk.IconSize.LARGE });

            var text = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            text.append(new Gtk.Label(null) { halign = Gtk.Align.START, ellipsize = Pango.EllipsizeMode.END });
            text.append(new Gtk.Label(null) {
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "dim-label" },
            });
            box.append(text);
            item.child = box;
        });
        factory.bind.connect((obj) => {
            var item = (Gtk.ListItem) obj;
            var result = (SearchResult) item.item;
            var box = (Gtk.Box) item.child;
            var image = (Gtk.Image) box.get_first_child();
            var text = (Gtk.Box) box.get_last_child();

            if (result.icon != null) {
                image.set_from_gicon(result.icon);
            } else {
                image.icon_name = "text-x-generic-symbolic";
            }
            ((Gtk.Label) text.get_first_child()).label = result.name;
            ((Gtk.Label) text.get_last_child()).label = result.description;
        });

        var list_view = new Gtk.ListView(_selection, factory) {
            single_click_activate = true,
        };
        list_view.add_css_class("runner-results");
        list_view.activate.connect((pos) => {
            run_result(_selection.get_item(pos) as SearchResult);
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

    private void run_result(SearchResult? result) {
        if (result != null) {
            result.activate();
        }
        Runner.instance.visible = false;
    }

    public void handle_input(string input) {
        if (_debounce > 0) {
            Source.remove(_debounce);
        }
        _debounce = Timeout.add(150, () => {
            _provider.search.begin(input.strip());
            _debounce = 0;
            return Source.REMOVE;
        });
    }

    public void on_activate() {
        _provider.search.begin("");
    }

    public void on_deactivate() {
        if (_debounce > 0) {
            Source.remove(_debounce);
            _debounce = 0;
        }
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
        run_result(_selection.selected_item as SearchResult);
        return true;
    }
}
