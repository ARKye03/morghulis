public class Morghulis : Astal.Application {
	private bool _css_loaded;
	private File _css_file;
	private FileMonitor _css_file_monitor;
	private GTop.Uptime _g_uptime;

	public static Morghulis instance { get; private set; }
	public static GLib.Settings gsettings { get; private set; }
	public static Gdk.Display? display { get; private set; }
	public static Gdk.Monitor? primary_monitor { get; private set; }
	public static string clock_format { get; private set; default = "%H:%M %b %d"; }
	public static string user_name { get; private set; }

	public string uptime { get; private set; }

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
		gsettings = new GLib.Settings("com.arkye.morghulis");

		try {
			acquire_socket();
		} catch (Error e) {
			critical("%s", e.message);
		}
		instance = this;

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
			critical("Error: %s\n", e.message);
		}
	}

	[DBus(visible = false)]
	public override void activate() {
		base.activate();
		setup_display_and_monitor();
		Gtk.IconTheme.get_for_display(display).add_resource_path("/com/github/ARKye03/morghulis/icons");
		user_name = Environment.get_user_name();

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
		primary_monitor = (Gdk.Monitor)monitors.get_item(0);
		if (primary_monitor == null) {
			critical("Failed to get primary monitor");
			return;
		}
		message("Successfully initialized primary monitor");
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
