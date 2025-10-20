[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/ScreenRecord.ui")]
public class ScreenRecord : MorghulWindow {
	private ScreenRecorder _screen_rec;
	private AstalNotifd.Notifd _notifd;

	[GtkChild]
	private unowned Gtk.Button record_btn;

	construct {
		this._screen_rec = ScreenRecorder.get_default();
		this._notifd = AstalNotifd.Notifd.get_default();
		var monitor_geometry = Morghulis.primary_monitor.get_geometry();

		this.default_width = monitor_geometry.width;
		this.default_height = monitor_geometry.height;

		_screen_rec.notify["recording"].connect(() => {
			update_record_button();
		});

		update_record_button();
	}

	public ScreenRecord() {
		present();
	}

	[GtkCallback]
	private async void on_screenshot_interactive() {
		this.visible = false;
		_screen_rec.take_screenshot.begin(true, null, (obj, res) => {
			string? path = _screen_rec.take_screenshot.end(res);
			if (path != null) {
				debug("Screenshot saved to: %s", path);
				AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
					app_name = "Morghulis ScreenRecord",
					body = "Screenshot saved to: %s".printf(path),
					app_icon = "dialog-information-symbolic",
				});
			}
			this.visible = true;
		});
	}

	[GtkCallback]
	private void on_screenshot_full() {
		this.visible = false;
		_screen_rec.take_screenshot.begin(false, null, (obj, res) => {
			string? path = _screen_rec.take_screenshot.end(res);
			if (path != null) {
				debug("Screenshot saved to: %s", path);
				AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
					app_name = "Morghulis ScreenRecord",
					body = "Screenshot saved to: %s".printf(path),
					app_icon = "dialog-information-symbolic",
				});
			}
			this.visible = true;
		});
	}

	[GtkCallback]
	private void on_toggle_record() {
		if (_screen_rec.recording) {
			_screen_rec.stop_record();
			AstalNotifd.send_notification.begin(new AstalNotifd.Notification() {
				app_name = "Morghulis ScreenRecord",
				body = "Screen recording stopped.",
				app_icon = "dialog-information-symbolic",
			});
		} else {
			this.visible = false;
			_screen_rec.start_record(null);
			this.visible = true;
		}
	}

	[GtkCallback]
	private void on_close() {
		this.visible = false;
	}

	[GtkCallback]
	public void key_released(uint keyval, uint _, Gdk.ModifierType __) {
		if (keyval == Gdk.Key.Escape) {
			this.visible = false;
		}
	}

	private void update_record_button() {
		if (_screen_rec.recording) {
			record_btn.icon_name = "media-playback-stop-symbolic";
		} else {
			record_btn.icon_name = "media-record-symbolic";
		}
	}
}
