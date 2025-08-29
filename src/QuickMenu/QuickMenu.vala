[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QuickMenu.ui")]
public class QuickMenu : MorghulWindow {
	public AstalWp.Endpoint speaker { get; set; }
	public static QuickMenu instance { get; private set; }

	construct {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		if (NavBar.instance.vanchor == WindowAnchor.TOP) {
			this.anchor = WindowAnchor.RIGHT | WindowAnchor.TOP;
		} else {
			this.anchor = WindowAnchor.RIGHT | WindowAnchor.BOTTOM;
		}

		this.notify["visible"].connect(() => {
			if (!this.visible) {
				Settings.settings_navigation.pop();
				PowerBox.mstack.set_visible_child_name("main");
				BatteryBox.bb_stack_ref?.set_visible_child_name("sliders");
			}
		});
	}
}
