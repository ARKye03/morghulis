[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QuickMenu.ui")]
public class QuickMenu : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }
	public static QuickMenu instance { get; private set; }

	construct {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		if (NavBar.instance.vanchor == Astal.WindowAnchor.TOP) {
			this.anchor = Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.TOP;
		} else {
			this.anchor = Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM;
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
