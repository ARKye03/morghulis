public class TagButton : Gtk.Button {
	private AstalRiver.Output _output;
	private Gtk.GestureClick _rclick;
	private int _index;

	public TagButton(AstalRiver.Output output, int index, string icon) {
		this._output = output;
		this._index = index;
		child = new Gtk.Image.from_icon_name(icon) {
			pixel_size = 20
		};
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
	private AstalRiver.River _river;
	private AstalRiver.Output _output;
	private uint _total_tags;
	private List<TagButton> _tags;
	private const string SHIFTTAGS_PREV = "river-shifttags --occupied --shifts -1";
	private const string SHIFTTAGS_NEXT = "river-shifttags --occupied";

	public RiverTags(AstalRiver.River river, uint max_tags = 9) {
		this._river = river;
		string focused_output = river.get_focused_output();
		this._output = river.get_output(focused_output);
		this._tags = new List<TagButton>();
		this._total_tags = max_tags;

		spacing = 5;

		for (int i = 0; i < _total_tags; i++) {
			var tag_button = new TagButton(_output, i, NavBar.icon_names[i]);
			this.append(tag_button);
			_tags.append(tag_button);
		}

		_output.changed.connect(update_css);
		update_css();

		setup_scroll_handler();
	}

	private void setup_scroll_handler() {
		bool shifttags_available = check_shifttags();

		if (shifttags_available) {
			var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
			scroll_controller.scroll.connect((delta_x, delta_y) => {
				string command = delta_y > 0 ? SHIFTTAGS_PREV : SHIFTTAGS_NEXT;
				try {
					Process.spawn_command_line_async(command);
				} catch (SpawnError e) {
					warning("Failed to execute %s: %s", command, e.message);
				}
				return true;
			});
			this.add_controller(scroll_controller);
		} else {
			warning("River-shifttags not found, please install it to use the tags feature");
		}
	}

	private bool check_shifttags() {
		try {
			string standard_output;
			string standard_error;
			int wait_status;
			Process.spawn_command_line_sync("which river-shifttags",
											out standard_output,
											out standard_error,
											out wait_status);
			return wait_status == 0;
		} catch (SpawnError e) {
			warning("Failed to check for command river-shifttags: %s", e.message);
			return false;
		}
	}

	private void update_css() {
		foreach (var tag_button in _tags) {
			tag_button.update_css();
		}
	}
}
