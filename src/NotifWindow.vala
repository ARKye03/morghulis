[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotifWindow.ui")]
public class NotifWindow : Gtk.Box {
	private AstalNotifd.Notifd notifd;

	[GtkChild]
	private unowned Gtk.ListBox notifications;
	[GtkCallback]
	public void clear_notifications() {
		this.notifd.notifications.@foreach(n => n.dismiss());
	}

	construct {
		notifd = AstalNotifd.get_default();
		this.notifd.notifications.@foreach(n => this.on_notification_added(n.id, false, this.notifications));
		this.notifd.notified.connect((id, replace) => this.on_notification_added(id, replace, this.notifications));
		this.notifd.resolved.connect((id) => this.remove_notification(id, this.notifications));
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = notifd.get_notification(notification_id);
		notif_list_box.prepend(new NotifPop(notification));
	}

	private void remove_notification(uint notificationId, Gtk.ListBox notifListBox) {
		int i = 0;

		NotifPop ?notifPopup = (NotifPop)notifListBox.get_row_at_index(0);

		while (notifPopup != null) {
			if (notifPopup.notification.id == notificationId) {
				notifListBox.remove(notifPopup);
				break;
			}
			notifPopup = (NotifPop)notifListBox.get_row_at_index(++i);
		}
	}
}
