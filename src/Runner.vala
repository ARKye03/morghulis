using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Gtk.Window, ILayerWindow {

public AstalApps.Apps apps {get; construct set;}

[GtkChild]
private unowned Gtk.ListBox app_list;

[GtkChild]
private unowned Gtk.Entry entry;

private int sort_func (Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
	RunnerButton a = (RunnerButton) la;
	RunnerButton b = (RunnerButton) lb;
	if (a.score == b.score) return b.app.frequency - a.app.frequency;
	return (a.score > b.score) ? -1 : 1;
}

private bool filter_func (Gtk.ListBoxRow row) {
	RunnerButton app = (RunnerButton) row;
	return app.score >= 0;
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
	this.app_list.invalidate_filter ();
}
[GtkCallback]
public void launch_first_runner_button () {
	RunnerButton selectedButton = (RunnerButton)this.app_list.get_row_at_index(0);
	if (selectedButton != null) {
		selectedButton.activate();
		this.visible = false;
	}
}

[GtkCallback]
public void key_released (uint keyval) {
	if (keyval == Gdk.Key.Escape) {
		this.visible = false;
	}
}

public void init_layer_properties () {
	init_for_window (this);
	set_layer (this, Layer.TOP);
	set_keyboard_mode (this, KeyboardMode.ON_DEMAND);

	set_namespace (this, "Runner");
	set_anchor (this, Edge.BOTTOM, true);
	set_margin (this, Edge.BOTTOM, 10);
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
	this.app_list.set_filter_func (filter_func);

	this.apps.list.@foreach (app => {
			this.app_list.append (new RunnerButton (app));
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