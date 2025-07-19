[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

// Command struct for simple command management
public struct Command {
	public string name;
	public string description;
	public Gtk.Widget widget;
}

// Helper function to create weather widget
private Gtk.Widget create_weather_widget() {
	var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
	box.margin_top = box.margin_bottom = 16;
	box.margin_start = box.margin_end = 16;

	var title = new Gtk.Label("Weather");
	title.add_css_class("title-2");
	box.append(title);

	var weather_info = new Gtk.Label("🌤️ 22°C - Partly Cloudy\n📍 Current Location\n💨 Wind: 5 km/h");
	weather_info.add_css_class("body");
	weather_info.justify = Gtk.Justification.CENTER;
	box.append(weather_info);

	var note = new Gtk.Label("(This is a placeholder - integrate with weather API)");
	note.add_css_class("caption");
	note.add_css_class("dim-label");
	box.append(note);

	return box;
}

// Helper function to create math widget
private Gtk.Widget create_math_widget() {
	var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
	box.margin_top = box.margin_bottom = 12;
	box.margin_start = box.margin_end = 12;

	var result_label = new Gtk.Label("0");
	result_label.justify = Gtk.Justification.LEFT;
	result_label.halign = Gtk.Align.START;
	result_label.valign = Gtk.Align.CENTER;
	result_label.add_css_class("title-2");
	result_label.add_css_class("numeric-result");

	box.append(result_label);
	box.set_data("result_label", result_label);

	return box;
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Astal.Window {
	public static Runner instance { get; private set; }
	public AstalApps.Apps apps { get; construct set; }

	[GtkChild]
	private unowned Gtk.Entry entry;

	[GtkChild]
	private unowned Gtk.ListBox app_list;

	[GtkChild]
	private unowned Gtk.Stack commands_stack;

	// Command system using struct
	private GLib.HashTable<string, Command?> commands;
	private Gtk.Widget? math_widget = null;

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
		return
			text.contains("+") ||
			text.contains("-") ||
			text.contains("*") ||
			text.contains("/") ||
			text.contains("^");
	}

	[GtkCallback]
	public void update_list() {
		string input = this.entry.text.strip();

		// Handle commands (starts with ':')
		if (is_command(input)) {
			handle_command(input);
			return;
		}

		// Handle math expressions
		if (looks_like_math(input)) {
			string error;
			double result = mpars_evaluate(input, out error);

			if (error == null) {
				// Update the math widget with the result
				var result_label = math_widget.get_data<Gtk.Label>("result_label");
				if (result_label != null) {
					result_label.set_text(result.to_string());
				}
				commands_stack.visible_child_name = "math";
				return;
			}
		}

		// Default to showing apps
		commands_stack.visible_child_name = "apps";

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
		RunnerButton selected_button = (RunnerButton)this.app_list.get_first_child();

		if (selected_button != null && commands_stack.visible_child_name == "apps") {
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

	private void init_commands() {
		commands = new GLib.HashTable<string, Command?>(str_hash, str_equal);

		// Create and register system info command
		var sysinfo_widget = new SysInfo();
		Command sysinfo_cmd = {
			name: "si",
			description : "System Information Dashboard",
			widget : sysinfo_widget
		};
		commands.insert("si", sysinfo_cmd);
		commands_stack.add_named(sysinfo_widget, "si");

		// Create and register weather command
		var weather_widget = create_weather_widget();
		Command weather_cmd = {
			name : "w",
			description : "Weather information (placeholder)",
			widget : weather_widget
		};
		commands.insert("w", weather_cmd);
		commands_stack.add_named(weather_widget, "w");

		// Create and register math command
		math_widget = create_math_widget();
		Command math_cmd = {
			name : "math",
			description : "Mathematical expression evaluator",
			widget : math_widget
		};
		commands.insert("math", math_cmd);
		commands_stack.add_named(math_widget, "math");

		// Create and register help command
		var help_widget = new HelpCmd(commands.get_values());
		Command help_cmd = {
			name : "help",
			description : "Show available commands",
			widget : help_widget
		};
		commands.insert("help", help_cmd);
		commands_stack.add_named(help_widget, "help");
	}

	private bool is_command(string text) {
		return text.length > 1 && text[0] == ':';
	}

	private void handle_command(string input) {
		// Remove the ':' prefix
		string command_text = input.substring(1);
		string[] parts = command_text.split(" ");

		if (parts.length == 0) {
			commands_stack.visible_child_name = "apps";
			return;
		}

		string command_name = parts[0];
		string[] args = parts[1 : parts.length];

		Command? cmd = commands.lookup(command_name);
		if (cmd != null) {
			// Show the command's widget in the stack
			commands_stack.visible_child_name = command_name;
		} else {
			commands_stack.visible_child_name = "help";
		}
	}

	construct {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		this.apps = new AstalApps.Apps();
		init_commands();

		this.app_list.set_sort_func(sort_func);
		this.app_list.set_filter_func(filter_func);

		this.apps.list.@foreach(app => {
			this.app_list.append(new RunnerButton(app));
		});

		this.notify["visible"].connect(() => {
			if (!this.visible) {
				this.entry.text = "";
				// Reset to apps view when hiding
				commands_stack.visible_child_name = "apps";
			} else {
				this.entry.grab_focus();
			}
		});
		this.margin_top = Morghulis.primary_monitor.get_geometry().height / 4;
	}
}
