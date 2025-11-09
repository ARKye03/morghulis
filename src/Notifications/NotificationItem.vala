public class NotificationItem : Gtk.ListBoxRow {
    public AstalNotifd.Notification notification { get; set; }
    private NotificationContent _content;

    public NotificationItem(AstalNotifd.Notification notification) {
        Object(
            notification: notification,
            overflow: Gtk.Overflow.HIDDEN,
            css_classes: new string[] { "rounded", "zero_padding" },
            activatable: false
        );

        _content = new NotificationContent(notification);
        this.child = _content;
    }
}
