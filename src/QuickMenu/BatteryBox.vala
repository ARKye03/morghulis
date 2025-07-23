[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/BatteryBox.ui")]
class BatteryBox : Gtk.Box {
	public static Gtk.Stack bb_stack_ref;
	public AstalPowerProfiles.PowerProfiles power_profiles { get; private set; }
	public AstalBattery.Device battery { get; private set; }
	public Backlight backlight { get; private set; }
	public Gtk.Adjustment brightness_adj { get; private set; }
	public Gtk.Adjustment battery_adj { get; private set; }

	[GtkChild]
	private unowned Gtk.Stack bb_stack;

	[GtkChild]
	private unowned Gtk.Button ppd_stack_btn;

	[GtkChild]
	private unowned Gtk.Button power_saver;

	[GtkChild]
	private unowned Gtk.Button balanced;

	[GtkChild]
	private unowned Gtk.Button performance;

	construct {
		battery = AstalBattery.Device.get_default();
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		backlight = Backlight.get_default();
		if (battery.is_present) {
			debug("Setting up Battery module");
			brightness_adj = new Gtk.Adjustment(0, 0, 1, 0, 0, 0);
			battery_adj = new Gtk.Adjustment(0, 0, 1, 0, 0, 0);

			backlight.bind_property("percentage", brightness_adj, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
			battery.bind_property("percentage", battery_adj, "value", BindingFlags.SYNC_CREATE);

			if (power_profiles != null && power_profiles.version != null && power_profiles.version != "") {
				debug("Setting up Power Profiles module");
				sync_ppd();
				power_profiles.notify["active-profile"].connect(sync_ppd);
			} else {
				ppd_stack_btn.visible = false;
			}
			bb_stack_ref = bb_stack;
		} else {
			this.dispose();
		}
	}

	[GtkCallback]
	private void show_power_profiles() {
		if (bb_stack.visible_child_name == "profiles") {
			bb_stack.set_visible_child_name("sliders");
		} else {
			bb_stack.set_visible_child_name("profiles");
		}
	}

	[GtkCallback]
	private void set_power_saver() {
		power_profiles.active_profile = "power-saver";
	}

	[GtkCallback]
	private void set_balanced() {
		power_profiles.active_profile = "balanced";
	}

	[GtkCallback]
	private void set_performance() {
		power_profiles.active_profile = "performance";
	}

	private void sync_ppd() {
		switch (power_profiles.active_profile) {
			case "power-saver":
				power_saver.add_css_class("accent");
				balanced.remove_css_class("accent");
				performance.remove_css_class("accent");
			break;

			case "balanced":
				power_saver.remove_css_class("accent");
				balanced.add_css_class("accent");
				performance.remove_css_class("accent");
			break;

			case "performance":
				power_saver.remove_css_class("accent");
				balanced.remove_css_class("accent");
				performance.add_css_class("accent");
			break;

			default:
				critical("Unreachable code reached");
			break;
		}
	}
}
