private enum PMOption {
	NONE,
	SHUTDOWN,
	REBOOT,
	SUSPEND,
	HIBERNATE,
	LOGOUT
}
[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/PowerMenu.ui")]
public class PowerMenu : MorghulWindow {
	private PMOption _option;
	public string uptime { get; set; }

	[GtkChild]
	private unowned Gtk.Stack stapel;

	construct {
		_option = PMOption.NONE;

		Morghulis.instance.bind_property("uptime", this, "uptime", BindingFlags.SYNC_CREATE);

		this.notify["visible"].connect(() => {
			if (!visible) {
				stapel.visible_child_name = "actions";
				_option = PMOption.NONE;
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
		this.visible = false;
		switch (_option) {
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

			case PMOption.HIBERNATE:
				try {
					Process.spawn_command_line_async("systemctl hibernate");
				} catch (SpawnError e) {
					warning("Failed to hibernate: %s", e.message);
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
	private void set_hibernate() {
		debug("Set Hibernate");
		_option = PMOption.HIBERNATE;
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
}
