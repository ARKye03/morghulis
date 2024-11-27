[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotifWindow.ui")]
public class NotifWindow : Gtk.Box {
	private AstalNotifd.Notifd notifd;
	Gtk.MediaFile notif_sound;

	[GtkChild]
	private unowned Gtk.ListBox notifications;
	[GtkCallback]
	public void clear_notifications() {
		this.notifd.notifications.@foreach(n => n.dismiss());
	}

	construct {
		notifd = AstalNotifd.get_default();
		this.notifd.notifications.@foreach(n => this.on_notification_added(n.id, false, this.notifications));
		this.notifd.notified.connect((id, replace) => {
			this.on_notification_added(id, replace, this.notifications);
			this.notif_sound.play();
		});
		this.notifd.resolved.connect((id) => this.remove_notification(id, this.notifications));
		notif_sound = Gtk.MediaFile.for_resource("/com/github/ARKye03/morghulis/assets/colloid-notif-sound.opus");
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = notifd.get_notification(notification_id);
		notif_list_box.prepend(new NotifPop(notification));
	}

	private void remove_notification(uint notification_id, Gtk.ListBox notif_list_box) {
		int i = 0;

		NotifPop ?notif_popup = (NotifPop)notif_list_box.get_row_at_index(0);

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_list_box.remove(notif_popup);
				break;
			}
			notif_popup = (NotifPop)notif_list_box.get_row_at_index(++i);
		}
	}
}
