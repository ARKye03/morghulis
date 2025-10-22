private enum PMOption {
	NONE,
	SHUTDOWN,
	REBOOT,
	SUSPEND,
	LOGOUT
}
[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/PowerMenu.ui")]
public class PowerMenu : MorghulWindow {
	private PMOption _option;
	private uint _focused_button_index = 0;
	private List<Gtk.Button> _action_buttons;
	private List<Gtk.Button> _confirm_buttons;
	public string uptime { get; set; }

	[GtkChild]
	private unowned Gtk.Stack stapel;

	[GtkChild]
	private unowned Gtk.Box actions_box;

	[GtkChild]
	private unowned Gtk.Box dialog_box;

	construct {
		_option = PMOption.NONE;
		_action_buttons = new List<Gtk.Button>();
		_confirm_buttons = new List<Gtk.Button>();

		Morghulis.instance.bind_property("uptime", this, "uptime", BindingFlags.SYNC_CREATE);

		{
			var current_action_button = (Gtk.Button)actions_box.get_first_child();

			while (current_action_button != null) {
				_action_buttons.append(current_action_button);
				current_action_button = (Gtk.Button)current_action_button.get_next_sibling();
			}
		}
		{
			var current_confirm_button = (Gtk.Button)dialog_box.get_first_child();

			while (current_confirm_button != null) {
				_confirm_buttons.append(current_confirm_button);
				current_confirm_button = (Gtk.Button)current_confirm_button.get_next_sibling();
			}
		}

		this.notify["visible"].connect(() => {
			if (!visible) {
				stapel.visible_child_name = "actions";
				_option = PMOption.NONE;
			} else {
				focus_button(0);
			}
		});

		stapel.notify["visible-child-name"].connect(() => {
			_focused_button_index = 0;
			if (stapel.visible_child_name == "confirmation") {
				focus_button(0);
			}
		});
	}

	[GtkCallback]
	private void cancel() {
		debug("Cancelled");
		stapel.visible_child_name = "actions";
		_option = PMOption.NONE;
	}

	[GtkCallback]
	private void confirm() {
		var current_option = _option;
		this.visible = false;
		switch (current_option) {
			case PMOption.SHUTDOWN:
				try {
					Process.spawn_command_line_async("systemctl poweroff");
				} catch (SpawnError e) {
					warning("Failed to shutdown: %s", e.message);
				}
			break;

			case PMOption.REBOOT:
				try {
					Process.spawn_command_line_async("systemctl reboot");
				} catch (SpawnError e) {
					warning("Failed to reboot: %s", e.message);
				}
			break;

			case PMOption.SUSPEND:
				try {
					Process.spawn_command_line_async("systemctl suspend");
				} catch (SpawnError e) {
					warning("Failed to suspend: %s", e.message);
				}
			break;

			case PMOption.LOGOUT:
				try {
					Process.spawn_command_line_async(@"loginctl terminate-user $(Morghulis.user_name)");
				} catch (SpawnError e) {
					warning("Failed to logout: %s", e.message);
				}
			break;

			default:
				// Funny fact, this line is actually reachable, if current_option is NONE
				// However, at no point in the code can current_option be NONE when confirm is called
				// Nevertheless, some bloody how it happened
				message("Unreachable code reached");
			break;
		}
	}

	[GtkCallback]
	private void set_shutdown() {
		debug("Set Shutdown");
		_option = PMOption.SHUTDOWN;
		stapel.visible_child_name = "confirmation";
	}

	[GtkCallback]
	private void set_reboot() {
		debug("Set Reboot");
		_option = PMOption.REBOOT;
		stapel.visible_child_name = "confirmation";
	}

	[GtkCallback]
	private void set_suspend() {
		debug("Set Suspend");
		_option = PMOption.SUSPEND;
		stapel.visible_child_name = "confirmation";
	}

	[GtkCallback]
	private void set_logout() {
		debug("Set Logout");
		_option = PMOption.LOGOUT;
		stapel.visible_child_name = "confirmation";
	}

	[GtkCallback]
	private void just_lock() {
		debug("Set Lock");
		try {
			Process.spawn_command_line_async("loginctl lock-session");
		} catch (SpawnError e) {
			warning("Failed to lock: %s", e.message);
		}
	}

	private void focus_button(uint index) {
		unowned List<Gtk.Button> current_buttons = stapel.visible_child_name == "actions"
												   ? _action_buttons
												   : _confirm_buttons;

		if (index < 0 || index >= current_buttons.length()) {
			return;
		}

		foreach (var btn in _action_buttons) {
			btn.remove_css_class("suggested-action");
		}
		foreach (var btn in _confirm_buttons) {
			btn.remove_css_class("suggested-action");
		}

		_focused_button_index = index;
		current_buttons.nth_data(index).add_css_class("suggested-action");
	}

	[GtkCallback]
	public void key_released(uint keyval, uint _, Gdk.ModifierType __) {
		unowned List<Gtk.Button> current_buttons = stapel.visible_child_name == "actions"
												   ? _action_buttons
												   : _confirm_buttons;

		if (keyval == Gdk.Key.Escape) {
			this.visible = false;
		} else if (keyval == Gdk.Key.Left) {
			uint new_index = _focused_button_index - 1;
			if (new_index < 0) {
				new_index = current_buttons.length() - 1;
			}
			focus_button(new_index);
		} else if (keyval == Gdk.Key.Right) {
			uint new_index = (_focused_button_index + 1) % current_buttons.length();
			focus_button(new_index);
		} else if (keyval == Gdk.Key.Return || keyval == Gdk.Key.space) {
			current_buttons.nth_data(_focused_button_index).activate();
		}
	}
}
