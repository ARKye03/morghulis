[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QBluetooth.ui")]
public class QBluetooth : Gtk.Box {
    public AstalBluetooth.Bluetooth bluetooth { get; set; }

    [GtkChild]
    private unowned Gtk.ListBox blue_list;

    [GtkChild]
    private unowned Gtk.Image scan_button_image;

    [GtkChild]
    private unowned ScrollableIndicatorMenu scrolled_window;

    construct {
        bluetooth = AstalBluetooth.get_default();

        bluetooth.device_added.connect(on_device_added);
        bluetooth.device_removed.connect(on_device_removed);
        bluetooth.devices.@foreach(on_device_added);
        bluetooth.adapter.notify["discovering"].connect(() => {
            if (bluetooth.adapter.discovering) {
                scan_button_image.add_css_class("rotieren");
            } else {
                scan_button_image.remove_css_class("rotieren");
            }
        });

        this.blue_list.set_sort_func(sfunc);
        this.blue_list.invalidate_sort();
    }

    [GtkCallback]
    public void refresh() {
        if (bluetooth.adapter.discovering) {
            try {
                bluetooth.adapter.stop_discovery();
            } catch (Error e) {
                critical("Error: %s", e.message);
            }
        } else {
            try {
                bluetooth.adapter.start_discovery();
            } catch (Error e) {
                critical("Error: %s", e.message);
            }
        }
    }

    private int sfunc(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
        QBluetoothItem a = (QBluetoothItem)la;

        return a.device.connected ? -1 : 1;
    }

    private void on_device_added(AstalBluetooth.Device device) {
        blue_list.append(new QBluetoothItem(device));
        this.blue_list.invalidate_sort();

        Idle.add(() => {
            scrolled_window.refresh_scroll_indicator();
            return Source.REMOVE;
        });
    }

    private void on_device_removed(AstalBluetooth.Device device) {
        var current = (QBluetoothItem)blue_list.get_first_child();

        while (current != null) {
            if (current.device == device) {
                blue_list.remove(current);
                break;
            }

            current = (QBluetoothItem)current.get_next_sibling();
        }
        this.blue_list.invalidate_sort();
        Idle.add(() => {
            scrolled_window.refresh_scroll_indicator();
            return Source.REMOVE;
        });
    }
}
