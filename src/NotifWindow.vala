using GLib;

public class NotifWindow : Astal.Window {
	private AstalNotifd.Notifd notifd;
	private Gtk.ListBox notifications;
	private int DEFAULT_EXPIRE_TIMEOUT = 3000;

	public NotifWindow() {
		Object(
			title: "Notifications",
			name: "notifications",
			anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM,
			exclusivity: Astal.Exclusivity.IGNORE
			);
		present();
	}

	construct {
		notifd = AstalNotifd.get_default();
		notifications = new Gtk.ListBox();
		this.set_child(notifications);

		this.notifd.notified.connect((id, replace) => this.on_notification_added(id, replace, this.notifications));
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = notifd.get_notification(notification_id);
		var notif_pop = new NotifPop(notification);
		notif_list_box.prepend(notif_pop);

		int timeout = get_notification_timeout(notification);
		Timeout.add(timeout, () => {
			notif_list_box.remove(notif_pop);
			print("removing notif\n");
			return true;
		});
	}

	private int get_notification_timeout(AstalNotifd.Notification notification) {
		return notification.expire_timeout != 0 ? notification.expire_timeout : DEFAULT_EXPIRE_TIMEOUT;
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
