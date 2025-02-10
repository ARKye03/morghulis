[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu.ui")]
public class QuickMenu : Gtk.Popover {
	public AstalWp.Endpoint speaker { get; set; }
	public static QuickMenu instance { get; private set; }

	public QuickMenu() {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		this.notify["visible"].connect(() => {
			message("Closed");
			Settings.settings_navigation.pop();
			PowerBox.mstack.set_visible_child_name("main");
		});
	}
}
