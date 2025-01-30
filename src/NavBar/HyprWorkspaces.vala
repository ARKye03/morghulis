using AstalHyprland;
public class HyprWorkspaces : Gtk.Box {
	private List<Gtk.Button> workspace_buttons;
	private AstalHyprland.Hyprland hyprland { get; set; }
	private int focused_workspace_id { get; set; }

	// Workspace Icons
	private string[] wicons = {
		" ", " ", "󰨞 ",
		" ", " ", "󰭹 ",
		" ", " ", "󰊖 ",
		" ",
	};

	public HyprWorkspaces(AstalHyprland.Hyprland hyprland) {
		this.hyprland = hyprland;
		workspace_buttons = new List<Gtk.Button>();
		spacing = 5;
		this.hyprland.bind_property("focused-workspace", this, "focused-workspace-id", BindingFlags.SYNC_CREATE, (_, src, ref trgt) => {
			var workspace = src as AstalHyprland.Workspace;
			if (workspace != null) {
				trgt = workspace.id;
			}
			return true;
		});

		for (var i = 1; i <= 10; i++) {
			var workspace_button = new Gtk.Button.with_label(wicons[i - 1]);
			connect_button_to_workspace(workspace_button, i);
			workspace_button.valign = Gtk.Align.CENTER;
			workspace_button.halign = Gtk.Align.CENTER;
			this.append(workspace_button);
			workspace_buttons.append(workspace_button);
		}
		update_workspaces();
		setup_workspace_event_handlers();
		setup_workspace_scroll();
	}

	private void setup_workspace_event_handlers() {
		hyprland.notify["focused-workspace"].connect(update_workspaces);
		hyprland.client_added.connect(update_workspaces);
		hyprland.client_removed.connect(update_workspaces);
		hyprland.client_moved.connect(update_workspaces);
	}

	private void setup_workspace_scroll() {
		var scroll = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);

		scroll.scroll.connect((delta_x, delta_y) => {
			string direction = delta_y > 0 ? "e-1" : "e+1";
			hyprland.dispatch("workspace", direction);
			return true;
		});
		this.add_controller(scroll);
	}

	private void update_workspaces() {
		int index = 0;

		workspace_buttons.foreach((button) => {
			if (button != null) {
				if (index + 1 == focused_workspace_id) {
					button.set_css_classes(new string[] { "focused" });
				} else if (workspace_exists(index + 1)) {
					button.set_css_classes(new string[] { "occupied" });
				} else {
					button.set_css_classes(new string[] { "empty" });
				}
			}
			index++;
		});
	}

	private void connect_button_to_workspace(Gtk.Button button, int workspace_number) {
		var middle_click = new Gtk.GestureClick();

		middle_click.set_button(2);
		middle_click.pressed.connect(() => {
			hyprland.dispatch("movetoworkspacesilent", workspace_number.to_string());
		});
		button.add_controller(middle_click);
		button.clicked.connect(() => {
			hyprland.dispatch("workspace", workspace_number.to_string());
		});
	}

	private bool workspace_exists(int workspace_number) {
		var workspace = hyprland.get_workspace(workspace_number);

		return workspace != null && workspace.clients != null && workspace.clients.length() > 0;
	}
}
