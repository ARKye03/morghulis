[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
    private AstalNetwork.Wifi _wifi;
    // Use the AccessPoint object itself as the key, as idk what else to do
    private HashTable<AstalNetwork.AccessPoint, QNetworkItem> ap_items;

    public AstalNetwork.Network network { get; set; }

    [GtkChild]
    private unowned Gtk.ListBox wifi_list;

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
        update_active_states();
    }

    private void on_added_ap(AstalNetwork.AccessPoint ap) {
        if (ap_items.contains(ap)) {
            return;
        }

        var item = new QNetworkItem(ap, network);
        ap_items.insert(ap, item);
        wifi_list.append(item);
    }

    private void on_removed_ap(AstalNetwork.AccessPoint ap) {
        var item = ap_items.lookup(ap);

        if (item != null) {
            wifi_list.remove(item);
            ap_items.remove(ap);
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

        // Reset all items to inactive - O(n) but necessary
        ap_items.foreach((ap, item) => {
            item.active = false;
        });

        var active_item = ap_items.lookup(active_ap);
        if (active_item != null) {
            active_item.active = true;
        }

        wifi_list.invalidate_sort();
    }

    [GtkCallback]
    public void refresh() {
        network.wifi.scan();
    }
}
