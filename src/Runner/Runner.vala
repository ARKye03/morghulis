public struct Command {
    public string name;
    public string description;
    public Gtk.Widget widget;
}

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Runner.ui")]
public class Runner : MorghulWindow {
    private const string[] PROVIDERS = { "apps", "clip", "files" };

    private GLib.HashTable<string, Command?> _commands;
    private MathCmd _math_cmd;
    private string? _previous_page = null;
    private string _current_provider = "apps";

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

        init_commands();

        commands_stack.notify["visible-child"].connect(on_stack_page_changed);

        this.notify["visible"].connect(() => {
            if (!this.visible) {
                this.entry.text = "";
                _current_provider = "apps";
                commands_stack.visible_child_name = "apps";
            } else {
                this.entry.grab_focus();
                var current = commands_stack.visible_child;
                if (current is ICommand) {
                    ((ICommand) current).on_activate();
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

        // Infer a bare math expression (Spotlight-style), but only from the apps
        // provider so typing on clipboard/files filters those instead.
        if (_current_provider == "apps" && _math_cmd.looks_like_math(input)) {
            commands_stack.visible_child_name = "m";
            _math_cmd.handle_input(input);
            return;
        }

        commands_stack.visible_child_name = _current_provider;

        var current_widget = commands_stack.visible_child;
        if (current_widget is ICommand) {
            ((ICommand) current_widget).handle_input(input);
        }
    }

    [GtkCallback]
    public void launch_first_runner_button() {
        var current_widget = commands_stack.visible_child;

        if (current_widget is IResultProvider) {
            if (((IResultProvider) current_widget).activate_selected()) {
                this.visible = false;
            }
            return;
        }

        if (current_widget is ICommand) {
            ((ICommand) current_widget).on_enter();
        }

        if (current_widget is MathCmd && ((MathCmd) current_widget).has_valid_result) {
            this.visible = false;
        }
    }

    [GtkCallback]
    public bool key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
        var provider = commands_stack.visible_child as IResultProvider;

        switch (keyval) {
            case Gdk.Key.Down:
                if (provider != null) {
                    provider.select_next();
                    return true;
                }
            break;

            case Gdk.Key.Up:
                if (provider != null) {
                    provider.select_prev();
                    return true;
                }
            break;

            case Gdk.Key.Left:
                if (this.entry.text == "") {
                    cycle_provider(-1);
                    return true;
                }
            break;

            case Gdk.Key.Right:
                if (this.entry.text == "") {
                    cycle_provider(1);
                    return true;
                }
            break;
        }

        return false;
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

    private void cycle_provider(int dir) {
        int idx = 0;
        for (int i = 0; i < PROVIDERS.length; i++) {
            if (PROVIDERS[i] == _current_provider) {
                idx = i;
                break;
            }
        }
        idx = ((idx + dir) % PROVIDERS.length + PROVIDERS.length) % PROVIDERS.length;
        _current_provider = PROVIDERS[idx];
        commands_stack.visible_child_name = _current_provider;
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
            description : "View current weather information",
            widget : new WeatherBox()
        };
        _commands.insert(weather_cmd.name, weather_cmd);
        commands_stack.add_named(weather_cmd.widget, weather_cmd.name);

        _math_cmd = new MathCmd();
        Command math_cmd = {
            name : "m",
            description : "Mathematical expression evaluator",
            widget : _math_cmd
        };
        _commands.insert(math_cmd.name, math_cmd);
        commands_stack.add_named(math_cmd.widget, math_cmd.name);

        commands_stack.add_named(new ClipboardCmd(), "clip");
        commands_stack.add_named(new FilesCmd(), "files");

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
                ((ICommand) cmd.widget).handle_input(command_input);
            }
        } else {
            // Unknown command, show help
            commands_stack.visible_child_name = "help";
        }
    }

    private void on_stack_page_changed() {
        if (_previous_page != null) {
            var prev = commands_stack.get_child_by_name(_previous_page);
            if (prev is ICommand) {
                ((ICommand) prev).on_deactivate();
            }
        }

        string current_page = commands_stack.visible_child_name;
        var current = commands_stack.visible_child;

        // The default browsing modes hide the header icon; manually invoked
        // commands (:m, :si, :w) and the clip/files providers show theirs.
        if (current_page == "apps" || current_page == "help") {
            cmd_active = false;
            active_cmd_icon = null;
        } else if (current is ICommand) {
            cmd_active = true;
            active_cmd_icon = ((ICommand) current).icon_name;
        }

        if (current is ICommand) {
            ((ICommand) current).on_activate();
        }

        _previous_page = current_page;
    }
}
