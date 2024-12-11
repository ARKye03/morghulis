using AstalHyprland;
using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NavBar.ui")]
public class NavBar : Astal.Window {
	public static NavBar instance { get; private set; }
// Properties
	private AstalMpris.Mpris mpris { get; set; }
	private AstalNotifd.Notifd notifd { get; set; }
	private List <Gtk.Button> workspace_buttons = new List <Gtk.Button> ();

	public AstalHyprland.Hyprland hyprland { get; set; }
	public AstalMpris.Player mpd { get; set; }
	public AstalWp.Endpoint speaker { get; set; }
	public AstalBattery.Device battery { get; set; }
	public AstalPowerProfiles.PowerProfiles power_profiles { get; set; }

// UI Elements
	[GtkChild]
	public unowned Gtk.Box workspaces;

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
	public bool focused_client_exists(AstalHyprland.Client ?focused_client) {
		return focused_client != null;
	}

// Workspace icons
	private static string[] wicons = {
		" ", " ", "󰨞 ",
		" ", " ", "󰭹 ",
		" ", " ", "󰊖 ",
		" ",
	};

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
		init_workspaces();
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

// Clock methods
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

// Workspace methods
	private static int focused_workspace_id { get; private set; }

	private void init_workspaces() {
		for (var i = 1; i <= 10; i++) {
			var workspace_button = new Gtk.Button.with_label(wicons[i - 1]);
			connect_button_to_workspace(workspace_button, i);
			workspace_button.valign = Gtk.Align.CENTER;
			workspace_button.halign = Gtk.Align.CENTER;
			workspaces.append(workspace_button);
			workspace_buttons.append(workspace_button);
		}
		update_workspaces();
		setup_workspace_event_handlers();
		setup_workspace_scroll();
	}

	private void setup_workspace_event_handlers() {
		hyprland.notify["focused-workspace"].connect(update_workspaces);
		hyprland.client_added.connect(update_workspaces);
		hyprland.client_removed.connect(update_workspaces);
		hyprland.client_moved.connect(update_workspaces);
	}

	private void setup_workspace_scroll() {
		var scroll = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
		scroll.scroll.connect((delta_x, delta_y) => {
			string direction = delta_y > 0 ? "e-1" : "e+1";
			hyprland.dispatch("workspace", direction);
			return true;
		});
		workspaces.add_controller(scroll);
	}

	private void update_workspaces() {
		focused_workspace_id = hyprland.focused_workspace.id;

		int index = 0;
		workspace_buttons.foreach((button) => {
			if (button != null) {
				if (index + 1 == focused_workspace_id) {
					button.set_css_classes(new string[] { "focused" });
				}
				else if (workspace_exists(index + 1)) {
					button.set_css_classes(new string[] { "has_windows" });
				}
				else {
					button.set_css_classes(new string[] { "empty" });
				}
			}
			index++;
		});
	}

	private void connect_button_to_workspace(Gtk.Button button, int workspace_number) {
		var middle_click = new Gtk.GestureClick();
		middle_click.set_button(2);
		middle_click.pressed.connect(() => {
			hyprland.dispatch("movetoworkspacesilent", workspace_number.to_string());
		});
		button.add_controller(middle_click);
		button.clicked.connect(() => {
			hyprland.dispatch("workspace", workspace_number.to_string());
		});
	}

	private bool workspace_exists(int workspace_number) {
		var workspace = hyprland.get_workspace(workspace_number);
		return workspace != null && workspace.clients != null && workspace.clients.length() > 0;
	}
}
