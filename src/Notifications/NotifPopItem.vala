[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotifPopItem.ui")]
public class NotifPopItem : Gtk.ListBoxRow {
	public AstalNotifd.Notification notification { get; set; }

	[GtkChild]
	public unowned Gtk.Box actions_box;

	public NotifPopItem(AstalNotifd.Notification notification) {
		Object(
			notification: notification
		);
		setup_actions();
		setup_urgency();
		setup_auto_remove();
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

	private void setup_urgency() {
		if (notification.urgency == AstalNotifd.Urgency.CRITICAL) {
			this.add_css_class("critical");
		} else if (notification.urgency == AstalNotifd.Urgency.LOW) {
			this.add_css_class("low");
		} else {
			this.add_css_class("normal");
		}
	}

	private void setup_auto_remove() {
		// Get timeout value, default to 3 seconds if not set
		uint timeout = notification.expire_timeout > 0
					   ? notification.expire_timeout * 1000
					   : 3000;

		Timeout.add(timeout, () => {
			((Gtk.ListBox)this.get_parent()).remove(this);
			return false;
		});
	}

	private void setup_actions() {
		notification.actions.@foreach(a => {
			Gtk.Button action = new Gtk.Button();
			action.label = a.label;
			action.clicked.connect(() => this.notification.invoke(a.id));
			action.hexpand = true;
			this.actions_box.append(action);
		});
	}
}
