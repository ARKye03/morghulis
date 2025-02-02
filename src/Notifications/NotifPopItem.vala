[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotifPopItem.ui")]
public class NotifPopItem : Gtk.ListBoxRow {
	private Gtk.ListBox notif_list_box { get; set; }
	public AstalNotifd.Notification notification { get; set; }

	[GtkChild]
	public unowned Gtk.Box actions_box;

	[GtkChild]
	public unowned Gtk.ProgressBar progress;

	public NotifPopItem(AstalNotifd.Notification notification, Gtk.ListBox notif_list_box) {
		Object(
			notification: notification
		);
		this.notif_list_box = notif_list_box;
		this.init_actions();
		if (notification.urgency == AstalNotifd.Urgency.CRITICAL) {
			this.add_css_class("critical");
		} else if (notification.urgency == AstalNotifd.Urgency.LOW) {
			this.add_css_class("low");
		} else {
			this.add_css_class("normal");
		}
		init_countdown();
	}

	private void init_countdown() {
		// Get timeout value, default to 3 seconds if not set
		uint timeout = notification.expire_timeout > 0
					   ? notification.expire_timeout * 1000
					   : 3000;

		GLib.Timeout.add(timeout, () => {
			notif_list_box.remove(this);
			return false;
		});
	}

	[GtkCallback]
	public string current_time(int64 t) {
		DateTime dt = new DateTime.from_unix_local(t);

		return dt.format("%H:%M");
	}

	[GtkCallback]
	public void dismiss_notif() {
		this.notification.dismiss();
	}

	private void init_actions() {
		notification.actions.@foreach(a => {
			Gtk.Button action = new Gtk.Button();
			action.label = a.label;
			action.clicked.connect(() => this.notification.invoke(a.id));
			action.hexpand = true;
			this.actions_box.append(action);
		});
	}
}
