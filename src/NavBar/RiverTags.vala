public class TagButton : Gtk.Button {
	private AstalRiver.Output _output;
	private int _index;

	public TagButton(AstalRiver.Output output, int index, string icon) {
		this._output = output;
		this._index = index;
		try {
			Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_resource(icon);
			Gdk.Paintable paintable = Gdk.Texture.for_pixbuf(pixbuf);
			Gtk.Image img = new Gtk.Image.from_paintable(paintable);
			set_child(img);
		} catch (Error e) {
			warning("Failed to load icon: %s", e.message);
		}
		add_css_class("empty");

		clicked.connect(() => {
			this._output.focused_tags = 1 << this._index;
		});
	}

	public void update_css() {
		uint occupied_tags = _output.occupied_tags;
		uint focused_tags = _output.focused_tags;
		uint urgent_tags = _output.urgent_tags;

		if ((occupied_tags & (1 << _index)) != 0) {
			add_css_class("occupied");
		} else {
			remove_css_class("occupied");
		}

		if ((focused_tags & (1 << _index)) != 0) {
			add_css_class("focused");
		} else {
			remove_css_class("focused");
		}

		if ((urgent_tags & (1 << _index)) != 0) {
			add_css_class("urgent");
		} else {
			remove_css_class("urgent");
		}
	}
}

public class RiverTags : Gtk.Box {
	private AstalRiver.Output output { get; set; }
	private uint total_tags { get; set; }
	public AstalRiver.River river { get; set; }
	public List<TagButton> tags;

	private string[] wicons = {
		"/com/github/ARKye03/morghulis/assets/NavBar/terminal.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/browser.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/code.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/explorer.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/docs.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/social.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/media.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/settings.svg",
		"/com/github/ARKye03/morghulis/assets/NavBar/gaming.svg",
	};

	public RiverTags(AstalRiver.River river, uint total_tags = 9) {
		this.river = river;
		string focused_output = river.get_focused_output();
		output = river.get_output(focused_output);
		tags = new List<TagButton>();
		spacing = 5;

		for (int i = 0; i < total_tags; i++) {
			var tag_button = new TagButton(output, i, wicons[i]);
			this.append(tag_button);
			tags.append(tag_button);
		}

		output.changed.connect(() => update_css());
		update_css();
	}

	private void update_css() {
		foreach (var tag_button in tags) {
			tag_button.update_css();
		}
	}
}
