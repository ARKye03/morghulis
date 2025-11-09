[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNotifications.ui")]
public class QNotifications : Gtk.Box {
    private AstalNotifd.Notifd _notifd;
    private HashTable<uint, NotificationItem> _notif_items;
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
        this._notif_items = new HashTable<uint, NotificationItem>(direct_hash, direct_equal);
        this._vadj = scrolled_window.get_vadjustment();
        _vadj.notify["upper"].connect(debounce_scroll_indicator);
        _vadj.notify["page-size"].connect(debounce_scroll_indicator);
        _vadj.notify["value"].connect(debounce_scroll_indicator);

        this._notifd.notifications.@foreach(n => this.on_notification_added(n.id, false));
        this._notifd.notified.connect(on_notification_added);
        this._notifd.resolved.connect(remove_notification);

        this.at_least_one_notification = _notif_items.size() > 0;
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
        var item = new NotificationItem(notification);

        _notif_items.insert(notification_id, item);
        notif_list.prepend(item);

        Idle.add(() => {
            this.at_least_one_notification = _notif_items.size() > 0;
            debounce_scroll_indicator();
            return Source.REMOVE;
        });
    }

    private void remove_notification(uint notification_id) {
        var item = _notif_items.lookup(notification_id);

        if (item != null) {
            notif_list.remove(item);
            _notif_items.remove(notification_id);
        }

        Idle.add(() => {
            this.at_least_one_notification = _notif_items.size() > 0;
            debounce_scroll_indicator();
            return Source.REMOVE;
        });
    }

    private void debounce_scroll_indicator() {
        if (_scroll_indicator_timeout_id > 0) {
            Source.remove(_scroll_indicator_timeout_id);
        }

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
