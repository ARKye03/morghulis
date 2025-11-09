[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNotifications.ui")]
public class QNotifications : Gtk.Box {
    private AstalNotifd.Notifd _notifd;
    private HashTable<uint32, NotificationItem> _notif_items;
    private uint _scroll_indicator_timeout_id = 0;
    private Gtk.Adjustment _vadj;

    public bool at_least_one_notification { get; private set; }

    [GtkChild]
    private unowned Gtk.ScrolledWindow scrolled_window;

    [GtkChild]
    private unowned Gtk.ListBox notif_list;

    [GtkChild]
    private unowned Gtk.Revealer go_down_revealer;

    construct {
        this._notifd = AstalNotifd.get_default();
        this._notif_items = new HashTable<uint32, NotificationItem>(direct_hash, direct_equal);
        this._vadj = scrolled_window.get_vadjustment();
        _vadj.notify["upper"].connect(debounce_scroll_indicator);
        _vadj.notify["page-size"].connect(debounce_scroll_indicator);
        _vadj.notify["value"].connect(debounce_scroll_indicator);

        this._notifd.notifications.@foreach(n => this.on_notification_added(n.id, false));
        this._notifd.notified.connect(on_notification_added);
        this._notifd.resolved.connect(remove_notification);

        if (_notifd.notifications.length() == 0) {
            this.at_least_one_notification = false;
        }
        update_scroll_indicator();
    }

    [GtkCallback]
    public async void clear_notifications() {
        this._notifd.notifications.@foreach(n => n.dismiss());
    }

    [GtkCallback]
    public string get_stack_page_to_show(bool has_notifications) {
        return has_notifications ? "notifications" : "no_notifications";
    }

    private void on_notification_added(uint notification_id, bool is_replaced) {
        if (is_replaced) {
            remove_notification(notification_id);
        }

        var notification = _notifd.get_notification(notification_id);
        notif_list.prepend(new NotificationItem(notification));

        Idle.add(() => {
            if (_notifd.notifications.length() > 0) {
                this.at_least_one_notification = true;
            }
            debounce_scroll_indicator();

            return Source.REMOVE;
        });
    }

    private void remove_notification(uint notification_id) {
        NotificationItem? notif_popup = (NotificationItem)notif_list.get_first_child();

        while (notif_popup != null) {
            if (notif_popup.notification.id == notification_id) {
                notif_list.remove(notif_popup);
                break;
            }
            notif_popup = (NotificationItem)notif_popup.get_next_sibling();
        }
        if (_notifd.notifications.length() == 0) {
            this.at_least_one_notification = false;
        }

        Idle.add(() => {
            if (_notifd.notifications.length() > 0) {
                this.at_least_one_notification = true;
            }
            debounce_scroll_indicator();

            return Source.REMOVE;
        });
    }

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
}
