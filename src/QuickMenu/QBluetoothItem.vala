[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QBluetoothItem.ui")]
public class QBluetoothItem : Gtk.ListBoxRow {
    public AstalBluetooth.Device device { get; construct set; }

    public bool active {
        get {
            return has_css_class("accent");
        }
        set {
            if (value) {
                this.add_css_class("accent");
            } else {
                this.remove_css_class("accent");
            }
        }
    }

    public QBluetoothItem(AstalBluetooth.Device? device) {
        Object(
            device: device
        );
    }

    [GtkCallback]
    public void switch_connection() {
        if (this.device.connected) {
            this.device.disconnect_device.begin();
        } else {
            this.device.connect_device.begin();
        }
    }

    [GtkCallback]
    public string get_device_name(string? name) {
        return name ?? "Unknown Device";
    }

    [GtkCallback]
    public string device_icon(string? icon) {
        if (icon == null) {
            return "bluetooth-active";
        }
        return icon;
    }

    [GtkCallback]
    public string battery_percent(double percent) {
        return @"$(Math.round(percent * 100))%";
    }

    [GtkCallback]
    public bool is_battery_a_real_thing(double percent) {
        return percent != -1;
    }
}
