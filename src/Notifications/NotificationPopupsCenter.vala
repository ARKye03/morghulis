public class NotifPopItemsCenter : Astal.Window {
	private AstalNotifd.Notifd _notifd;
	private Gtk.ListBox _notif_list_box;
	private GSound.Context _scontext;
	private uint _notif_count = 0;

	public NotifPopItemsCenter(Astal.WindowAnchor x_anchor = Astal.WindowAnchor.RIGHT) {
		Object(
			title: "Notifications",
			anchor: Astal.WindowAnchor.TOP | x_anchor,
			default_width: 330,
			default_height: 0,
			margin: 5,
			css_classes: new string[] { "all_unset" },
			overflow: Gtk.Overflow.HIDDEN
		);

		setup_sound();
		setup_window();
		setup_notifications();
	}

	private void setup_window() {
		this.notify["visible"].connect(() => {
			if (visible) {
				this.default_height = -1;
			} else {
				this.default_height = 0;
			}
		});

		this._notif_list_box = new Gtk.ListBox() {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = { "boxed-list-separate" }
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

		if (_notifd.dont_disturb && notification.urgency != AstalNotifd.Urgency.CRITICAL) {
			return;
		}

		var notif_item = new PopupNotificationItem(notification);
		this._notif_list_box.prepend(notif_item);
		this._notif_count++;

		uint timeout_ms = notification.expire_timeout > 0 ? notification.expire_timeout * 1000 : 3000;
		Timeout.add(timeout_ms, () => {
			remove_notification(notification_id);
			return Source.REMOVE;
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
		PopupNotificationItem? notif_popup = (PopupNotificationItem)_notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_popup.dismiss_notif(false);
				Timeout.add(notif_popup.transition_duration + 50, () => {
					this._notif_list_box.remove(notif_popup);
					this._notif_count--;
					if (this._notif_count == 0) {
						this.visible = false;
					}
					return Source.REMOVE;
				});
				break;
			}
			notif_popup = (PopupNotificationItem)notif_popup.get_next_sibling();
		}
	}
}
