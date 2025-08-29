public class MorghulisApplication : Gtk.Application {
	private bool _css_loaded;
	private File _css_file;
	private FileMonitor _css_file_monitor;
	private GTop.Uptime _g_uptime;
	private List<Astal.Window> _windows;

	public static MorghulisApplication instance { get; private set; }
	public static GLib.Settings gsettings { get; private set; }
	public static Gdk.Display? display { get; private set; }
	public static Gdk.Monitor? primary_monitor { get; private set; }
	public static string clock_format { get; private set; default = "%H:%M %b %d"; }
	public static string user_name { get; private set; }

	public string uptime { get; private set; }

	public MorghulisApplication() {
		Object(
			application_id: "com.arkye.morghulis",
			flags: ApplicationFlags.HANDLES_COMMAND_LINE
		);

		instance = this;
		_windows = new List<Astal.Window>();

		Adw.init();
		gsettings = new GLib.Settings("com.arkye.morghulis");
		user_name = Environment.get_user_name();

		setup_css_monitoring();
	}

	public override int command_line(ApplicationCommandLine command_line) {
		var args = command_line.get_arguments();

		// Option variables
		bool show_help = false;
		bool show_version = false;
		bool quit_app = false;
		bool inspector = false;
		string? toggle_window_name = null;
		string? request_type = null;

		// Define command line options
		var options = new OptionEntry[] {
			{ "help", 'h', OptionFlags.NONE, OptionArg.NONE, out show_help, "Show this help message", null },
			{ "version", 'v', OptionFlags.NONE, OptionArg.NONE, out show_version, "Show version information", null },
			{ "quit", 'q', OptionFlags.NONE, OptionArg.NONE, out quit_app, "Quit the application", null },
			{ "inspector", 'i', OptionFlags.NONE, OptionArg.NONE, out inspector, "Toggle GTK inspector", null },
			{ "toggle", 't', OptionFlags.NONE, OptionArg.STRING, out toggle_window_name, "Toggle window visibility", "WINDOW" },
			{ "request", 'r', OptionFlags.NONE, OptionArg.STRING, out request_type, "Send custom request", "REQUEST" },
			{ null }
		};

		var context = new OptionContext("- Morghulis Desktop Shell");
		context.set_summary("A GTK4 desktop shell built with Vala");
		context.set_description(
			"""Examples:
                    morghulis -t runner         # Toggle runner window
                    morghulis -r change_volume  # Trigger volume change OSD
            """);

		context.add_main_entries(options, null);

		try {
			unowned string[] args_unowned = args;
			context.parse(ref args_unowned);
		} catch (OptionError e) {
			command_line.printerr("Option parsing failed: %s\n", e.message);
			return 1;
		}

		// Handle the parsed options
		if (show_help) {
			command_line.print("%s", context.get_help(true, null));
			return 0;
		}

		if (show_version) {
			command_line.print("Morghulis version 0.1.0\n");
			return 0;
		}

		if (quit_app) {
			quit_application();
			return 0;
		}

		if (inspector) {
			toggle_inspector();
			return 0;
		}

		if (toggle_window_name != null) {
			toggle_window(toggle_window_name);
			return 0;
		}

		if (request_type != null) {
			handle_request(request_type);
			return 0;
		}

		// If no specific options were provided, activate normally
		activate();
		return 0;
	}

	private void handle_request(string request) {
		switch (request) {
			case "change_volume":
				if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_volume();
				}
			break;

			case "change_brightness":
				if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_brightness();
				}
			break;

			default:
				warning("Unknown request: %s", request);
			break;
		}
	}

	private void toggle_window(string window_name) {
		switch (window_name.down()) {
			case "navbar":
				if (NavBar.instance != null) {
					NavBar.instance.visible = !NavBar.instance.visible;
				}
			break;

			case "runner":
				if (Runner.instance != null) {
					Runner.instance.visible = !Runner.instance.visible;
				}
			break;

			case "quickmenu":
				if (QuickMenu.instance != null) {
					QuickMenu.instance.visible = !QuickMenu.instance.visible;
				}
			break;

			case "powermenu":
				//  if (PowerMenu.instance != null) {
				//  	PowerMenu.instance.visible = !PowerMenu.instance.visible;
				//  }
			break;

			default:
				warning("Unknown window: %s", window_name);
			break;
		}
	}

	private void toggle_inspector() {
		Gtk.Window.set_interactive_debugging(true);
	}

	private void quit_application() {
		// Clean up windows
		foreach (var window in _windows) {
			window.destroy();
		}
		quit();
	}

	public new void add_window(Gtk.Window window) {
		_windows.append((Astal.Window)window);
		add_window_to_app(window);
	}

	private void add_window_to_app(Gtk.Window window) {
		window.set_application(this);
	}

	protected override void activate() {
		if (_windows.length() > 0) {
			// Application is already running
			return;
		}

		setup_display_and_monitor();
		Gtk.IconTheme.get_for_display(display).add_resource_path("/com/github/ARKye03/morghulis/icons");

		if (!_css_loaded) {
			load_css();
			_css_loaded = true;
		}

		if (_css_file.query_exists()) {
			apply_css(_css_file.get_path(), true);
		}

		string navbar_position = gsettings.get_string("navbar-anchor");
		Astal.WindowAnchor navbar_anchor;

		switch (navbar_position.down()) {
			case "top":
				navbar_anchor = Astal.WindowAnchor.TOP;
			break;

			case "bottom":
			default:
				navbar_anchor = Astal.WindowAnchor.BOTTOM;
			break;
		}

		add_window(new NavBar(navbar_anchor));
		add_window(new Runner());
		add_window(new QuickMenu());
		add_window(new OnScreenDisplay());
		add_window(new NotifPopItemsCenter());
		add_window(new PowerMenu());

		Timeout.add_seconds(60, () => {
			sync_uptime();
			return true;
		});
		sync_uptime();

		hold();
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
		primary_monitor = (Gdk.Monitor)monitors.get_item(0);
		if (primary_monitor == null) {
			critical("Failed to get primary monitor");
			return;
		}
		message("Successfully initialized primary monitor");
	}

	private void setup_css_monitoring() {
		_css_file = File.new_for_path(@"$(Environment.get_user_config_dir())/morghulis/main.css");
		try {
			_css_file_monitor = _css_file.monitor_file(
				GLib.FileMonitorFlags.WATCH_HARD_LINKS
				| GLib.FileMonitorFlags.WATCH_MOUNTS
				| GLib.FileMonitorFlags.WATCH_MOVES
			);
			uint count = 0;
			_css_file_monitor.changed.connect((file, other_file, event_type) => {
				if (event_type == FileMonitorEvent.CHANGED) {
					apply_css(_css_file.get_path(), true);
					print(@"\033[34mCSS Reloaded:\033[0m \033[33mx$(++count)\033[0m\n");
				} else if (event_type == FileMonitorEvent.CREATED) {
					apply_css(_css_file.get_path(), true);
					print("\033[34mCSS File Created!\033[0m\n");
				}
			});
		} catch (IOError e) {
			critical("Error setting up CSS monitoring: %s\n", e.message);
		}
	}

	// Function made to HAVE ONLY ONE: `Gtk.StyleContext' has been deprecated since 4.10
	[Version(deprecated = true, deprecated_since = "4.10", replacement = "")]
	private void add_css_provider(Gtk.CssProvider provider) {
		Gtk.StyleContext.add_provider_for_display(
			Gdk.Display.get_default(),
			provider,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);
	}

	private void load_css() {
		var provider = new Gtk.CssProvider();
		provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
		add_css_provider(provider);
	}

	public void apply_css(string css_path, bool user_css = false) {
		var provider = new Gtk.CssProvider();

		if (user_css && FileUtils.test(css_path, FileTest.EXISTS)) {
			provider.load_from_path(css_path);
			add_css_provider(provider);
		}
	}

	private void sync_uptime() {
		GTop.get_uptime(out _g_uptime);
		var uptime_hours = Math.floor(_g_uptime.uptime / 3600);
		var uptime_minutes = Math.floor((_g_uptime.uptime % 3600) / 60);

		if (uptime_hours <= 0) {
			uptime = @"Up for $uptime_minutes minutes";
		} else {
			uptime = @"Up $uptime_hours hours, and $uptime_minutes minutes";
		}
	}
}
