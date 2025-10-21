[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/ScreenRecord.ui")]
public class ScreenRecord : MorghulWindow {
	private AstalNotifd.Notifd _notifd;
	private uint _timer_id = 0;
	private const string APP_ICON_NAME = "dialog-information-symbolic";

	public ScreenRecorder screen_rec { get; private set; }

	[GtkChild]
	private unowned Gtk.Label status_label;

	[GtkChild]
	private unowned Gtk.Image status_icon;

	construct {
		this.screen_rec = ScreenRecorder.get_default();
		this._notifd = AstalNotifd.Notifd.get_default();
		var monitor_geometry = Morghulis.primary_monitor.get_geometry();

		this.default_width = monitor_geometry.width;
		this.default_height = monitor_geometry.height;

		screen_rec.notify["is-recording"].connect(() => {
			if (screen_rec.is_recording) {
				start_timer();
				status_icon.add_css_class("is_recording");
			} else {
				status_icon.remove_css_class("is_recording");
				stop_timer();
			}
		});
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

	private void start_timer() {
		if (_timer_id != 0) {
			Source.remove(_timer_id);
		}
		_timer_id = Timeout.add(100, () => {
			update_status_label();
			return true;
		});
		update_status_label();
	}

	private void stop_timer() {
		if (_timer_id != 0) {
			Source.remove(_timer_id);
			_timer_id = 0;
		}
		status_label.label = "00:00";
	}

	private void update_status_label() {
		double duration = screen_rec.get_recording_duration();
		int total_seconds = (int)duration;
		int hours = total_seconds / 3600;
		int minutes = (total_seconds % 3600) / 60;
		int seconds = total_seconds % 60;

		if (hours > 0) {
			status_label.label = "%02d:%02d:%02d".printf(hours, minutes, seconds);
		} else {
			status_label.label = "%02d:%02d".printf(minutes, seconds);
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
