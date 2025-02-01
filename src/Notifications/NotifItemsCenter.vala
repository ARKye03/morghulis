using Astal;
public class NotifItemsCenter : Astal.Window {
	private AstalNotifd.Notifd notifd { get; set; }
	private Gtk.ListBox notif_list_box { get; set; }
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

		this.default_width = 330;
	}
}
