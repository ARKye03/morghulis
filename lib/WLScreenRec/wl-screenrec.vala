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

	public bool recording { get; private set; }

	construct {
		this.portal = new Xdp.Portal();
		this.recording = false;
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

	public void start_record(string? file_path) {
		if (this.recording) {
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

			string geometry;
			Process.spawn_command_line_sync("slurp", out geometry);
			geometry = geometry.strip();

			string[] args = { "wl-screenrec", "--geometry", geometry, "--filename", path };
			this.recorder = new Subprocess.newv(args, SubprocessFlags.NONE);
			this.recording = true;
		} catch (Error e) {
			critical("%s\n", e.message);
		}
	}

	public void stop_record() {
		if (!this.recording) {
			return;
		}
		this.recorder.send_signal(15);
		this.recorder = null;
		this.recording = false;
	}
}
