public class Morghulis : Astal.Application {
	private string socket_path { get; private set; }
	private bool css_loaded = false;

	public static Astal.Application instance;

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
	}

	public Morghulis() {
		Object(
			application_id: "io.Astal.arkye03.morghulis",
			flags: ApplicationFlags.DEFAULT_FLAGS
			);
	}

	[DBus(visible = false)]
	public override void activate() {
		base.activate();
		if (!css_loaded) {
			load_css();
			css_loaded = true;
		}
		add_window(new SideDashboard());
		add_window(new Runner());
		add_window(new OnScreenDisplay());
		add_window(new StatusBar());

		this.hold();
	}

	private void load_css() {
		Gtk.CssProvider provider = new Gtk.CssProvider();
		provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
		Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
																Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
}
