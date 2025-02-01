using Gtk;
using AstalNotifd;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotifPop.ui")]
public class NotifPop : ListBoxRow {
	public AstalNotifd.Notification notification { get; set; }

	[GtkChild]
	public unowned Box actions_box;

	private void init_actions() {
		notification.actions.@foreach(a => {
			Gtk.Button action = new Gtk.Button();
			action.label = a.label;
			action.clicked.connect(() => this.notification.invoke(a.id));
			action.hexpand = true;
			this.actions_box.append(action);
		});
	}

	[GtkCallback]
	public string current_time(int64 t) {
		DateTime dt = new DateTime.from_unix_local(t);

		return dt.format(Morghulis.clock_format);
	}

	[GtkCallback]
	public void dismiss_notif() {
		this.notification.dismiss();
	}

	public NotifPop(AstalNotifd.Notification notification) {
		Object(notification: notification);
		this.init_actions();
		if (notification.urgency == AstalNotifd.Urgency.CRITICAL) {
			this.add_css_class("critical");
		} else if (notification.urgency == AstalNotifd.Urgency.LOW) {
			this.add_css_class("low");
		} else {
			this.add_css_class("normal");
		}
	}
}
