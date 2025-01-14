public class Morghulis : Astal.Application {
	private string socket_path { get; private set; }
	private bool css_loaded = false;
	private GLib.File file;
	private GLib.FileMonitor monitor;

	public static Morghulis instance;

	public override void request(string msg, SocketConnection conn) {
		AstalIO.write_sock.begin(conn, @"missing response implementation on $instance_name");
	}

	construct {
		instance_name = "morghulis";
		try {
			acquire_socket();
		} catch (Error e) {
			printerr("%s", e.message);
		}
		instance = this;

		file = File.new_for_path(@"$(Environment.get_user_config_dir())/morghulis/main.css");
		if (file.query_exists()) {
			try {
				monitor = file.monitor_file(GLib.FileMonitorFlags.NONE);
				monitor.changed.connect((_) => {
					apply_css(file.get_path(), true);
				});
			} catch (Error e) {
				critical("Error: %s\n", e.message);
			}
		}
	}

	[DBus(visible = false)]
	public override void activate() {
		base.activate();
		if (!css_loaded) {
			load_css();
			css_loaded = true;
		}
		add_window(new QuickMenu());
		add_window(new Runner());
		add_window(new OnScreenDisplay());
		add_window(new NavBar());

		if (file.query_exists()) {
			apply_css(file.get_path(), true);
		}

		this.hold();
	}

	private void load_css() {
		Gtk.CssProvider provider = new Gtk.CssProvider();
		provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
		Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
												  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
}
