public class Morghulis : Astal.Application {
	private string socket_path { get; set; }
	private bool css_loaded { get; set; default = false; }
	private GLib.File file { get; set; }
	private GLib.FileMonitor file_monitor { get; set; }
	private Adw.StyleManager style_manager { get; set; }

	public static Morghulis instance { get; private set; }
	public static Gdk.Display? display { get; private set; }
	public static Gdk.Monitor? primary_monitor { get; private set; }
	public static string clock_format { get; set; default = "%H:%M %b %e"; }

	public override void request(string msg, SocketConnection conn) {
		switch (msg) {
			case "change_volume":
				OnScreenDisplay.instance.change_volume();
			break;

				default:
				AstalIO.write_sock.begin(conn, @"missing response implementation on $instance_name");
			break;
		}
	}

	construct {
		Adw.init();
		instance_name = "morghulis";
		style_manager = Adw.StyleManager.get_default();

		try {
			acquire_socket();
		} catch (Error e) {
			critical("%s", e.message);
		}
		instance = this;

		file = File.new_for_path(@"$(Environment.get_user_config_dir())/morghulis/main.css");
		if (file.query_exists()) {
			try {
				file_monitor = file.monitor_file(GLib.FileMonitorFlags.NONE);
				file_monitor.changed.connect((_) => {
					apply_css(file.get_path(), true);
					message("Reloaded CSS");
				});
			} catch (IOError e) {
				critical("Error: %s\n", e.message);
			}
		}
	}

	[DBus(visible = false)]
	public override void activate() {
		base.activate();
		setup_display_and_monitor();

		if (!css_loaded) {
			load_css();
			css_loaded = true;
		}

		add_window(new NavBar());
		add_window(new Runner());
		add_window(new QuickMenu());
		add_window(new OnScreenDisplay());
		add_window(new NotifPopItemsCenter());

		if (file.query_exists()) {
			apply_css(file.get_path(), true);
		}
		this.hold();
	}

	private void setup_display_and_monitor() {
		display = Gdk.Display.get_default();
		if (display == null) {
			critical("Failed to get default display");
			return;
		}
		var monitors = display.get_monitors();
		if (monitors == null) {
			critical("Failed to get monitors");
			return;
		}
		// Morghulis assume there is only one monitor
		primary_monitor = monitors.get_item(0) as Gdk.Monitor;
		if (primary_monitor == null) {
			critical("Failed to get primary monitor");
			return;
		}
		message("Successfully initialized primary monitor");
	}

	private void load_css() {
		var accent_color = style_manager.get_accent_color();
		var accent_rgba = accent_color.to_rgba();

		// Lighten each channel by 10%
		accent_rgba.red = float.min(1.0f, float.max(0.0f, accent_rgba.red + (1.0f - accent_rgba.red) * 0.1f));
		accent_rgba.green = float.min(1.0f, float.max(0.0f, accent_rgba.green + (1.0f - accent_rgba.green) * 0.1f));
		accent_rgba.blue = float.min(1.0f, float.max(0.0f, accent_rgba.blue + (1.0f - accent_rgba.blue) * 0.1f));

		// Convert to integer range 0–255
		int r_byte = (int)(accent_rgba.red * 255.0);
		int g_byte = (int)(accent_rgba.green * 255.0);
		int b_byte = (int)(accent_rgba.blue * 255.0);

		Gtk.CssProvider accent_provider = new Gtk.CssProvider();
		string accent_css = @"@define-color accent_hover_color rgb($(r_byte), $(g_byte), $(b_byte));";
		message(accent_css);
		accent_provider.load_from_string(accent_css);
		Gtk.StyleContext.add_provider_for_display(
			Gdk.Display.get_default(),
			accent_provider,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);

		Gtk.CssProvider provider = new Gtk.CssProvider();
		provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");

		Gtk.StyleContext.add_provider_for_display(
			Gdk.Display.get_default(),
			provider,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);
	}
}
