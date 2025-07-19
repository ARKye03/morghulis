[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/SysInfo/SysInfoData.ui")]
public class SysInfoData : Gtk.Box {
	public string hostname { get; set; }
	public string kernel { get; set; }
	public string distro { get; set; }
	public string desktop { get; set; }
	public string display { get; set; }

	construct {
		gather_system_info();
	}

	private void gather_system_info() {
		try {
			string contents;
			FileUtils.get_contents("/etc/hostname", out contents);
			hostname = contents.strip();
		} catch (Error e) {
			hostname = Environment.get_host_name();
		}

		// Get distro info
		try {
			string contents;
			if (FileUtils.get_contents("/etc/os-release", out contents)) {
				string[] lines = contents.split("\n");
				foreach (string line in lines) {
					if (line.has_prefix("PRETTY_NAME=")) {
						distro = line.substring(12).replace("\"", "");
						break;
					}
				}
			}
		} catch (Error e) {
			distro = "Unknown Linux";
		}

		// Get kernel info
		try {
			string output;
			Process.spawn_command_line_sync("uname -r", out output);
			kernel = output.strip();
		} catch (Error e) {
			kernel = "Unknown";
		}

		// Detect display server and desktop environment
		detect_display_environment();
	}

	private void detect_display_environment() {
		string display_server = "Unknown";
		string desktop_env = "";

		// Check for Wayland
		if (Environment.get_variable("WAYLAND_DISPLAY") != null) {
			display_server = "Wayland";

			// Try to detect Wayland compositor
			string? compositor = Environment.get_variable("XDG_CURRENT_DESKTOP");
			if (compositor == null) {
				compositor = Environment.get_variable("DESKTOP_SESSION");
			}

			if (compositor != null) {
				desktop_env = compositor;
			} else {
				// Try to detect specific compositors
				if (Environment.get_variable("HYPRLAND_INSTANCE_SIGNATURE") != null) {
					desktop_env = "Hyprland";
				} else if (Environment.get_variable("SWAYSOCK") != null) {
					desktop_env = "Sway";
				}
			}
		}
		// Check for X11
		else if (Environment.get_variable("DISPLAY") != null) {
			display_server = "X11";

			string? desktop = Environment.get_variable("XDG_CURRENT_DESKTOP");
			if (desktop == null) {
				desktop = Environment.get_variable("DESKTOP_SESSION");
			}

			if (desktop != null) {
				desktop_env = desktop;
			}
		}

		display = display_server;
		if (desktop_env != "") {
			desktop = desktop_env;
		}
	}
}
