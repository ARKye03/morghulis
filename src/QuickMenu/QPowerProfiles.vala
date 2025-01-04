[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QPowerProfiles.ui")]
class QPowerProfiles : Gtk.Box {
	public AstalPowerProfiles.PowerProfiles power_profiles { get; construct; }

	private Gtk.Button performance_button { get; set; }
	private Gtk.Button power_saver_button { get; set; }
	private Gtk.Button balanced_button { get; set; }

	[GtkChild]
	public unowned Gtk.Box ppd_list;

	construct {
		power_profiles = AstalPowerProfiles.PowerProfiles.get_default();

		performance_button = new Gtk.Button.with_label("Performance");
		power_saver_button = new Gtk.Button.with_label("Power Saver");
		balanced_button = new Gtk.Button.with_label("Balanced");

		ppd_list.append(performance_button);
		ppd_list.append(balanced_button);
		ppd_list.append(power_saver_button);

		power_profiles.notify["active-profile"].connect(
			switch_profile
			);

		performance_button.clicked.connect(() => {
			power_profiles.active_profile = "performance";
		});

		power_saver_button.clicked.connect(() => {
			power_profiles.active_profile = "power-saver";
		});

		balanced_button.clicked.connect(() => {
			power_profiles.active_profile = "balanced";
		});
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
