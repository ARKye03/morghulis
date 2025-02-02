using Astal;
public class NotifPopItemsCenter : Astal.Window {
	private AstalNotifd.Notifd notifd { get; set; }
	private Gtk.ListBox notif_list_box { get; set; }
	private Gtk.MediaFile notif_sound { get; set; }
	private uint _notif_count = 0;
	public static NotifPopItemsCenter instance { get;  private set; }

	public NotifPopItemsCenter(WindowAnchor x_anchor = WindowAnchor.RIGHT) {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}
		Object(
			title: "Notifications",
			anchor: WindowAnchor.TOP | x_anchor
		);
		notifd = AstalNotifd.Notifd.get_default();

		setup_window();
		setup_notifications();
	}

	private void setup_window() {
		default_width = 330;
		default_height = 1;
		set_css_classes({ "all_unset" });

		notif_list_box = new Gtk.ListBox();
		notif_list_box.set_selection_mode(Gtk.SelectionMode.NONE);
		set_child(notif_list_box);

		notif_sound = Gtk.MediaFile.for_resource("/com/github/ARKye03/morghulis/assets/colloid-notif-sound.opus");
	}

	private void setup_notifications() {
		notifd = AstalNotifd.Notifd.get_default();
		notifd.notified.connect((id, replace) => this.handle_notification(id, replace));
		notifd.resolved.connect((id) => this.remove_notification(id));
	}

	private void handle_notification(uint notification_id, bool replace) {
		if (!this.visible) {
			this.visible = true;
		}
		this.on_notification_added(notification_id, replace);
		this.play_notification_sound();
	}

	private void play_notification_sound() {
		if (!notifd.dont_disturb) {
			this.notif_sound.seek(0);
			this.notif_sound.play();
		}
	}

	private void on_notification_added(uint notification_id, bool is_replaced) {
		if (is_replaced) {
			remove_notification(notification_id);
		}

		var notification = notifd.get_notification(notification_id);
		var notif_item = new NotifPopItem(notification);
		notif_list_box.prepend(notif_item);
		_notif_count++;
	}

	private void remove_notification(uint notification_id) {
		NotifPopItem? notif_popup = (NotifPopItem)notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_list_box.remove(notif_popup);
				_notif_count--;
				break;
			}
			notif_popup = (NotifPopItem)notif_popup.get_next_sibling();
		}
		if (_notif_count == 0) {
			this.visible = false;
		}
	}
}
