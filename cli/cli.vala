using GLib;

public class MorghulCTL {
	private static string version = "1.0-alpha";

	public static int main(string[] args) {
		var options = new OptionEntry[] {
			{ "start", 0, OptionFlags.NONE, OptionArg.NONE, out start, "Start the application", null },
			{ "toggle-window", 't', OptionFlags.NONE, OptionArg.STRING, out toggle_window, "Toggle window(s)", "WINDOW" },
			{ "show-inspector", 'i', OptionFlags.NONE, OptionArg.NONE, out show_inspector, "Show inspector", null },
			{ "quit", 'q', OptionFlags.NONE, OptionArg.NONE, out quit, "Quit the application", null },
			{ "version", 'v', OptionFlags.NONE, OptionArg.NONE, out show_version, "Show version", null },
			{ null }
		};

		var context = new OptionContext(null);

		context.add_main_entries(options, null);

		try {
			context.parse(ref args);
		} catch (OptionError e) {
			stderr.printf("Option parsing failed: %s\n", e.message);
			return 1;
		}

		if (show_version) {
			stdout.printf("Morghulis version %s\n", version);
			return 0;
		}

		if (start) {
			return start_morghulis();
		}

		if (toggle_window != null) {
			return toggle_window_func(toggle_window);
		}

		if (show_inspector) {
			return toggle_inspector();
		}

		if (quit) {
			return exit_morghulis();
		}
		stderr.printf("No valid options provided. Use --help for usage information.\n");
		return 1;
	}

	private static int exit_morghulis() {
		try {
			GLib.Process.spawn_command_line_async("astal -i morghulis -q");
		} catch (GLib.Error e) {
			stderr.printf("Failed to quit the application: %s\n", e.message);
			return 1;
		}
		return 0;
	}

	private static int toggle_inspector() {
		try {
			GLib.Process.spawn_command_line_async("astal -i morghulis -I");
		} catch (GLib.Error e) {
			stderr.printf("Failed to show inspector: %s\n", e.message);
			return 1;
		}
		return 0;
	}

	private static int toggle_window_func(string window) {
		try {
			GLib.Process.spawn_command_line_async(@"astal -i morghulis -t $window");
		} catch (GLib.Error e) {
			stderr.printf("Failed to toggle window: %s\n", e.message);
			return 1;
		}
		return 0;
	}

	private static int start_morghulis() {
		if (is_process_running("morghulis")) {
			stdout.printf("Process already running\n");
			return 0;
		}

		try {
			GLib.Pid child_pid;
			Process.spawn_async(
				null,
				new string[] { "/usr/bin/morghulis" },
				null,
				SpawnFlags.DO_NOT_REAP_CHILD,
				null,
				out child_pid
				);
			stdout.printf("Starting the application…\n");
		} catch (SpawnError e) {
			stderr.printf("Failed to start the application: %s\n", e.message);
			return 1;
		}
		return 0;
	}

	private static bool is_process_running(string process_name) {
		try {
			string output;
			string error;
			int exit_status;
			Process.spawn_command_line_sync("pgrep " + process_name, out output, out error, out exit_status);
			return !(output == null || output == "");
		} catch (SpawnError e) {
			stderr.printf("Failed to check if process is running: %s\n", e.message);
			return false;
		}
	}

	private static bool start = false;
	private static string ?toggle_window = null;
	private static bool show_inspector = false;
	private static bool quit = false;
	private static bool show_version = false;
}
