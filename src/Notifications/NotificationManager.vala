[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QNotifications.ui")]
public class QNotifications : Gtk.Box {
	private AstalNotifd.Notifd notifd { get; set; }

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
		});
		this.notifd.resolved.connect((id) => this.remove_notification(id, this.notifications));
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = notifd.get_notification(notification_id);
		notif_list_box.prepend(new NotificationItem(notification));
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
	}
}

public class NotifPopItemsCenter : Astal.Window {
	private AstalNotifd.Notifd notifd { get; set; }
	private Gtk.ListBox notif_list_box { get; set; }
	private GSound.Context scontext { get; set; }
	private uint _notif_count = 0;

	public NotifPopItemsCenter(Astal.WindowAnchor x_anchor = Astal.WindowAnchor.RIGHT) {
		Object(
			title: "Notifications",
			anchor: Astal.WindowAnchor.TOP | x_anchor
		);

		setup_sound();
		setup_window();
		setup_notifications();
	}

	private void setup_window() {
		default_width = 330;
		default_height = 0;
		margin = 5;
		set_css_classes({ "all_unset", "rounded" });
		overflow = Gtk.Overflow.HIDDEN;
		notify["visible"].connect(() => {
			if (visible) {
				this.default_height = -1;
			} else {
				this.default_height = 0;
			}
		});

		notif_list_box = new Gtk.ListBox();
		notif_list_box.set_selection_mode(Gtk.SelectionMode.NONE);
		notif_list_box.set_css_classes({ "boxed-list" });

		set_child(notif_list_box);
	}

	private void setup_notifications() {
		notifd = AstalNotifd.Notifd.get_default();
		notifd.notified.connect((id, replace) => this.handle_notification(id, replace));
		notifd.resolved.connect((id) => this.remove_notification(id));
	}

	private void handle_notification(uint notification_id, bool replace) {
		if (replace) {
			remove_notification(notification_id);
		}

		var notification = notifd.get_notification(notification_id);
		var notif_item = new NotificationItem(notification);
		notif_list_box.prepend(notif_item);
		_notif_count++;

		uint timeout_ms = notification.expire_timeout > 0 ? notification.expire_timeout * 1000 : 3000;
		Timeout.add(timeout_ms, () => {
			remove_notification(notification_id);
			return false;
		});
		this.visible = true;
		this.play_notification_sound.begin();
	}

	private void setup_sound() {
		try {
			scontext = new GSound.Context();
			scontext.init();
		} catch (Error e) {
			warning("Failed to create sound context: %s", e.message);
		}
	}

	private async void play_notification_sound() {
		if (!notifd.dont_disturb) {
			try {
				yield scontext.play_full(
					null,
					GSound.Attribute.EVENT_ID,
					"message"
				);
			} catch (Error e) {
				warning("Failed to play sound: %s", e.message);
			}
		}
	}

	private void remove_notification(uint notification_id) {
		NotificationItem? notif_popup = (NotificationItem)notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_list_box.remove(notif_popup);
				_notif_count--;
				break;
			}
			notif_popup = (NotificationItem)notif_popup.get_next_sibling();
		}
		if (_notif_count == 0) {
			this.visible = false;
		}
	}
}
