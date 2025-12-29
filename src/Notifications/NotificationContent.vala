[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotificationContent.ui")]
public class NotificationContent : Gtk.Box {
    public AstalNotifd.Notification notification { get; set; }

    [GtkChild]
    public unowned Gtk.Box actions_box;

    [GtkChild]
    public unowned Gtk.Label label_body;

    public NotificationContent(AstalNotifd.Notification notification) {
        Object(
            notification: notification
        );
        setup_actions();
        setup_urgency();
        setup_body();
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

    private void setup_body() {
        if (notification == null) {
            return;
        }

        string body_text = notification.body ?? "";
        if (body_text == "") {
            label_body.hide();
            return;
        }
        label_body.show();

        string pango = CMark.parse_to_pango(body_text);
        label_body.set_markup(pango);
    }
}
