using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu.ui")]
public class QuickMenu : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }

	public QuickMenu() {
		Object(
			anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
	}
}
