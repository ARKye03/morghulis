using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NavBar.ui")]
public class NavBar : Astal.Window {
	private GLib.DateTime _clock_time;

	public static NavBar instance { get; private set; }
	public AstalBattery.Device battery { get; private set; }
	public AstalWp.Endpoint speaker { get; private set; }
	public string current_time { get; private set; }
	public static string[] icon_names = {
		"terminal-symbolic",
		"browser-symbolic",
		"code-symbolic",
		"explorer-symbolic",
		"social-symbolic",
		"docs-symbolic",
		"media-symbolic",
		"settings-symbolic",
		"gaming-symbolic",
	};
	public Astal.WindowAnchor vanchor { get; construct; }

	[GtkChild]
	private unowned Adw.Bin workspaces;

	[GtkChild]
	private unowned Adw.Bin active_client;

	[GtkChild]
	private unowned Adw.Bin active_submap;

	public NavBar(Astal.WindowAnchor vanchor = Astal.WindowAnchor.BOTTOM) {
		Object(anchor: Astal.WindowAnchor.LEFT | vanchor | Astal.WindowAnchor.RIGHT, vanchor: vanchor);
		battery = AstalBattery.Device.get_default();
		speaker = AstalWp.get_default().audio.default_speaker;

		init_compositor();
		init_clock();

		instance = this;
		present();
	}

	[GtkCallback]
	public void toggle_side_dashboard() {
		QuickMenu.instance.visible = !QuickMenu.instance.visible;
	}

	[GtkCallback]
	public void toggle_runner() {
		Runner.instance.visible = !Runner.instance.visible;
	}

	[GtkCallback]
	public bool scroll_volume(double dx, double dy) {
		if (dy > 0) {
			speaker.volume = double.max(speaker.volume - 0.05, 0);
		} else {
			speaker.volume = double.min(speaker.volume + 0.05, 1);
		}
		return true;
	}

	[GtkCallback]
	public void toggle_volume() {
		speaker.mute = !speaker.mute;
	}

	[GtkCallback]
	public string current_volume(double volume) {
		return @"$(Math.round(volume * 100))%";
	}

	[GtkCallback]
	public string current_battery(double percentage) {
		return @"$(Math.round(percentage * 100))%";
	}

	private void update_clock() {
		_clock_time = new DateTime.now_local();
		current_time = _clock_time.format(Morghulis.clock_format);
	}

	private void init_clock() {
		Timeout.add(60000, () => {
			update_clock();
			return true;
		});
		update_clock();
	}

	private void init_compositor() {
		string current_session = Environment.get_variable("XDG_CURRENT_DESKTOP");

#if hyprland
		if (current_session == "Hyprland") {
			setup_hyprland();
		}
#if river
		else if (current_session == "river") {
			setup_river();
		}
#endif
#else
#if river
		if (current_session == "river") {
			setup_river();
		}
#endif
#endif
		if (current_session != "Hyprland" && current_session != "river") {
			warning("No Hyprland or River detected");
		}
	}

#if hyprland
	private AstalHyprland.Hyprland _hyprland;

	private void setup_hyprland() {
		message("Setting up Hyprland");
		_hyprland = AstalHyprland.Hyprland.get_default();
		workspaces.child = new HyprWorkspaces(_hyprland);

		Gtk.Label submap_label = new Gtk.Label("default") {
			halign = Gtk.Align.START,
			ellipsize = Pango.EllipsizeMode.END,
			max_width_chars = 20,
			tooltip_text = "Active submap"
		};

		active_submap.child = submap_label;

		_hyprland.submap.connect((value) => {
			if (value != null && value != "") {
				submap_label.label = value;
				active_submap.visible = true;
			} else {
				active_submap.visible = false;
			}
		});

		Gtk.Label client_label = new Gtk.Label("default") {
			halign = Gtk.Align.START,
			ellipsize = Pango.EllipsizeMode.END,
			max_width_chars = 20,
			tooltip_text = "Active client",
		};

		_hyprland.bind_property("focused_client", client_label, "label", BindingFlags.SYNC_CREATE, (binding, srcval, ref targetval) => {
			var client = (AstalHyprland.Client)srcval;
			if (client != null && client.title != null && client.title != "") {
				targetval = client.title;
				active_client.visible = true;
			} else {
				active_client.visible = false;
			}
			return true;
		});

		active_client.child = client_label;
	}
#endif

#if river
	private AstalRiver.River _river;

	private void setup_river() {
		message("Setting up River");
		_river = AstalRiver.River.get_default();

		workspaces.child = new RiverTags(_river);

		Gtk.Label view_label = new Gtk.Label("default") {
			halign = Gtk.Align.START,
			ellipsize = Pango.EllipsizeMode.END,
			max_width_chars = 20,
			tooltip_text = "Active View"
		};
		active_client.child = view_label;

		_river.bind_property("focused-view", view_label, "label", BindingFlags.SYNC_CREATE, (_, src, ref trgt) => {
			var view_title = (string)src;
			if (view_title != null && view_title != "") {
				trgt = view_title;
				active_client.visible = true;
			} else {
				active_client.visible = false;
			}
			return true;
		});

		Gtk.Label mode_label = new Gtk.Label("default") {
			halign = Gtk.Align.START,
			ellipsize = Pango.EllipsizeMode.END,
			max_width_chars = 20,
			tooltip_text = "Active mode"
		};
		active_submap.child = mode_label;

		_river.bind_property("mode", mode_label, "label", BindingFlags.SYNC_CREATE, (_, src, ref trgt) => {
			var mode_name = (string)src;
			if (mode_name != null && mode_name != "normal") {
				trgt = mode_name;
				active_submap.visible = true;
			} else {
				active_submap.visible = false;
			}
			return true;
		});
	}
#endif
}
