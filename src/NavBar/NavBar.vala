using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NavBar.ui")]
public class NavBar : Astal.Window {
	private GLib.DateTime clock_time { get; set; }
	private string clock_format { get; set; default = "%H:%M %b %e"; }

	public static NavBar instance { get; private set; }
	public AstalBattery.Device battery { get; set; }

	[GtkChild]
	private unowned Gtk.Label clock;

	[GtkChild]
	private unowned Adw.Bin workspaces;

	[GtkChild]
	private unowned Adw.Bin active_client;

	[GtkChild]
	private unowned Adw.Bin active_submap;

	public NavBar() {
		Object(
			namespace : "NavBar",
			anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
		battery = AstalBattery.Device.get_default();

		init_compositor();
		init_clock();
		instance = this;

		present();
	}

	[GtkCallback]
	public void toggle_side_dashboard() {
		try {
			Morghulis.instance.toggle_window("QuickMenu");
		} catch (GLib.Error e) {
			warning("Failed to toggle window: %s", e.message);
		}
	}

	[GtkCallback]
	public void toggle_runner() {
		try {
			Morghulis.instance.toggle_window("Runner");
		} catch (GLib.Error e) {
			warning("Failed to toggle window: %s", e.message);
		}
	}

	[GtkCallback]
	public string current_battery(double percentage) {
		return @"$(Math.round(percentage * 100))%";
	}

	private void update_clock() {
		clock_time = new DateTime.now_local();

		clock.label = clock_time.format(clock_format);
	}

	private void init_clock() {
		update_clock();
		GLib.Timeout.add(60000, () => {
			update_clock();
			return true;
		});
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
	private AstalHyprland.Hyprland hyprland { get; set; }

	private void setup_hyprland() {
		message("Setting up Hyprland");
		hyprland = AstalHyprland.Hyprland.get_default();
		workspaces.set_child(new HyprWorkspaces(hyprland));

		Gtk.Label submap_label = new Gtk.Label("default");
		submap_label.set_visible(false);
		submap_label.halign = Gtk.Align.START;
		submap_label.ellipsize = Pango.EllipsizeMode.END;
		submap_label.max_width_chars = 20;
		submap_label.tooltip_text = "Active submap";
		active_submap.set_child(submap_label);
		hyprland.submap.connect((value) => {
			if (value != null && value != "") {
				submap_label.label = value;
				active_submap.set_visible(true);
			} else {
				active_submap.set_visible(false);
			}
		});

		Gtk.Label client_label = new Gtk.Label("default");
		client_label.set_visible(false);
		client_label.halign = Gtk.Align.START;
		client_label.ellipsize = Pango.EllipsizeMode.END;
		client_label.max_width_chars = 20;
		client_label.tooltip_text = "Active client";
		hyprland.notify["focused_client"].connect((value) => {
			var client = (AstalHyprland.Client)value;
			if (client.title != null && client.title != "") {
				client_label.label = client.title;
				active_client.set_visible(true);
			} else {
				active_client.set_visible(false);
			}
		});

		active_client.set_child(client_label);
		hyprland.bind_property("focused-client", client_label, "label", BindingFlags.SYNC_CREATE);
	}
#endif

#if river
	private Gtk.Label view_label = new Gtk.Label("default");
	private AstalRiver.River river { get; set; }

	private void setup_river() {
		message("Setting up River");
		river = AstalRiver.River.get_default();

		workspaces.set_child(new RiverTags(river));

		view_label.halign = Gtk.Align.START;
		view_label.ellipsize = Pango.EllipsizeMode.END;
		view_label.max_width_chars = 20;
		active_client.tooltip_text = "Active View";
		active_client.set_child(view_label);
		river.notify["focused-view"].connect(active_view);
		active_view();
	}

	private void active_view() {
		if (river.focused_view != null && river.focused_view != "") {
			view_label.label = river.focused_view;
			active_client.visible = true;
		} else {
			active_client.visible = false;
		}
	}
#endif
}
