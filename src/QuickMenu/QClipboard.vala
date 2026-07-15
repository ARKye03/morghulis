// Clipboard history picker: a list of stored entries; activating one
// re-publishes it as the current selection and closes the menu.
public class QClipboard : Adw.Bin {
    construct {
        var clipboard = Clipboard.get_default();

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

        var list_view = new Gtk.ListView(new Gtk.NoSelection(clipboard.history), factory);
        list_view.add_css_class("clipboard-history");
        list_view.activate.connect((pos) => {
            var entry = (ClipboardEntry) clipboard.history.get_item(pos);
            if (entry != null) {
                clipboard.copy(entry);
            }
            QuickMenu.instance.visible = false;
        });

        var scrollable = new ScrollableIndicatorMenu() {
            vexpand = true,
            css_classes = new string[] { "background", "padding_10" },
            child = list_view,
        };

        var header = new Adw.HeaderBar() {
            show_end_title_buttons = false,
        };

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.append(header);
        box.append(scrollable);
        this.child = box;
    }
}
