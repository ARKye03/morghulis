public struct Command {
    public string name;
    public string description;
    public Gtk.Widget widget;
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Runner.ui")]
public class Runner : MorghulWindow {
    private GLib.HashTable<string, Command?> _commands;
    private AppsCmd _apps_cmd;
    private string? _previous_page = null;

    public static Runner instance { get; private set; }

    public bool cmd_active { get; private set; }
    public string? active_cmd_icon { get; private set; }

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

        _apps_cmd = new AppsCmd();
        init_commands();

        commands_stack.notify["visible-child"].connect(on_stack_page_changed);

        this.notify["visible"].connect(() => {
            if (!this.visible) {
                this.entry.text = "";
                commands_stack.visible_child_name = "apps";
            } else {
                this.entry.grab_focus();
                if (commands_stack.visible_child_name == "apps") {
                    if (_apps_cmd is ICommand) {
                        ((ICommand)_apps_cmd).on_activate();
                    }
                }
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
        if (_previous_page != null) {
            if (_previous_page == "apps") {
                if (_apps_cmd is ICommand) {
                    ((ICommand)_apps_cmd).on_deactivate();
                }
            } else {
                Command? prev_cmd = _commands.lookup(_previous_page);
                if (prev_cmd != null && prev_cmd.widget is ICommand) {
                    ((ICommand)prev_cmd.widget).on_deactivate();
                }
            }
        }

        string current_page = commands_stack.visible_child_name;

        // Update cmd_active and active_cmd_icon based on current page
        if (current_page == "apps" || current_page == "help") {
            cmd_active = false;
            active_cmd_icon = null;
        } else {
            // This is a manually invoked command (like :m, :si, :w)
            Command? current_cmd = _commands.lookup(current_page);
            if (current_cmd != null && current_cmd.widget is ICommand) {
                cmd_active = true;
                active_cmd_icon = ((ICommand)current_cmd.widget).icon_name;
            }
        }

        if (current_page == "apps") {
            if (_apps_cmd is ICommand) {
                ((ICommand)_apps_cmd).on_activate();
            }
        } else {
            Command? current_cmd = _commands.lookup(current_page);
            if (current_cmd != null && current_cmd.widget is ICommand) {
                ((ICommand)current_cmd.widget).on_activate();
            }
        }

        _previous_page = current_page;
    }
}
