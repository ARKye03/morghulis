[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

// Command handler interface
public interface CommandHandler : Object {
	public abstract string get_name();
	public abstract string get_description();

	public abstract Gtk.Widget? execute(string[] args);
}

public class WeatherCommand : Object, CommandHandler {
	public string get_name() {
		return "w";
	}

	public string get_description() {
		return "Weather information (placeholder)";
	}

	public Gtk.Widget? execute(string[] args) {
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

	// Command system
	private GLib.HashTable<string, CommandHandler> commands;
	private Gtk.Widget? current_command_widget = null;

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
		//  if (looks_like_math(input)) {
		//  	string error;
		//  	double result = mpars_evaluate(input, out error);

		//  	if (error == null) {
		//  		math_label.set_text(result.to_string());
		//  		app_list.visible = false;
		//  command_bin.visible = false;
		//  		return;
		//  	} else {
		//  	}
		//  }

		// Default to app filtering
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
		commands = new GLib.HashTable<string, CommandHandler>(str_hash, str_equal);

		// Register built-in commands
		var sysinfo_cmd = new SysInfoCommand();
		commands.insert(sysinfo_cmd.get_name(), sysinfo_cmd);
		commands_stack.add_child(new HelpCmd(commands.get_values()));

		var weather_cmd = new WeatherCommand();
		commands.insert(weather_cmd.get_name(), weather_cmd);

		//  var bluetooth_cmd = new BluetoothCommand();
		//  commands.insert(bluetooth_cmd.get_name(), bluetooth_cmd);

		//  var calc_cmd = new CalculatorCommand();
		//  commands.insert(calc_cmd.get_name(), calc_cmd);

		// Help command should be registered last so it has access to all commands
		var help_cmd = new HelpCommand(commands);
		commands.insert(help_cmd.get_name(), help_cmd);
	}

	private bool is_command(string text) {
		return text.length > 1 && text[0] == ':';
	}

	private void handle_command(string input) {
		// Remove the ':' prefix
		string command_text = input.substring(1);
		string[] parts = command_text.split(" ");

		if (parts.length == 0) {
			//  command_bin.visible = false;
			return;
		}

		string command_name = parts[0];
		string[] args = parts[1 : parts.length];

		CommandHandler? handler = commands.lookup(command_name);
		if (handler != null) {
			// Clear previous command widget
			if (current_command_widget != null) {
				//  command_bin.child = null;
				current_command_widget = null;
			}

			// Execute command and show result
			current_command_widget = handler.execute(args);
			if (current_command_widget != null) {
				//  command_bin.child = current_command_widget;
				//  command_bin.visible = true;
				app_list.visible = false;
				return;
			}
		}

		// Command not found or failed
		//  command_bin.visible = false;
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
				// Clear command widget when hiding
				if (current_command_widget != null) {
					//  command_bin.child = null;
					current_command_widget = null;
					//  command_bin.visible = false;
				}
			} else {
				this.entry.grab_focus();
			}
		});
		this.margin_top = Morghulis.primary_monitor.get_geometry().height / 4;
	}
}
