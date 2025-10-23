public class PopupNotificationItem : Gtk.ListBoxRow {
    private Gtk.Revealer _revealer;

    public uint transition_duration {
        get { return _revealer.transition_duration; }
    }
    private NotificationContent _notification_content;

    public AstalNotifd.Notification notification { get; set; }

    public PopupNotificationItem(AstalNotifd.Notification notification) {
        Object(
            notification: notification,
            overflow: Gtk.Overflow.HIDDEN,
            selectable: false,
            activatable: false,
            css_classes: new string[] { "zero_padding" }
        );

        _revealer = new Gtk.Revealer() {
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            transition_duration = 200
        };
        this.child = _revealer;

        _notification_content = new NotificationContent(notification);
        _revealer.child = _notification_content;

        Timeout.add(50, () => {
            _revealer.reveal_child = true;
            return Source.REMOVE;
        });
    }

    public void dismiss_notif(bool dismiss_from_daemon = true) {
        _revealer.reveal_child = false;
        if (dismiss_from_daemon) {
            Timeout.add(_revealer.transition_duration, () => {
                _notification_content.dismiss_notif();
                return Source.REMOVE;
            });
        }
    }
}
