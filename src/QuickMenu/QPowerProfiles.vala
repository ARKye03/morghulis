[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QPowerProfiles.ui")]
class QPowerProfiles : Gtk.Box {
	public AstalPowerProfiles.PowerProfiles power_profiles { get; construct; }
	private AstalBattery.Device battery { get; set; }

	private Gtk.Button performance_button { get; set; }
	private Gtk.Button power_saver_button { get; set; }
	private Gtk.Button balanced_button { get; set; }

	[GtkChild]
	public unowned Gtk.Box ppd_box;

	[GtkChild]
	public unowned Adw.Bin cpb;

	construct {
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();
		battery = AstalBattery.Device.get_default();

		performance_button = new Gtk.Button.with_label("Performance");
		power_saver_button = new Gtk.Button.with_label("Power Saver");
		balanced_button = new Gtk.Button.with_label("Balanced");

		ppd_box.append(performance_button);
		ppd_box.append(balanced_button);
		ppd_box.append(power_saver_button);

		power_profiles.notify["active-profile"].connect(switch_profile);
		switch_profile();

		performance_button.clicked.connect(() => {
			power_profiles.active_profile = "performance";
		});

		power_saver_button.clicked.connect(() => {
			power_profiles.active_profile = "power-saver";
		});

		balanced_button.clicked.connect(() => {
			power_profiles.active_profile = "balanced";
		});

		CircularProgressBar progress_bar = new CircularProgressBar();
		power_profiles.bind_property("icon_name", progress_bar, "icon-name", BindingFlags.SYNC_CREATE);
		battery.bind_property("percentage", progress_bar, "percentage", BindingFlags.SYNC_CREATE);
		progress_bar.line_cap = Cairo.LineCap.ROUND;
		progress_bar.line_width = 15;

		cpb.set_child(progress_bar);
	}
	private void switch_profile() {
		switch (power_profiles.active_profile) {
			case "performance":
				performance_button.set_css_classes({ "active_profile_button" });
				power_saver_button.set_css_classes({ "" });
				balanced_button.set_css_classes({ "" });
				break;

			case "power-saver":
				performance_button.set_css_classes({ "" });
				power_saver_button.set_css_classes({ "active_profile_button" });
				balanced_button.set_css_classes({ "" });
				break;

			case "balanced":
				performance_button.set_css_classes({ "" });
				power_saver_button.set_css_classes({ "" });
				balanced_button.set_css_classes({ "active_profile_button" });
				break;
		}
	}
}
