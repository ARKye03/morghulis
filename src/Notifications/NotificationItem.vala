public class NotificationItem : Gtk.ListBoxRow {
	public AstalNotifd.Notification notification { get; set; }
	private NotificationContent _content;

	public NotificationItem(AstalNotifd.Notification notification) {
		Object(
			notification: notification
		);

		_content = new NotificationContent(notification);
		this.child = _content;
	}
}
