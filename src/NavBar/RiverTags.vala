public class RiverTags : Gtk.Box {
	public AstalRiver.River river { get; set; }
	private AstalRiver.Output output { get; set; }
	public List<Gtk.Button> tags;

	private static string[] wicons = {
		" ", " ", "󰨞 ",
		" ", " ", "󰭹 ",
		" ", " ", "󰊖 "
	};

	public RiverTags(AstalRiver.River river) {
		this.river = river;
		string focused_output = river.get_focused_output();
		output = river.get_output(focused_output);
		tags = new List<Gtk.Button>();
		spacing = 5;

		for (int i = 0; i < 9; i++) {
			int tag_index = i;
			var tag_button = new Gtk.Button();
			var tag_button_label = new Gtk.Label(wicons[tag_index]);
			tag_button.set_child(tag_button_label);

			this.append(tag_button);
			tags.append(tag_button);
			tag_button.clicked.connect(() => {
				output.focused_tags = 1 << tag_index;
			});
		}

		output.changed.connect(() => update_css());
		update_css();
	}

	private void update_css() {
		uint occupied_tags = output.occupied_tags;
		uint focused_tags = output.focused_tags;

		for (int i = 0; i < tags.length(); i++) {
			var tag_button = tags.nth_data(i);

			if ((occupied_tags & (1 << i)) != 0) {
				tag_button.add_css_class("occupied");
				tag_button.remove_css_class("empty");
			} else {
				tag_button.remove_css_class("occupied");
			}

			if ((focused_tags & (1 << i)) != 0) {
				tag_button.add_css_class("focused");
				tag_button.remove_css_class("empty");
			} else {
				tag_button.remove_css_class("focused");
			}

			if ((occupied_tags & (1 << i)) == 0 && (focused_tags & (1 << i)) == 0) {
				tag_button.add_css_class("empty");
			}
		}
	}
}
