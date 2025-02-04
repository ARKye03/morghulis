[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/PowerBox.ui")]
public class PowerBox : Gtk.Box {
	private string? pending_action { get; set; default = null; }

	public string user_name { get; private set; }
	public string user_image { get; private set; }
	public Gdk.Paintable user_image_paintable { get; private set; }
	public static Gtk.Stack mstack { get; private set; }

	[GtkChild]
	private unowned Gtk.Stack main_stack;

	construct {
		user_name = @"Hello there $(Environment.get_user_name())!";
		user_image = Environment.get_home_dir() + "/user.png";
		try {
			var pixbuf = new Gdk.Pixbuf.from_file(user_image);
			if (pixbuf != null) {
				user_image_paintable = Gdk.Texture.for_pixbuf(pixbuf);
			}
		} catch (Error e) {
			stderr.printf("Error loading image: %s\n", e.message);
		}
		mstack = main_stack;
	}

	/// I honestly think this can be done better

	[GtkCallback]
	private void show_shutdown_confirm() {
		pending_action = "shutdown";
		main_stack.visible_child_name = "confirm";
	}

	[GtkCallback]
	private void show_reboot_confirm() {
		pending_action = "reboot";
		main_stack.visible_child_name = "confirm";
	}

	[GtkCallback]
	private void cancel_action() {
		pending_action = null;
		main_stack.visible_child_name = "main";
	}

	[GtkCallback]
	private void confirm_action() {
		switch (pending_action) {
			case "shutdown":
				shutdown();
			break;

			case "reboot":
				reboot();
			break;
		}
		pending_action = null;
		main_stack.visible_child_name = "main";
	}

	public void shutdown() {
		try {
			Process.spawn_command_line_async("systemctl poweroff");
		} catch (SpawnError e) {
			warning("Failed to shutdown: %s", e.message);
		}
	}

	public void reboot() {
		try {
			Process.spawn_command_line_async("systemctl reboot");
		} catch (SpawnError e) {
			warning("Failed to reboot: %s", e.message);
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
