[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetwork.ui")]
public class QNetwork : Gtk.Box {
    private AstalNetwork.Wifi _wifi;

    public AstalNetwork.Network network { get; set; }

    [GtkChild]
    private unowned Gtk.ListBox wifi_list;

    construct {
        network = AstalNetwork.get_default();
        if (network == null || network.wifi == null) {
            warning("Network or WiFi interface not available");
            return;
        }
        _wifi = network.wifi;

        wifi_list.set_sort_func(sort_network_items);

        _wifi.access_point_added.connect(on_added_ap);
        _wifi.access_point_removed.connect(on_removed_ap);
        _wifi.access_points.foreach(on_added_ap);
        _wifi.notify["active-access-point"].connect(update_active_states);
        update_active_states();
    }

    private void on_added_ap(AstalNetwork.AccessPoint ap) {
        var item = new QNetworkItem(ap, network);

        wifi_list.append(item);
    }

    private void on_removed_ap(AstalNetwork.AccessPoint ap) {
        var current = (QNetworkItem)wifi_list.get_first_child();

        while (current != null) {
            if (current.access_point.ssid == ap.ssid) {
                wifi_list.remove(current);
                return;
            }
            current = (QNetworkItem)current.get_next_sibling();
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

        var active_ap_ssid = network.wifi.active_access_point.ssid;

        if (active_ap_ssid == null || active_ap_ssid == "") {
            return;
        }

        var current = (QNetworkItem)wifi_list.get_first_child();

        while (current != null) {
            if (current.access_point.ssid == active_ap_ssid) {
                current.active = true;
                break;
            } else {
                current.active = false;
            }
            current = (QNetworkItem)current.get_next_sibling();
        }

        wifi_list.invalidate_sort();
    }

    [GtkCallback]
    public void refresh() {
        network.wifi.scan();
    }
}
