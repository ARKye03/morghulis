public class HyprWorkspaces : Gtk.Box {
	private AstalHyprland.Hyprland _hyprland;

	public HyprWorkspaces(AstalHyprland.Hyprland hyprland) {
		this._hyprland = hyprland;
		this.spacing = 5;

		populate_workspace_items();
		update_workspaces();
		setup_workspace_event_handlers();
		setup_workspace_scroll();
	}

	private void populate_workspace_items() {
		for (var i = 1; i <= 9; i++) {
			int workspace_number = i;

			var workspace_button = new WorkspaceItem(
				() => {
				if (!(workspace_number == _hyprland.focused_workspace.id)) {
					_hyprland.dispatch("workspace", workspace_number.to_string());
				}
			},
				() => {
				_hyprland.dispatch("movetoworkspacesilent", workspace_number.to_string());
			},
				() => {
				_hyprland.dispatch("movetoworkspace", workspace_number.to_string());
			}) {
				child = new Gtk.Image.from_icon_name(NavBar.icon_names[i - 1]) {
					pixel_size = 20
				},
			};

			this.append(workspace_button);
		}
	}

	private void setup_workspace_event_handlers() {
		_hyprland.notify["focused-workspace"].connect(update_workspaces);
		_hyprland.client_added.connect(update_workspaces);
		_hyprland.client_removed.connect(update_workspaces);
		_hyprland.client_moved.connect(update_workspaces);
	}

	private void setup_workspace_scroll() {
		var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);

		scroll_controller.scroll.connect((delta_x, delta_y) => {
			string direction = delta_y > 0 ? "e-1" : "e+1";
			_hyprland.dispatch("workspace", direction);
			return true;
		});
		this.add_controller(scroll_controller);
	}

	private void update_workspaces() {
		int index = 0;
		var current = (WorkspaceItem)this.get_first_child();
		var focused_workspace_id = this._hyprland.focused_workspace.id;

		while (current != null) {
			if (index + 1 == focused_workspace_id) {
				current.set_css_classes({ "focused" });
			} else if (workspace_exists(index + 1)) {
				current.set_css_classes({ "occupied" });
			} else {
				current.set_css_classes({ "empty" });
			}
			current = (WorkspaceItem)current.get_next_sibling();
			index++;
		}
	}

	private bool workspace_exists(int workspace_number) {
		var workspace = _hyprland.get_workspace(workspace_number);

		return workspace != null && workspace.clients != null && workspace.clients.length() > 0;
	}
}
