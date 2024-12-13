using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Astal.Window {
	public AstalApps.Apps apps { get; construct set; }

	[GtkChild]
	private unowned Gtk.ListBox app_list;

	[GtkChild]
	private unowned Gtk.Entry entry;

	private int sort_func(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
		RunnerButton a = (RunnerButton)la;
		RunnerButton b = (RunnerButton)lb;

		if (a.score == b.score) {
			return b.app.frequency - a.app.frequency;
		}
		return (a.score > b.score) ? -1 : 1;
	}

	private bool filter_func(Gtk.ListBoxRow row) {
		RunnerButton app = (RunnerButton)row;

		return app.score >= 0;
	}

	[GtkCallback]
	public void update_list() {
		int i = 0;
		RunnerButton? app = (RunnerButton)this.app_list.get_row_at_index(0);

		while (app != null) {
			app.score = apps.fuzzy_score(this.entry.text, app.app);
			app = (RunnerButton)this.app_list.get_row_at_index(++i);
		}
		this.app_list.invalidate_sort();
		this.app_list.invalidate_filter();
	}

	[GtkCallback]
	public void launch_first_runner_button() {
		RunnerButton selected_button = (RunnerButton)this.app_list.get_row_at_index(0);

		if (selected_button != null) {
			selected_button.activate();
			this.visible = false;
		}
	}

	[GtkCallback]
	public void key_released(uint keyval) {
		if (keyval == Gdk.Key.Escape) {
			this.visible = false;
		}
	}

	construct {
		this.apps = new AstalApps.Apps();

		this.app_list.set_sort_func(sort_func);
		this.app_list.set_filter_func(filter_func);

		this.apps.list.@foreach(app => {
			this.app_list.append(new RunnerButton(app));
		});

		this.notify["visible"].connect(() => {
			if (!this.visible) {
				this.entry.text = "";
			} else {
				this.entry.grab_focus();
			}
		});
	}
}
