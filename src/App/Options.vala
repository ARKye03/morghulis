public struct CommandLineResult {
    public bool should_exit;
    public int exit_code;
    public bool show_version;
    public bool quit_app;
    public bool inspector;
    public string? toggle_window_name;
    public string? request_type;
}

public class CommandLineParser : Object {
    public CommandLineResult parse(string[] args, ApplicationCommandLine command_line) {
        var result = CommandLineResult();

        // Option variables
        bool show_version = false;
        bool quit_app = false;
        bool inspector = false;
        string? toggle_window_name = null;
        string? request_type = null;

        var options = new OptionEntry[] {
            { "version", 'v', OptionFlags.NONE, OptionArg.NONE, out show_version, "Show version information", null },
            { "quit", 'q', OptionFlags.NONE, OptionArg.NONE, out quit_app, "Quit the application", null },
            { "inspector", 'i', OptionFlags.NONE, OptionArg.NONE, out inspector, "Toggle GTK inspector", null },
            { "toggle", 't', OptionFlags.NONE, OptionArg.STRING, out toggle_window_name, "Toggle window visibility", "WINDOW" },
            { "request", 'r', OptionFlags.NONE, OptionArg.STRING, out request_type, "Send custom request", "REQUEST" }
        };

        var context = new OptionContext("- Morghulis Desktop Shell");
        context.set_summary("A GTK4 desktop shell built with Vala");
        context.set_description("Examples:\n\tmorghulis -t runner\t# Toggle runner window\n\tmorghulis -r change_volume\t# Trigger volume change OSD");
        context.set_help_enabled(false);
        context.add_main_entries(options, null);

        try {
            unowned string[] args_unowned = args;
            context.parse(ref args_unowned);
        } catch (OptionError e) {
            command_line.printerr("Option parsing failed: %s\n", e.message);
            result.should_exit = true;
            result.exit_code = 1;
            return result;
        }

        result.show_version = show_version;
        result.quit_app = quit_app;
        result.inspector = inspector;
        result.toggle_window_name = toggle_window_name;
        result.request_type = request_type;

        return result;
    }
}

public class HelpDisplay : Object {
    public static bool should_show_help(string[] args) {
        foreach (string arg in args) {
            if (arg == "--help" || arg == "-h" || arg == "-?") {
                return true;
            }
        }
        return false;
    }

    public static void show_help(ApplicationCommandLine command_line) {
        command_line.print("\033[1;36mUsage:\033[0m\n");
        command_line.print("  \033[1;32mmorghulis\033[0m \033[33m[OPTION…]\033[0m - \033[1;35mMorghulis Desktop Shell\033[0m\n\n");
        command_line.print("\033[1;34mA GTK4 desktop shell built with Vala\033[0m\n\n");
        command_line.print("\033[1;33mHelp Options:\033[0m\n");
        command_line.print("  \033[32m-?, --help\033[0m                Show help options\n\n");
        command_line.print("\033[1;33mApplication Options:\033[0m\n");
        command_line.print("  \033[32m-v, --version\033[0m             Show version information\n");
        command_line.print("  \033[32m-q, --quit\033[0m                Quit the application\n");
        command_line.print("  \033[32m-i, --inspector\033[0m           Toggle GTK inspector\n");
        command_line.print("  \033[32m-t, --toggle=\033[36mWINDOW\033[0m       Toggle window visibility\n");
        command_line.print("  \033[32m-r, --request=\033[36mREQUEST\033[0m     Send custom request\n\n");
        command_line.print("\033[1;33mExamples:\033[0m\n");
        command_line.print("\t\033[32mmorghulis -t runner\033[0m\t\033[90m# Toggle runner window\033[0m\n");
        command_line.print("\t\033[32mmorghulis -r change_volume\033[0m\t\033[90m# Trigger volume change OSD\033[0m\n");
    }
}
