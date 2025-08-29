public class Morghulis : Gtk.Application {
	private File _css_file;
	private FileMonitor _css_file_monitor;
	private GTop.Uptime _g_uptime;
	private List<MorghulWindow> _windows;

	public static Morghulis instance { get; private set; }
	public static GLib.Settings gsettings { get; private set; }
	public static Gdk.Display? display { get; private set; }
	public static Gdk.Monitor? primary_monitor { get; private set; }
	public static string clock_format { get; private set; default = "%H:%M %b %d"; }
	public static string user_name { get; private set; }

	public string uptime { get; private set; }

	construct {
		this.application_id = "com.arkye.morghulis";
		this.flags = ApplicationFlags.HANDLES_COMMAND_LINE;

		instance = this;
		_windows = new List<MorghulWindow>();

		Adw.init();
		gsettings = new GLib.Settings("com.arkye.morghulis");
		user_name = Environment.get_user_name();

		setup_css_monitoring();
	}

	public override int command_line(ApplicationCommandLine command_line) {
		var args = command_line.get_arguments();

		// Check for help flag before option parsing to avoid issues with running instance
		foreach (string arg in args) {
			if (arg == "--help" || arg == "-h" || arg == "-?") {
				command_line.print("\033[1;36mUsage:\033[0m\n");
				command_line.print("  \033[1;32mmorghulis\033[0m \033[33m[OPTION…]\033[0m - \033[1;35mMorghulis Desktop Shell\033[0m\n\n");
				command_line.print("\033[1;34mA GTK4 desktop shell built with Vala\033[0m\n\n");
				command_line.print("\033[1;33mHelp Options:\033[0m\n");
				command_line.print("  \033[32m-?, --help\033[0m                Show help options\n\n");
				command_line.print("\033[1;33mApplication Options:\033[0m\n");
				command_line.print("  \033[32m-v, --version\033[0m             Show version information\n");
				command_line.print("  \033[32m-q, --quit\033[0m                Quit the application\n");
				command_line.print("  \033[32m-i, --inspector\033[0m           Toggle GTK inspector\n");
				command_line.print("  \033[32m-t, --toggle=\033[36mWINDOW\033[0m       Toggle window visibility\n");
				command_line.print("  \033[32m-r, --request=\033[36mREQUEST\033[0m     Send custom request\n\n");
				command_line.print("\033[1;33mExamples:\033[0m\n");
				command_line.print("\t\033[32mmorghulis -t runner\033[0m\t\033[90m# Toggle runner window\033[0m\n");
				command_line.print("\t\033[32mmorghulis -r change_volume\033[0m\t\033[90m# Trigger volume change OSD\033[0m\n");
				return 0;
			}
		}

		// Option variables
		bool show_version = false;
		bool quit_app = false;
		bool inspector = false;
		string? toggle_window_name = null;
		string? request_type = null;

		var options = new OptionEntry[] {
			{ "version", 'v', OptionFlags.NONE, OptionArg.NONE, out show_version, "Show version information", null },
			{ "quit", 'q', OptionFlags.NONE, OptionArg.NONE, out quit_app, "Quit the application", null },
			{ "inspector", 'i', OptionFlags.NONE, OptionArg.NONE, out inspector, "Toggle GTK inspector", null },
			{ "toggle", 't', OptionFlags.NONE, OptionArg.STRING, out toggle_window_name, "Toggle window visibility", "WINDOW" },
			{ "request", 'r', OptionFlags.NONE, OptionArg.STRING, out request_type, "Send custom request", "REQUEST" }
		};

		var context = new OptionContext("- Morghulis Desktop Shell");
		context.set_summary("A GTK4 desktop shell built with Vala");
		context.set_description("Examples:\n\tmorghulis -t runner\t# Toggle runner window\n\tmorghulis -r change_volume\t# Trigger volume change OSD");
		context.set_help_enabled(false);
		context.add_main_entries(options, null);

		try {
			unowned string[] args_unowned = args;
			context.parse(ref args_unowned);
		} catch (OptionError e) {
			command_line.printerr("Option parsing failed: %s\n", e.message);
			return 1;
		}

		if (show_version) {
			command_line.print(@"Morghulis version $(MorghulVersion.VERSION)\n");
			return 0;
		}

		if (quit_app) {
			quit();
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

		if (_windows.length() > 0) {
			command_line.printerr("Application is already running");
			return 1;
		} else {
			activate();
			return 0;
		}
	}

	private void handle_request(string request) {
		switch (request) {
			case "change_volume":
				if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_volume();
				} else {
					warning("OnScreenDisplay not available");
				}
			break;

			case "change_brightness":
				if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_brightness();
				} else {
					warning("OnScreenDisplay not available");
				}
			break;

			default:
				warning("Unknown request: %s", request);
			break;
		}
	}

	private void toggle_window(string window_name) {
		_windows.foreach(w => {
			if (w.title == window_name) {
				w.visible = !w.visible;
			}
		});
	}

	private void toggle_inspector() {
		Gtk.Window.set_interactive_debugging(true);
	}

	public new void add_window(MorghulWindow window) {
		_windows.append(window);
		window.set_application(this);
	}

	protected override void activate() {
		setup_display_and_monitor();
		Gtk.IconTheme.get_for_display(display).add_resource_path("/com/github/ARKye03/morghulis/icons");
		load_css();

		if (_css_file.query_exists()) {
			apply_css(_css_file.get_path(), true);
		}

		string navbar_position = gsettings.get_string("navbar-anchor");
		WindowAnchor navbar_anchor;

		switch (navbar_position.down()) {
			case "top":
				navbar_anchor = WindowAnchor.TOP;
			break;

			case "bottom":
			default:
				navbar_anchor = WindowAnchor.BOTTOM;
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
			return Source.CONTINUE;
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
