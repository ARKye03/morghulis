using GtkLayerShell;

[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Astal.Window {
	public AstalApps.Apps apps { get; construct set; }

	[GtkChild]
	private unowned Gtk.Entry entry;

	[GtkChild]
	private unowned Adw.Bin math_bin;

	[GtkChild]
	private unowned Gtk.Label math_label;

	[GtkChild]
	private unowned Gtk.ListBox app_list;
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

	private bool looks_like_math(string text) {
		return text[0] != ':' &&
			   (text.contains("+") ||
				text.contains("-") ||
				text.contains("*") ||
				text.contains("/") ||
				text.contains("^"));
	}

	[GtkCallback]
	public void update_list() {
		string input = this.entry.text.strip();

		// Handle math expressions
		if (looks_like_math(input)) {
			string error;
			double result = mpars_evaluate(input, out error);

			if (error == null) {
				math_label.set_text("%s = %g".printf(input, result));
				math_bin.set_visible(true);
				return;
			} else {
				math_bin.set_visible(false);
			}
			app_list.set_visible(false);
			return;
		} else {
			app_list.set_visible(true);
			math_bin.set_visible(false);
		}

		// Update app filtering
		var child = this.app_list.get_first_child();
		while (child != null) {
			if (child is RunnerButton) {
				var app = (RunnerButton)child;
				app.score = apps.fuzzy_score(input, app.app);
			}
			child = child.get_next_sibling();
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
		this.margin_top = Morghulis.primary_monitor.get_geometry().height / 4;
	}
}
