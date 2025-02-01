using Astal;
public class NotifItemsCenter : Astal.Window {
	private AstalNotifd.Notifd notifd { get; set; }
	private Gtk.ListBox notif_list_box { get; set; }
	private Gtk.MediaFile notif_sound { get; set; }
	private uint _notif_count = 0;
	public static NotifItemsCenter instance { get;  private set; }

	public NotifItemsCenter(WindowAnchor x_anchor = WindowAnchor.RIGHT) {
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
		notif_list_box = new Gtk.ListBox();
		notif_sound = Gtk.MediaFile.for_resource("/com/github/ARKye03/morghulis/assets/colloid-notif-sound.opus");
		this.default_width = 330;
		this.set_css_classes({ "all_unset" });
		notif_list_box.add_css_class("boxed-list-separate");
		notif_list_box.set_selection_mode(Gtk.SelectionMode.NONE);

		this.notifd.notified.connect((id, replace) => {
			this.visible = true;
			this.on_notification_added(id, replace, this.notif_list_box);
			this.play_sound();
		});
		this.notifd.resolved.connect((id) => this.remove_notification(id, this.notif_list_box));

		this.set_child(notif_list_box);
	}

	private void play_sound() {
		if (!notifd.dont_disturb) {
			this.notif_sound.seek(0);
			this.notif_sound.play();
		}
	}

	private uint hide_timeout_id = 0;
	private void handle_timeout() {
		// Remove the existing timeout if it exists
		if (hide_timeout_id != 0) {
			GLib.Source.remove(hide_timeout_id);
			hide_timeout_id = 0;
		}

		// Set a new timeout
		hide_timeout_id = GLib.Timeout.add(3000, () => {
			this.visible = false;
			hide_timeout_id = 0;
			return false;
		});
	}

	private void on_notification_added(uint notification_id, bool is_replaced, Gtk.ListBox notif_list_box) {
		if (is_replaced) {
			remove_notification(notification_id, notif_list_box);
		}

		var notification = notifd.get_notification(notification_id);
		notif_list_box.prepend(new NotifItem(notification));
		_notif_count++;
	}

	private void remove_notification(uint notification_id, Gtk.ListBox notif_list_box) {
		NotifItem? notif_popup = (NotifItem)notif_list_box.get_first_child();

		while (notif_popup != null) {
			if (notif_popup.notification.id == notification_id) {
				notif_list_box.remove(notif_popup);
				_notif_count--;
				break;
			}
			notif_popup = (NotifItem)notif_popup.get_next_sibling();
		}
		if (_notif_count == 0) {
			this.visible = false;
		}
	}
}
