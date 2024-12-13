using AstalHyprland;
using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NavBar.ui")]
public class NavBar : Astal.Window {
	public static NavBar instance { get; private set; }

	// Properties
	private AstalMpris.Mpris mpris { get; set; }
	private AstalNotifd.Notifd notifd { get; set; }

	public AstalHyprland.Hyprland hyprland { get; set; }
	public AstalMpris.Player mpd { get; set; }
	public AstalWp.Endpoint speaker { get; set; }
	public AstalBattery.Device battery { get; set; }
	public AstalPowerProfiles.PowerProfiles power_profiles { get; set; }

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
	public unowned Gtk.Label active_submap;

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

	[GtkCallback]
	public void change_power_profile() {
		var active_profile = power_profiles.active_profile;

		switch (active_profile) {
			case "performance":
				power_profiles.active_profile = "power-saver";
				break;

			case "power-saver":
				power_profiles.active_profile = "balanced";
				break;

			case "balanced":
			default:
				power_profiles.active_profile = "performance";
				break;
		}
	}

	[GtkCallback]
	public bool focused_client_exists(AstalHyprland.Client? focused_client) {
		return focused_client != null;
	}

	// Constructor
	public NavBar() {
		Object(
			namespace: "NavBar",
			anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
		present();
	}

	construct {
		speaker = AstalWp.get_default().audio.default_speaker;
		mpris = AstalMpris.Mpris.get_default();
		hyprland = AstalHyprland.Hyprland.get_default();
		notifd = AstalNotifd.Notifd.get_default();
		battery = AstalBattery.Device.get_default();
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		hyprland.submap.connect((_, value) => {
			if (value != null && value != "") {
				active_submap.label = value;
				active_submap.set_visible(true);
			}
			else {
				active_submap.set_visible(false);
			}
		});

		init_notif_label_count();
		init_clock();
		instance = this;
	}

	private void init_notif_label_count() {
		notifd.notified.connect(() => {
			notif_count_label.label = (notifd.notifications.length()).to_string();
		});
		notifd.resolved.connect(() => {
			notif_count_label.label = (notifd.notifications.length()).to_string();
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
