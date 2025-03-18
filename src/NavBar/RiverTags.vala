public class TagButton : Gtk.Button {
	private AstalRiver.Output _output;
	private Gtk.GestureClick _rclick;
	private int _index;

	public TagButton(AstalRiver.Output output, int index, string icon) {
		this._output = output;
		this._index = index;
		try {
			Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_resource(icon);
			Gdk.Paintable paintable = Gdk.Texture.for_pixbuf(pixbuf);
			child = new Gtk.Image.from_paintable(paintable);
		} catch (Error e) {
			warning("Failed to load icon: %s", e.message);
		}
		add_css_class("empty");
		this._rclick = new Gtk.GestureClick() {
			button = Gdk.BUTTON_SECONDARY,
		};

		clicked.connect(() => {
			this._output.focused_tags = 1 << this._index;
		});
		_rclick.pressed.connect(() => {
			this._output.focused_tags ^= 1 << this._index;
		});
		add_controller(_rclick);
	}

	public void update_css() {
		uint occupied_tags = _output.occupied_tags;
		uint focused_tags = _output.focused_tags;
		uint urgent_tags = _output.urgent_tags;

		if ((focused_tags & (1 << _index)) != 0) {
			set_css_classes({ "focused" });
		} else if ((urgent_tags & (1 << _index)) != 0) {
			set_css_classes({ "urgent" });
		} else if ((occupied_tags & (1 << _index)) != 0) {
			set_css_classes({ "occupied" });
		} else {
			set_css_classes({ "empty" });
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
