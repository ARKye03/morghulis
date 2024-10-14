[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Gtk.Window, ILayerWindow {

public AstalApps.Apps apps {get; construct set;}

[GtkChild]
private unowned Gtk.ListBox app_list;

[GtkChild]
private unowned Gtk.Entry entry;

[GtkChild]
private unowned Gtk.EventControllerKey key_controller;

private int sort_func (Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
	RunnerButton a = (RunnerButton) la;
	RunnerButton b = (RunnerButton) lb;
	if (a.score == b.score)return b.app.frequency - a.app.frequency;
	return (int)((b.score - a.score) * 100);
}

[GtkCallback]
public void update_list () {
	int i = 0;
	RunnerButton? app = (RunnerButton) this.app_list.get_row_at_index (0);
	while (app != null) {
		app.score = app.app.fuzzy_match (this.entry.text).name;
		app = (RunnerButton) this.app_list.get_row_at_index (++i);
	}
	this.app_list.invalidate_sort ();
}
public void init_layer_properties () {
	GtkLayerShell.init_for_window (this);
	GtkLayerShell.set_layer (this, GtkLayerShell.Layer.OVERLAY);
	GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.ON_DEMAND);

	GtkLayerShell.set_namespace (this, "Runner");
	GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
	GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 10);
}
public void present_layer () {
	this.present ();
	this.visible = false;
}
public string namespace { get; set; }

construct {
	init_layer_properties ();

	this.apps = new AstalApps.Apps ();

	this.app_list.set_sort_func (sort_func);

	this.apps.list.@foreach (app => {
			this.app_list.append (new RunnerButton (app));
		});

	this.key_controller.key_released.connect ((keyval, _) => {
			if (keyval == Gdk.Key.Escape) {
				this.visible = false;
			}
		});
	this.notify["visible"].connect (() => {
			if (!this.visible) {
				this.entry.text = "";
			} else {
				this.entry.grab_focus ();
			}
		});
}
}