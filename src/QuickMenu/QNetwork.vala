[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
    private AstalNetwork.Wifi _wifi;
    private HashTable<AstalNetwork.AccessPoint, QNetworkItem> ap_items;
    private uint _scroll_indicator_timeout_id = 0;
    private Gtk.Adjustment _vadj;

    public AstalNetwork.Network network { get; set; }

    [GtkChild]
    private unowned Gtk.ScrolledWindow scrolled_window;

    [GtkChild]
    private unowned Gtk.ListBox wifi_list;

    [GtkChild]
    private unowned Gtk.Revealer go_down_revealer;

    [GtkChild]
    private unowned Gtk.Image scan_button_image;

    construct {
        ap_items = new HashTable<AstalNetwork.AccessPoint, QNetworkItem>(direct_hash, direct_equal);

        network = AstalNetwork.get_default();
        if (network == null || network.wifi == null) {
            warning("Network or WiFi interface not available");
            return;
        }
        _wifi = network.wifi;

        wifi_list.set_sort_func(sort_network_items);

        _wifi.access_point_added.connect(on_added_ap);
        _wifi.access_point_removed.connect(on_removed_ap);
        _wifi.notify["active-access-point"].connect(update_active_states);
        _wifi.access_points.foreach(on_added_ap);
        _wifi.notify["scanning"].connect(() => {
            if (_wifi.scanning) {
                scan_button_image.add_css_class("rotieren");
            } else {
                scan_button_image.remove_css_class("rotieren");
            }
        });
        update_active_states();

        _vadj = scrolled_window.vadjustment;
        _vadj.notify["upper"].connect(debounce_scroll_indicator);
        _vadj.notify["page-size"].connect(debounce_scroll_indicator);
        _vadj.notify["value"].connect(debounce_scroll_indicator);

        update_scroll_indicator();
    }

    private void on_added_ap(AstalNetwork.AccessPoint ap) {
        if (ap_items.contains(ap)) {
            return;
        }

        var item = new QNetworkItem(ap, network);
        ap_items.insert(ap, item);
        wifi_list.append(item);

        Idle.add(() => {
            debounce_scroll_indicator();
            return Source.REMOVE;
        });
    }

    private void on_removed_ap(AstalNetwork.AccessPoint ap) {
        var item = ap_items.lookup(ap);

        if (item != null) {
            wifi_list.remove(item);
            ap_items.remove(ap);

            Idle.add(() => {
                debounce_scroll_indicator();
                return Source.REMOVE;
            });
        }
    }

    private int sort_network_items(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var item1 = (QNetworkItem)row1;
        var item2 = (QNetworkItem)row2;

        return item1.compare_to(item2);
    }

    private void update_active_states() {
        if (network.wifi.active_access_point == null) {
            return;
        }

        var active_ap = network.wifi.active_access_point;

        ap_items.foreach((ap, item) => {
            item.active = false;
        });

        var active_item = ap_items.lookup(active_ap);
        if (active_item != null) {
            active_item.active = true;
        }

        wifi_list.invalidate_sort();
    }

    // Debouncing shits is the coolest shit ever
    // It's like using HashMaps in LeetCode, feels like chee'in (<== Read it with brit accent)
    private void debounce_scroll_indicator() {
        if (_scroll_indicator_timeout_id > 0) {
            Source.remove(_scroll_indicator_timeout_id);
        }
        // ----------------------------------- ¯\_(ツ)_/¯
        _scroll_indicator_timeout_id = Timeout.add(0x64, () => {
            update_scroll_indicator();
            _scroll_indicator_timeout_id = 0;
            return Source.REMOVE;
        });
    }

    private void update_scroll_indicator() {
        bool is_scrollable = _vadj.upper > _vadj.page_size;
        bool not_at_bottom = (_vadj.value + _vadj.page_size) < _vadj.upper - 1;

        go_down_revealer.reveal_child = is_scrollable && not_at_bottom;
    }

    [GtkCallback]
    public void refresh() {
        network.wifi.scan();
    }
}
