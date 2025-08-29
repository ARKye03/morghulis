public class Morghulis : Gtk.Application {
	private GTop.Uptime _g_uptime;
	private List<MorghulWindow> _windows;
	private CssManager _css_manager;

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

		_css_manager = new CssManager();
		setup_css_signals();
	}

	public override int command_line(ApplicationCommandLine command_line) {
		var args = command_line.get_arguments();

		// Check for help flag before option parsing to avoid issues with running instance
		if (should_show_help(args)) {
			show_help(command_line);
			return 0;
		}

		var parser = new CommandLineParser();
		var result = parser.parse(args, command_line);

		if (result.should_exit) {
			return result.exit_code;
		}

		if (result.show_version) {
			command_line.print(@"Morghulis version $(MorghulVersion.VERSION)\n");
			return 0;
		}

		if (result.quit_app) {
			quit();
			return 0;
		}

		if (result.inspector) {
			toggle_inspector();
			return 0;
		}

		if (result.toggle_window_name != null) {
			toggle_window(result.toggle_window_name);
			return 0;
		}

		if (result.request_type != null) {
			handle_request(result.request_type);
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

	private bool should_show_help(string[] args) {
		foreach (string arg in args) {
			if (arg == "--help" || arg == "-h" || arg == "-?") {
				return true;
			}
		}
		return false;
	}

	private void show_help(ApplicationCommandLine command_line) {
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
	}

	private void setup_css_signals() {
		_css_manager.css_reloaded.connect((count) => {
			print(@"\033[34mCSS Reloaded:\033[0m \033[33mx$count\033[0m\n");
		});

		_css_manager.css_created.connect(() => {
			print("\033[34mCSS File Created!\033[0m\n");
		});
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
		setup_ui();
		setup_timers();
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

		// Morghulis assumes there is only one monitor
		primary_monitor = (Gdk.Monitor)monitors.get_item(0);
		if (primary_monitor == null) {
			critical("Failed to get primary monitor");
			return;
		}

		message("Successfully initialized primary monitor");
	}

	private void setup_ui() {
		Gtk.IconTheme.get_for_display(display).add_resource_path("/com/github/ARKye03/morghulis/icons");

		// Load CSS
		_css_manager.load_app_css();
		_css_manager.load_user_css();

		// Create windows
		create_windows();
	}

	private void create_windows() {
		string navbar_position = gsettings.get_string("navbar-anchor");
		WindowAnchor navbar_anchor = navbar_position.down() == "top" ?
									 WindowAnchor.TOP : WindowAnchor.BOTTOM;

		add_window(new NavBar(navbar_anchor));
		add_window(new Runner());
		add_window(new QuickMenu());
		add_window(new OnScreenDisplay());
		add_window(new NotifPopItemsCenter());
		add_window(new PowerMenu());
	}

	private void setup_timers() {
		// Update uptime every minute
		Timeout.add_seconds(60, () => {
			sync_uptime();
			return Source.CONTINUE;
		});
		sync_uptime();
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

public struct CommandLineResult {
	public bool should_exit;
	public int exit_code;
	public bool show_version;
	public bool quit_app;
	public bool inspector;
	public string? toggle_window_name;
	public string? request_type;
}

public class CommandLineParser : Object {
	public CommandLineResult parse(string[] args, ApplicationCommandLine command_line) {
		var result = CommandLineResult();

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
			result.should_exit = true;
			result.exit_code = 1;
			return result;
		}

		result.show_version = show_version;
		result.quit_app = quit_app;
		result.inspector = inspector;
		result.toggle_window_name = toggle_window_name;
		result.request_type = request_type;

		return result;
	}
}
