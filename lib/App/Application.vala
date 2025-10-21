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
	}

	public override int command_line(ApplicationCommandLine command_line) {
		var args = command_line.get_arguments();

		if (command_line.is_remote) {
			// Check for help flag before option parsing to avoid issues with running instance
			if (HelpDisplay.should_show_help(args)) {
				HelpDisplay.show_help(command_line);
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
				toggle_window(result.toggle_window_name, command_line);
				return 0;
			}

			if (result.request_type != null) {
				handle_request(result.request_type, command_line);
				return 0;
			}

			return 1;
		} else {
			if (_windows.length() > 0) {
				command_line.printerr("Application is already running");
				return 1;
			} else {
				activate();
				return 0;
			}
		}
	}

	private void setup_css_signals() {
		_css_manager.css_reloaded.connect((count) => {
			print(@"\033[34mCSS Reloaded:\033[0m \033[33mx$count\033[0m\n");
		});

		_css_manager.css_created.connect(() => {
			print("\033[34mCSS File Created!\033[0m\n");
		});
	}

	private void handle_request(string request, ApplicationCommandLine command_line) {
		switch (request) {
			case "change_volume"
				:if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_volume();
					command_line.print("Volume changed\n");
				} else {
					command_line.printerr("OnScreenDisplay not available\n");
				}
			break;

			case "change_brightness"
				:if (OnScreenDisplay.instance != null) {
					OnScreenDisplay.instance.change_brightness();
					command_line.print("Brightness changed\n");
				} else {
					command_line.printerr("OnScreenDisplay not available\n");
				}
			break;

			default:
				command_line.printerr(@"Unknown request: $request\n");
			break;
		}
	}

	private void toggle_window(string window_name, ApplicationCommandLine command_line) {
		bool found = false;
		_windows.foreach(w => {
			if (w.title == window_name) {
				w.visible = !w.visible;
				found = true;
			}
		});
		if (!found) {
			command_line.printerr(@"No window found with name: $window_name\n");
		}
	}

	private void toggle_inspector() {
		Gtk.Window.set_interactive_debugging(true);
	}

	public new void add_window(MorghulWindow window) {
		_windows.append(window);
		window.set_application(this);
	}

	protected override void activate() {
		_windows = new List<MorghulWindow>();

		Adw.init();
		gsettings = new GLib.Settings("com.arkye.morghulis");
		user_name = Environment.get_user_name();

		_css_manager = new CssManager();
		setup_css_signals();

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
		add_window(new NavBar());
		add_window(new Runner());
		add_window(new QuickMenu());
		add_window(new OnScreenDisplay());
		add_window(new NotifPopItemsCenter());
		add_window(new PowerMenu());
		add_window(new ScreenRecord());
	}

	private void setup_timers() {
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
