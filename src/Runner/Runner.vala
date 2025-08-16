[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

// Command struct for simple command management
public struct Command {
	public string name;
	public string description;
	public Gtk.Widget widget;
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner.ui")]
public class Runner : Astal.Window {
	private FileMonitor _data_dirs_applications;
	private GLib.HashTable<string, Command?> _commands;
	private uint _sysinfo_update_timeout = 0;

	public static Runner instance { get; private set; }
	public AstalApps.Apps apps { get; construct set; }

	[GtkChild]
	private unowned Gtk.Entry entry;

	[GtkChild]
	private unowned Gtk.ListBox app_list;

	[GtkChild]
	private unowned Gtk.Stack commands_stack;

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

		// Connect to stack page changes to handle sysinfo updates
		commands_stack.notify["visible-child"].connect(on_stack_page_changed);

		this.notify["visible"].connect(() => {
			if (!this.visible) {
				this.entry.text = "";
				// Stop any running updates when hiding
				if (_sysinfo_update_timeout > 0) {
					Source.remove(_sysinfo_update_timeout);
					_sysinfo_update_timeout = 0;
				}
				// Reset to apps view when hiding
				commands_stack.visible_child_name = "apps";
			} else {
				this.entry.grab_focus();
			}
		});
		this.margin_top = Morghulis.primary_monitor.get_geometry().height / 4;
	}

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
		string input = this.entry.text.strip();

		// Handle commands (starts with ':')
		if (is_command(input)) {
			handle_command(input);
			return;
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
	public void key_released(uint keyval, uint _, Gdk.ModifierType state) {
		if (keyval == Gdk.Key.Escape) {
			this.visible = false;
		} else if (keyval == Gdk.Key.c && (state & Gdk.ModifierType.CONTROL_MASK) != 0) {
			this.entry.text = "";
			this.entry.grab_focus();
		}
	}

	private void init_commands() {
		_commands = new GLib.HashTable<string, Command?>(str_hash, str_equal);

		Command sysinfo_cmd = {
			name : "si",
			description : "System Information Dashboard",
			widget : new SysInfo()
		};
		_commands.insert(sysinfo_cmd.name, sysinfo_cmd);
		commands_stack.add_named(sysinfo_cmd.widget, sysinfo_cmd.name);

		Command weather_cmd = {
			name : "w",
			description : "Weather information (placeholder)",
			widget : new WeatherBox()
		};
		_commands.insert(weather_cmd.name, weather_cmd);
		commands_stack.add_named(weather_cmd.widget, weather_cmd.name);

		// Create and register math command
		var math_cmd_widget = new MathCmd();
		Command math_cmd = {
			name : "m",
			description : "Mathematical expression evaluator",
			widget : math_cmd_widget
		};
		_commands.insert(math_cmd.name, math_cmd);
		commands_stack.add_named(math_cmd_widget, math_cmd.name);

		commands_stack.add_named(new HelpCmd(_commands.get_values()), "help");
	}

	private bool is_command(string text) {
		return text.length >= 1 && text[0] == ':';
	}

	private void handle_command(string input) {
		string command_text = input.substring(1).strip();

		if (command_text == "") {
			commands_stack.visible_child_name = "help";
			return;
		}

		string[] parts = command_text.split(" ");
		string command_name = parts[0];
		string[] args = parts[1 : parts.length];

		Command? cmd = _commands.lookup(command_name);
		if (cmd != null) {
			// Special handling for math command with arguments
			if (command_name == "m" && cmd.widget is MathCmd) {
				var math_cmd = (MathCmd)cmd.widget;
				if (args.length > 0) {
					// Join all arguments as the expression
					string expression = string.joinv(" ", args);
					math_cmd.evaluate_expression(expression);
				} else {
					// No expression provided, show placeholder
					math_cmd.reset();
				}
			}

			commands_stack.visible_child_name = command_name;
		} else {
			// Unknown command, show help
			commands_stack.visible_child_name = "help";
		}
	}

	private void on_stack_page_changed() {
		// Stop any existing sysinfo updates
		if (_sysinfo_update_timeout > 0) {
			Source.remove(_sysinfo_update_timeout);
			_sysinfo_update_timeout = 0;
		}

		// If system info page is now visible, start updates
		if (commands_stack.visible_child_name == "si") {
			var sysinfo_cmd = _commands.lookup("si");
			if (sysinfo_cmd != null && sysinfo_cmd.widget is SysInfo) {
				var sysinfo = (SysInfo)sysinfo_cmd.widget;

				// Update immediately
				sysinfo.update_all();

				// Start periodic updates every 3 seconds
				_sysinfo_update_timeout = Timeout.add_seconds(3, () => {
					sysinfo.update_all();
					return true;
				});
			}
		}
	}
}
