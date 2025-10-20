[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/ScreenRecord.ui")]
public class ScreenRecord : MorghulWindow {
	private ScreenRecorder _screen_rec;

	construct {
		this._screen_rec = ScreenRecorder.get_default();
		var monitor_geometry = Morghulis.primary_monitor.get_geometry();

		this.default_width = monitor_geometry.width;
		this.default_height = monitor_geometry.height;
	}

	public ScreenRecord() {
		present();
	}
}
