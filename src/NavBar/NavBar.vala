using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NavBar.ui")]
public class NavBar : Astal.Window {
	public static NavBar instance { get; private set; }

	// Properties
	private AstalMpris.Mpris mpris { get; set; }
	private AstalNotifd.Notifd notifd { get; set; }

	public AstalHyprland.Hyprland hyprland { get; set; }
	public AstalRiver.River river { get; set; }
	public AstalMpris.Player mpd { get; set; }
	public AstalWp.Endpoint speaker { get; set; }
	public AstalBattery.Device battery { get; set; }

	[GtkChild]
	public unowned Gtk.Label clock;

	[GtkChild]
	public unowned Gtk.Popover notif_popover;

	[GtkChild]
	public unowned Gtk.Label notif_count_label;

	[GtkChild]
	public unowned Gtk.Popover tray_popover;

	[GtkChild]
	public unowned Gtk.Popover clock_popover;

	[GtkChild]
	public unowned Adw.Bin workspaces;

	// Callback Methods
	[GtkCallback]
	public void notif_popover_popup() {
		notif_popover.popup();
	}

	[GtkCallback]
	public void tray_popover_popup() {
		tray_popover.popup();
	}

	[GtkCallback]
	public void clock_popover_popup() {
		clock_popover.popup();
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

	// Constructor
	public NavBar() {
		Object(
			namespace : "NavBar",
			anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
		present();
	}

	construct {
		speaker = AstalWp.get_default().audio.default_speaker;
		mpris = AstalMpris.Mpris.get_default();
		notifd = AstalNotifd.Notifd.get_default();
		battery = AstalBattery.Device.get_default();

		string current_session = Environment.get_variable("XDG_CURRENT_DESKTOP");
		if (current_session == "Hyprland") {
			hyprland = AstalHyprland.Hyprland.get_default();
			setup_hyprland();
		} else if (current_session == "river") {
			river = AstalRiver.River.get_default();
			setup_river();
		} else {
			warning("No Hyprland or River detected");
		}

		init_notif_label_count();
		init_clock();
		instance = this;
	}

	// Hyprland modules
	[GtkChild]
	public unowned Adw.Bin active_submap;

	[GtkChild]
	public unowned Adw.Bin active_client;

	private void setup_hyprland() {
		message("Setting up Hyprland");
		workspaces.set_child(new HyprWorkspaces());

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

	private void setup_river() {
		workspaces.set_child(new RiverTags());
	}

	private void init_notif_label_count() {
		notifd.notified.connect(() => {
			notif_count_label.label = notifd.notifications.length().to_string();
		});
		notifd.resolved.connect(() => {
			notif_count_label.label = notifd.notifications.length().to_string();
		});
		notif_count_label.label = notifd.notifications.length().to_string();
	}

	// Clock Methods
	private void update_clock() {
		var clock_time = new DateTime.now_local();

		clock.label = clock_time.format("%I:%M %p %b %e");
	}

	private void init_clock() {
		update_clock();
		GLib.Timeout.add(60000, () => {
			update_clock();
			return true;
		});
	}
}
