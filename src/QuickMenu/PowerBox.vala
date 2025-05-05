private enum PowerOption {
	NONE,
	SHUTDOWN,
	REBOOT,
	LOGOUT
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/PowerBox.ui")]
public class PowerBox : Gtk.Box {
	private PowerOption _option;

	public string uptime { get; set; }
	public string user_name { get; private set; }
	public Gdk.Paintable user_image_paintable { get; private set; }
	public static Gtk.Stack mstack { get; private set; }

	[GtkChild]
	private unowned Gtk.Stack main_stack;

	construct {
		_option = PowerOption.NONE;
		user_name = Morghulis.user_name;
		var user_image_path = Environment.get_home_dir() + "/user.png";
		try {
			var pixbuf = new Gdk.Pixbuf.from_file(user_image_path);
			if (pixbuf != null) {
				user_image_paintable = Gdk.Texture.for_pixbuf(pixbuf);
			}
		} catch (Error e) {
			critical("Error loading paintable: %s\n", e.message);
		}
		mstack = main_stack;

		Morghulis.instance.bind_property("uptime", this, "uptime", BindingFlags.SYNC_CREATE);
	}

	/// I honestly think this can be done better

	[GtkCallback]
	private void show_shutdown_confirm() {
		_option = PowerOption.SHUTDOWN;
		main_stack.visible_child_name = "confirm";
	}

	[GtkCallback]
	private void show_logout_confirm() {
		_option = PowerOption.LOGOUT;
		main_stack.visible_child_name = "confirm";
	}

	[GtkCallback]
	private void show_reboot_confirm() {
		_option = PowerOption.REBOOT;
		main_stack.visible_child_name = "confirm";
	}

	[GtkCallback]
	private void cancel_action() {
		_option = PowerOption.NONE;
		main_stack.visible_child_name = "main";
	}

	[GtkCallback]
	private void confirm_action() {
		switch (_option) {
			case PowerOption.SHUTDOWN:
				shutdown();
			break;

			case PowerOption.REBOOT:
				reboot();
			break;

			case PowerOption.LOGOUT:
				logout();
			break;

			default:
				message("Unreachable code reached");
			break;
		}
		_option = PowerOption.NONE;
		main_stack.visible_child_name = "main";
	}

	private void shutdown() {
		try {
			Process.spawn_command_line_async("systemctl poweroff");
		} catch (SpawnError e) {
			warning("Failed to shutdown: %s", e.message);
		}
	}

	private void reboot() {
		try {
			Process.spawn_command_line_async("systemctl reboot");
		} catch (SpawnError e) {
			warning("Failed to reboot: %s", e.message);
		}
	}

	public void logout() {
		try {
			Process.spawn_command_line_async(@"loginctl terminate-user $user_name");
		} catch (SpawnError e) {
			warning("Failed to logout: %s", e.message);
		}
	}

	[GtkCallback]
	public void suspend() {
		try {
			Process.spawn_command_line_async("systemctl suspend");
		} catch (SpawnError e) {
			warning("Failed to suspend: %s", e.message);
		}
	}

	[GtkCallback]
	public void hibernate() {
		try {
			Process.spawn_command_line_async("systemctl hibernate");
		} catch (SpawnError e) {
			warning("Failed to hibernate: %s", e.message);
		}
	}

	[GtkCallback]
	public void lock() {
		try {
			Process.spawn_command_line_async("loginctl lock-session");
		} catch (SpawnError e) {
			warning("Failed to lock: %s", e.message);
		}
	}
}
