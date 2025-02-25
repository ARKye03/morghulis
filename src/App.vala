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

			case "change_brightness":
				OnScreenDisplay.instance.change_brightness();
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

		if (file.query_exists()) {
			apply_css(file.get_path(), true);
		}

		add_window(new NavBar());
		add_window(new Runner());
		add_window(new QuickMenu());
		add_window(new OnScreenDisplay());
		add_window(new NotifPopItemsCenter());

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

	private Gdk.RGBA lighten_color(Gdk.RGBA color, float factor = 0.1f) {
		color.red = float.min(1.0f, float.max(0.0f, color.red + (1.0f - color.red) * factor));
		color.green = float.min(1.0f, float.max(0.0f, color.green + (1.0f - color.green) * factor));
		color.blue = float.min(1.0f, float.max(0.0f, color.blue + (1.0f - color.blue) * factor));
		return color;
	}

	// Function made to HAVE ONLY ONE: `Gtk.StyleContext' has been deprecated since 4.10
	private void add_css_provider(Gtk.CssProvider provider) {
		Gtk.StyleContext.add_provider_for_display(
			Gdk.Display.get_default(),
			provider,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);
	}

	private void load_css() {
		var accent_rgba = lighten_color(style_manager.get_accent_color().to_rgba());
		var accent_provider = new Gtk.CssProvider();
		var rgb = @"rgb($((int)(accent_rgba.red * 255)), $((int)(accent_rgba.green * 255)), $((int)(accent_rgba.blue * 255)))";
		accent_provider.load_from_string(@"@define-color accent_hover_color $(rgb);");
		add_css_provider(accent_provider);

		// Load main stylesheet
		var provider = new Gtk.CssProvider();
		provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
		add_css_provider(provider);
	}
}
