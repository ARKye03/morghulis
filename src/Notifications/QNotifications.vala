[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNotifications.ui")]
public class QNotifications : Gtk.Box {
	private AstalNotifd.Notifd _notifd;

	public bool at_least_one_notification { get; private set; }

	[GtkChild]
	private unowned Gtk.ListBox notifications;

	construct {
		_notifd = AstalNotifd.get_default();

		this._notifd.notifications.@foreach(n => this.on_notification_added(n.id, false, this.notifications));
		this._notifd.notified.connect((id, replace) => {
			this.on_notification_added(id, replace, this.notifications);
		});
		this._notifd.resolved.connect((id) => this.remove_notification(id, this.notifications));

		if (_notifd.notifications.length() == 0) {
			this.at_least_one_notification = false;
		}
	}

	[GtkCallback]
	public async void clear_notifications() {
		// Dismiss all notifications, using a copy of the list to avoid modification during iteration
		this._notifd.notifications.copy().@foreach(n => n.dismiss());
	}

	[GtkCallback]
	public string get_stack_page_to_show(bool has_notifications) {
		return has_notifications ? "notifications" : "no_notifications";
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = _notifd.get_notification(notification_id);
		notif_list_box.prepend(new NotificationItem(notification));

		if (_notifd.notifications.length() > 0) {
			this.at_least_one_notification = true;
		}
	}

	private void remove_notification(uint notification_id, Gtk.ListBox notif_list_box) {
		NotificationItem? notif_popup = (NotificationItem)notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_list_box.remove(notif_popup);
				break;
			}
			notif_popup = (NotificationItem)notif_popup.get_next_sibling();
		}
		if (_notifd.notifications.length() == 0) {
			this.at_least_one_notification = false;
		}
	}
}
