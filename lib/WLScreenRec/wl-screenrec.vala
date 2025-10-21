public class ScreenRecorder : Object {
	private static ScreenRecorder instance;
	public static ScreenRecorder get_default() {
		if (instance == null) {
			instance = new ScreenRecorder();
		}
		return instance;
	}

	private Xdp.Portal portal;
	private Subprocess recorder;
	private int64 recording_start_time;

	public bool is_recording { get; private set; }

	construct {
		this.portal = new Xdp.Portal();
		this.is_recording = false;
		this.recording_start_time = 0;
	}

	public double get_recording_duration() {
		if (!this.is_recording || this.recording_start_time == 0) {
			return 0.0;
		}
		int64 current_time = GLib.get_monotonic_time();
		return (current_time - this.recording_start_time) / 1000000.0;
	}

	public async string? take_screenshot(bool is_region, string? filepath) {
		string path = filepath;
		if (path == null || path == "") {
			string picture_dir = Environment.get_user_special_dir(UserDirectory.PICTURES);
			string file_name = new DateTime.now_local().format_iso8601();
			path = "%s/Screenshots/%s.png".printf(picture_dir, file_name);
		}
		File destination = GLib.File.new_for_path(path);
		try {
			File parent = destination.get_parent();
			if (parent != null && !parent.query_exists()) {
				parent.make_directory_with_parents();
			}
			string uri = is_region
						 ? yield portal.take_screenshot(null, Xdp.ScreenshotFlags.INTERACTIVE, null)
						 : yield portal.take_screenshot(null, Xdp.ScreenshotFlags.NONE, null);

			File source = GLib.File.new_for_uri(uri);
			source.copy(destination, FileCopyFlags.NONE, null, null);
			return destination.get_path();
		} catch (Error e) {
			critical(e.message);
			return null;
		}
	}

	public void start_record(bool is_region, string? file_path) {
		if (this.is_recording) {
			return;
		}
		string path = file_path;
		if (path == null || path == "") {
			string video_dir = Environment.get_user_special_dir(UserDirectory.VIDEOS);
			string file_name = new DateTime.now_local().format_iso8601();
			path = "%s/Screencasting/%s.mp4".printf(video_dir, file_name);
		}

		try {
			File destination = GLib.File.new_for_path(path);
			File parent = destination.get_parent();
			if (parent != null && !parent.query_exists()) {
				parent.make_directory_with_parents();
			}

			string[] args;
			if (is_region) {
				string geometry;
				int exit_status;
				Process.spawn_command_line_sync("slurp", out geometry, null, out exit_status);
				geometry = geometry.strip();
				if (geometry == "" || exit_status != 0) {
					return;
				}
				args = { "wl-screenrec", "--audio", "--geometry", geometry, "--filename", path };
			} else {
				args = { "wl-screenrec", "--audio", "--filename", path };
			}

			this.recorder = new Subprocess.newv(args, SubprocessFlags.NONE);
			this.recording_start_time = GLib.get_monotonic_time();
			this.is_recording = true;
		} catch (Error e) {
			critical("%s\n", e.message);
		}
	}

	public void stop_record() {
		if (!this.is_recording) {
			return;
		}
		this.recorder.send_signal(15);
		this.recorder = null;
		this.recording_start_time = 0;
		this.is_recording = false;
	}
}
