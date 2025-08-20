[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

// Command struct for simple command management
public struct Command {
	public string name;
	public string description;
	public Gtk.Widget widget;
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Runner.ui")]
public class Runner : Astal.Window {
	private GLib.HashTable<string, Command?> _commands;
	private uint _sysinfo_update_timeout = 0;
	private AppsCmd apps_cmd;
	private string? _previous_page = null;

	public static Runner instance { get; private set; }

	[GtkChild]
	private unowned Gtk.Entry entry;

	[GtkChild]
	private unowned Gtk.Stack commands_stack;

	construct {
		if (instance == null) {
			instance = this;
		} else {
			this.destroy();
		}

		apps_cmd = new AppsCmd();
		init_commands();

		// Connect to stack page changes to handle command activation
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

		// Notify the current command about input changes
		var current_widget = commands_stack.visible_child;
		if (current_widget is ICommand) {
			((ICommand)current_widget).handle_input(input);
		}
	}

	[GtkCallback]
	public void launch_first_runner_button() {
		var current_widget = commands_stack.visible_child;
		if (current_widget is ICommand) {
			((ICommand)current_widget).on_enter();
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

		Command math_cmd = {
			name : "m",
			description : "Mathematical expression evaluator",
			widget : new MathCmd()
		};
		_commands.insert(math_cmd.name, math_cmd);
		commands_stack.add_named(math_cmd.widget, math_cmd.name);

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
			commands_stack.visible_child_name = command_name;

			// If the command can handle input and has arguments, pass them
			if (cmd.widget is ICommand && args.length > 0) {
				string command_input = string.joinv(" ", args);
				((ICommand)cmd.widget).handle_input(command_input);
			}
		} else {
			// Unknown command, show help
			commands_stack.visible_child_name = "help";
		}
	}

	private void on_stack_page_changed() {
		// Handle deactivation of previous command
		if (_previous_page != null) {
			Command? prev_cmd = _commands.lookup(_previous_page);
			if (prev_cmd != null && prev_cmd.widget is ICommand) {
				((ICommand)prev_cmd.widget).on_deactivate();
			}
		}

		// Stop any existing sysinfo updates (legacy support)
		if (_sysinfo_update_timeout > 0) {
			Source.remove(_sysinfo_update_timeout);
			_sysinfo_update_timeout = 0;
		}

		// Handle activation of current command
		string current_page = commands_stack.visible_child_name;
		Command? current_cmd = _commands.lookup(current_page);
		if (current_cmd != null && current_cmd.widget is ICommand) {
			((ICommand)current_cmd.widget).on_activate();
		}

		// Legacy sysinfo special handling (to be removed when SysInfo implements ICommand)
		if (current_page == "si") {
			var sysinfo_cmd = _commands.lookup("si");
			if (sysinfo_cmd != null && sysinfo_cmd.widget is SysInfo) {
				var sysinfo = (SysInfo)sysinfo_cmd.widget;
				sysinfo.update_all();
				_sysinfo_update_timeout = Timeout.add_seconds(3, () => {
					sysinfo.update_all();
					return true;
				});
			}
		}

		_previous_page = current_page;
	}

	~Runner() {
		if (_sysinfo_update_timeout > 0) {
			Source.remove(_sysinfo_update_timeout);
		}
	}
}
