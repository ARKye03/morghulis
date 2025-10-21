[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/ScreenRecord.ui")]
public class ScreenRecord : MorghulWindow {
	private AstalNotifd.Notifd _notifd;
	private const string APP_ICON_NAME = "dialog-information-symbolic";

	public ScreenRecorder screen_rec { get; private set; }

	construct {
		this.screen_rec = ScreenRecorder.get_default();
		this._notifd = AstalNotifd.Notifd.get_default();
		var monitor_geometry = Morghulis.primary_monitor.get_geometry();

		this.default_width = monitor_geometry.width;
		this.default_height = monitor_geometry.height;
	}

	[GtkCallback]
	private async void on_screenshot_interactive() {
		this.visible = false;
		screen_rec.take_screenshot.begin(true, null, (obj, res) => {
			string? path = screen_rec.take_screenshot.end(res);
			if (path != null) {
				debug("Screenshot saved to: %s", path);
				AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
					app_name = "Morghulis ScreenRecord",
					body = "Screenshot saved to: %s".printf(path),
					app_icon = APP_ICON_NAME,
				});
			}
		});
	}

	[GtkCallback]
	private async void on_screenshot_full() {
		this.visible = false;
		screen_rec.take_screenshot.begin(false, null, (obj, res) => {
			string? path = screen_rec.take_screenshot.end(res);
			if (path != null) {
				debug("Screenshot saved to: %s", path);
				AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
					app_name = "Morghulis ScreenRecord",
					body = "Screenshot saved to: %s".printf(path),
					app_icon = APP_ICON_NAME,
				});
			}
		});
	}

	[GtkCallback]
	private async void on_toggle_record() {
		if (_screen_rec.is_recording) {
			screen_rec.stop_record();
			AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
				app_name = "Morghulis ScreenRecord",
				body = "Screen recording stopped.",
				app_icon = APP_ICON_NAME,
			});
		} else {
			this.visible = false;
			screen_rec.start_record(false, null);
		}
	}

	[GtkCallback]
	private string get_status_label(bool is_recording) {
		if (is_recording) {
			return "Recording...";
		} else {
			return "Not Recording";
		}
	}

	[GtkCallback]
	private string get_status_icon(bool is_recording) {
		if (is_recording) {
			return "media-playback-stop-symbolic";
		} else {
			return "media-record-symbolic";
		}
	}

	[GtkCallback]
	public void key_released(uint keyval, uint _, Gdk.ModifierType __) {
		if (keyval == Gdk.Key.Escape) {
			this.visible = false;
		}
	}
}
