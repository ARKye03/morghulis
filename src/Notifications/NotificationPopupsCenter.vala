public class NotifPopItemsCenter : Astal.Window {
	private AstalNotifd.Notifd _notifd;
	private Gtk.ListBox _notif_list_box;
	private GSound.Context _scontext;
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
		this.default_width = 330;
		this.default_height = 0;
		this.margin = 5;
		this.css_classes = { "all_unset", "rounded" };
		this.overflow = Gtk.Overflow.HIDDEN;
		this.notify["visible"].connect(() => {
			if (visible) {
				this.default_height = -1;
			} else {
				this.default_height = 0;
			}
		});

		this._notif_list_box = new Gtk.ListBox() {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = { "boxed-list" }
		};

		this.child = _notif_list_box;
	}

	private void setup_notifications() {
		this._notifd = AstalNotifd.Notifd.get_default();
		this._notifd.notified.connect((id, replace) => this.handle_notification(id, replace));
		this._notifd.resolved.connect((id) => this.remove_notification(id));
	}

	private void handle_notification(uint notification_id, bool replace) {
		if (replace) {
			remove_notification(notification_id);
		}

		var notification = _notifd.get_notification(notification_id);
		var notif_item = new NotificationItem(notification);
		this._notif_list_box.prepend(notif_item);
		this._notif_count++;

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
			this._scontext = new GSound.Context();
			this._scontext.init();
		} catch (Error e) {
			warning("Failed to create sound context: %s", e.message);
		}
	}

	private async void play_notification_sound() {
		if (!this._notifd.dont_disturb) {
			try {
				yield this._scontext.play_full(
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
		NotificationItem? notif_popup = (NotificationItem)_notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				this._notif_list_box.remove(notif_popup);
				this._notif_count--;
				break;
			}
			notif_popup = (NotificationItem)notif_popup.get_next_sibling();
		}
		if (this._notif_count == 0) {
			this.visible = false;
		}
	}
}
