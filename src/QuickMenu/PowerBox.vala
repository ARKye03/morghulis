[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/PowerBox.ui")]
public class PowerBox : Gtk.Box {
	public string user_name { get; set; }
	public string user_image { get; set; }
	public Gdk.Paintable user_image_paintable { get; set; }

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
