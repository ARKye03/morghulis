[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QPowerProfiles.ui")]
class QPowerProfiles : Gtk.Box {
	public AstalPowerProfiles.PowerProfiles power_profiles { get; construct; }
	public AstalBattery.Device battery { get; set; }

	[GtkChild]
	private unowned Gtk.Button performance_button;

	[GtkChild]
	private unowned Gtk.Button balanced_button;

	[GtkChild]
	private unowned Gtk.Button power_saver_button;

	construct {
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		battery = AstalBattery.Device.get_default();

		power_profiles.notify["active-profile"].connect(switch_profile);
		switch_profile();
	}

	[GtkCallback]
	private void set_performance_mode() {
		power_profiles.active_profile = "performance";
	}

	[GtkCallback]
	private void set_balanced_mode() {
		power_profiles.active_profile = "balanced";
	}

	[GtkCallback]
	private void set_power_saver_mode() {
		power_profiles.active_profile = "power-saver";
	}

	private void switch_profile() {
		switch (power_profiles.active_profile) {
			case "performance":
				performance_button.set_css_classes({ "accent" });
				power_saver_button.set_css_classes({ "" });
				balanced_button.set_css_classes({ "" });
			break;

			case "balanced":
				performance_button.set_css_classes({ "" });
				power_saver_button.set_css_classes({ "" });
				balanced_button.set_css_classes({ "accent" });
			break;

			case "power-saver":
				performance_button.set_css_classes({ "" });
				power_saver_button.set_css_classes({ "accent" });
				balanced_button.set_css_classes({ "" });
			break;
		}
	}
}
