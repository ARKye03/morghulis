using AstalHyprland;
using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/StatusBar.ui")]
public class StatusBar : Gtk.Window, ILayerWindow {
// Properties
private AstalMpris.Mpris mpris { get; set; }
private AstalHyprland.Hyprland hyprland { get; set; }
private List<Gtk.Button> workspace_buttons = new List<Gtk.Button> ();

public AstalMpris.Player mpd { get; set; }
public AstalWp.Endpoint speaker { get; set; }

public string namespace { get; set; }

// UI Elements
[GtkChild]
public unowned Gtk.Box workspaces;

[GtkChild]
public unowned Gtk.Button apps_button;

[GtkChild]
public unowned Gtk.Label client_label;

[GtkChild]
public unowned Gtk.Label clock;

[GtkChild]
public unowned Gtk.Button power_button;

// Workspace icons
private static string[] wicons = {
	" ", " ", "󰨞 ",
	" ", " ", "󰭹 ",
	" ", " ", "󰊖 ",
	" ",
};

public StatusBar (Gtk.Application app) {
	Object (application: app);
	initialize_components ();
	setup_event_handlers ();
}

// Initialization methods
private void initialize_components () {
	speaker = AstalWp.get_default ().audio.default_speaker;
	mpris = AstalMpris.Mpris.get_default ();
	hyprland = AstalHyprland.Hyprland.get_default ();

	init_layer_properties ();
	this.name = "StatusBar";
	this.namespace = "StatusBar";

	init_workspaces ();
	init_clock ();
}

private void setup_event_handlers () {
	power_button.clicked.connect (() => {
			Morghulis.instance.toggle_window ("QuickSettings");
		});

	apps_button.clicked.connect (() => {
			Morghulis.instance.toggle_window ("VRunner");
		});

	hyprland.notify["focused-client"].connect (() => {
			focused_client ();
		});
}

// Layer Shell methods
public void init_layer_properties () {
	GtkLayerShell.init_for_window (this);
	GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);

	GtkLayerShell.set_namespace (this, "StatusBar");
	GtkLayerShell.auto_exclusive_zone_enable (this);
}

public void present_layer () {
	this.present ();
}

// Client focus method
private void focused_client () {
	if (hyprland.focused_client != null) {
		client_label.label = hyprland.focused_client.title;
	}
}

// Clock methods
private void update_clock () {
	var clock_time = new DateTime.now_local ();
	clock.label = clock_time.format ("%I:%M %p %b %e");
}

private void init_clock () {
	update_clock ();
	GLib.Timeout.add (30000, () => {
			update_clock ();
			return true;
		});
}

// Workspace methods
private static int focused_workspace_id { get; private set; }

private void init_workspaces () {
	for (var i = 1; i <= 10; i++) {
		var workspace_button = new Gtk.Button.with_label (wicons[i - 1]);
		connect_button_to_workspace (workspace_button, i);
		workspace_button.valign = Gtk.Align.CENTER;
		workspace_button.halign = Gtk.Align.CENTER;
		workspaces.append (workspace_button);
		workspace_buttons.append (workspace_button);
	}
	update_workspaces ();
	setup_workspace_event_handlers ();
	setup_workspace_scroll ();
}

private void setup_workspace_event_handlers () {
	hyprland.notify["focused-workspace"].connect (update_workspaces);
	hyprland.client_added.connect (update_workspaces);
	hyprland.client_removed.connect (update_workspaces);
	hyprland.client_moved.connect (update_workspaces);
}

private void setup_workspace_scroll () {
	var scroll = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
	scroll.scroll.connect ((delta_x, delta_y) => {
			string direction = delta_y > 0 ? "e-1" : "e+1";
			hyprland.dispatch ("workspace", direction);
			return true;
		});
	workspaces.add_controller (scroll);
}

private void update_workspaces () {
	focused_workspace_id = hyprland.focused_workspace.id;

	int index = 0;
	workspace_buttons.foreach ((button) => {
			if (button != null) {
				if (index + 1 == focused_workspace_id) {
					button.set_css_classes (new string[] { "focused" });
				} else if (workspace_has_windows (index + 1)) {
					button.set_css_classes (new string[] { "has-windows" });
				} else {
					button.set_css_classes (new string[] { "empty" });
				}
			}
			index++;
		});
}

private void connect_button_to_workspace (Gtk.Button button, int workspace_number) {
	var middle_click = new Gtk.GestureClick ();
	middle_click.set_button (2);
	middle_click.pressed.connect (() => {
			hyprland.dispatch ("movetoworkspacesilent", workspace_number.to_string ());
		});
	button.add_controller (middle_click);
	button.clicked.connect (() => {
			hyprland.dispatch ("workspace", workspace_number.to_string ());
		});
}

private bool workspace_has_windows (int workspace_number) {
	var window_count = hyprland.get_workspace (workspace_number).clients.length ();
	return window_count > 0;
}
}
