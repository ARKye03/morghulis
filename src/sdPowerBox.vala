[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/sdPowerBox.ui")]
public class sdPowerBox : Gtk.Box {
	construct {
		uptime();
	}
	[GtkChild]
	public unowned Gtk.Label uptime_label;

	private static string stdout;
	private void uptime() {
		update_uptime();
		GLib.Timeout.add(60000, () => {
			update_uptime();
			return true;
		});
	}

	private void update_uptime() {
		try {
			Process.spawn_command_line_sync("uptime -p", out stdout);
		} catch (Error e) {
			warning("Failed to get uptime: %s", e.message);
		}
		uptime_label.label = stdout.strip();
	}

	[GtkCallback]
	public void shutdown() {
		try {
			Process.spawn_command_line_async("systemctl poweroff");
		} catch (Error e) {
			warning("Failed to shutdown: %s", e.message);
		}
	}

	[GtkCallback]
	public void reboot() {
		try {
			Process.spawn_command_line_async("systemctl reboot");
		} catch (Error e) {
			warning("Failed to reboot: %s", e.message);
		}
	}

	[GtkCallback]
	public void suspend() {
		try {
			Process.spawn_command_line_async("systemctl suspend");
		} catch (Error e) {
			warning("Failed to suspend: %s", e.message);
		}
	}

	[GtkCallback]
	public void hibernate() {
		try {
			Process.spawn_command_line_async("systemctl hibernate");
		} catch (Error e) {
			warning("Failed to hibernate: %s", e.message);
		}
	}

	[GtkCallback]
	public void lock() {
		try {
			Process.spawn_command_line_async("loginctl lock-session");
		} catch (Error e) {
			warning("Failed to lock: %s", e.message);
		}
	}
}
