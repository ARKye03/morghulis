[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu.ui")]
public class QuickMenu : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }
	public static QuickMenu instance { get; private set; }

	public QuickMenu() {
		Object(
			namespace : "QuickMenu",
			anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
		);
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		this.notify["visible"].connect(() => {
			if (!this.visible) {
				Settings.settings_navigation.pop();
				PowerBox.mstack.set_visible_child_name("main");
			}
		});
	}
}
