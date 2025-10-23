[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetworkItem.ui")]
public class QNetworkItem : Gtk.ListBoxRow {
    public AstalNetwork.AccessPoint access_point { get; construct; }
    public AstalNetwork.Network network { get; construct; }

    public bool active {
        get {
            return this.has_css_class("accent");
        }
        set {
            if (value) {
                this.add_css_class("accent");
            } else {
                this.remove_css_class("accent");
            }
        }
    }

    public QNetworkItem(AstalNetwork.AccessPoint ap, AstalNetwork.Network net) {
        Object(access_point: ap, network: net);
    }

    [GtkCallback]
    public string ssid_name(string? ssid) {
        return ssid ?? "Unknown Network";
    }

    [GtkCallback]
    public void switch_connection() {
        if (access_point == null) {
            return;
        }

        if (active) {
            network.wifi.deactivate_connection.begin();
        } else {
            access_point.activate.begin();
        }
    }

    [GtkCallback]
    private string status_label(bool active) {
        if (active) {
            return "Connected";
        } else if (access_point != null && access_point.requires_password) {
            return "Secured";
        } else {
            return "Open";
        }
    }

    // For sorting - active connections should be at top
    public int compare_to(QNetworkItem other) {
        // Active connections first
        if (this.active && !other.active) {
            return -1;
        }
        if (!this.active && other.active) {
            return 1;
        }

        // Then by signal strength
        if (this.access_point.strength > other.access_point.strength) {
            return -1;
        }
        if (this.access_point.strength < other.access_point.strength) {
            return 1;
        }

        // Then by SSID alphabetically
        bool both_ssids_are_valid =
            (this.access_point.ssid != null && this.access_point.ssid != "") &&
            (other.access_point.ssid != null && other.access_point.ssid != "");

        if (both_ssids_are_valid) {
            return this.access_point.ssid.collate(other.access_point.ssid);
        } else {
            return 1;
        }
    }
}
