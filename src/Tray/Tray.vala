public class Tray : Gtk.Widget {
    private HashTable<string, Gtk.Widget> items;
    private Gtk.FlowBox flow_box;

    public AstalTray.Tray tray { get; private set; }

    construct {
        this.tray = AstalTray.get_default();
        this.items = new HashTable<string, Gtk.Widget>(str_hash, str_equal);
        this.layout_manager = new Gtk.BinLayout();
        this.visible = false;
        this.flow_box = new Gtk.FlowBox() {
            max_children_per_line = 4,
            homogeneous = true,
            column_spacing = row_spacing = 1,
            selection_mode = Gtk.SelectionMode.NONE,
        };

        this.tray.item_added.connect(on_added);
        this.tray.item_removed.connect(on_removed);
        flow_box.set_parent(this);
    }

    private void on_added(AstalTray.Tray tray, string item_id) {
        if (this.items.contains(item_id)) {
            return;
        }
        var tray_item = this.tray.get_item(item_id);
        if (tray_item.id != null && tray_item.id != "") {
            var item = create_tray_item(tray_item);
            this.items.insert(item_id, item);
            flow_box.append(item);
            this.visible = true;
        }
    }

    private void on_removed(AstalTray.Tray tray, string item_id) {
        if (!this.items.contains(item_id)) {
            return;
        }
        flow_box.remove(this.items.take(item_id));
        this.visible = items.size() > 0;
    }

    private Gtk.FlowBoxChild create_tray_item(AstalTray.TrayItem item) {
        var button = new Gtk.MenuButton() {
            direction = Gtk.ArrowType.UP,
        };

        item.notify["action_group"].connect(() => {
            button.insert_action_group("dbusmenu", item.action_group);
        });
        button.insert_action_group("dbusmenu", item.action_group);
        item.bind_property("menu-model", button, "menu-model", BindingFlags.SYNC_CREATE);
        var icon = new Gtk.Image();
        item.bind_property("gicon", icon, "gicon", BindingFlags.SYNC_CREATE);
        button.child = icon;

        return new Gtk.FlowBoxChild() {
                   child = button
        };
    }
}
