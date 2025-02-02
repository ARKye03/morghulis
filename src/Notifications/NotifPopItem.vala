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

	private void setup_actions() {
		notification.actions.@foreach(a => {
			Gtk.Button action = new Gtk.Button.with_label(a.label);
			action.clicked.connect(() => this.notification.invoke(a.id));
			this.actions_box.append(action);
		});
	}
}
