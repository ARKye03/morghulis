public class Morghulis : Adw.Application {
    public static Morghulis Instance { get; private set; }
    private List<ILayerWindow> windows = new List<ILayerWindow> ();
    private bool _cssLoaded = false;
    private Daemon daemon;

    public static void main(string[] args) {
        Instance = new Morghulis();
        Instance.run(args);
    }

    construct {
        application_id = "com.github.arkye03.morghulis";
        flags = ApplicationFlags.HANDLES_COMMAND_LINE;
    }

    public override void activate() {
        if (!_cssLoaded) {
            LoadCss();
            _cssLoaded = true;
        }

        windows.append(new StatusBar(this));
        windows.append(new Mpris());

        foreach (var window in windows) {
            window.present_layer();
        }

        daemon = new Daemon(this);
        daemon.setup_socket_service();
    }

    public bool ToggleWindow(string name) {
        ILayerWindow? w = null;
        foreach (var window in windows) {
            if (window.name.down() == name.down()) {
                w = window;
                break;
            }
        }
        if (w != null) {
            w.visible = !w.visible;
            return true;
        }
        printerr(@"Window $name not found.\n");
        return false;
    }

    void LoadCss() {
        Gtk.CssProvider provider = new Gtk.CssProvider();
        provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public string process_command(string command) {
        string[] args = command.split(" ");
        string response;

        switch (args[0]) {
        case "-T" :
            if (args.length > 1) {
                string window_name = args[1];
                bool result = ToggleWindow(window_name);
                response = result ? @"$window_name toggled" : @"Failed to toggle $window_name";
            } else {
                response = "Error: Window name not provided";
            }
            break;
        default:
            response = "Unknown command. Use -T <window_name> to toggle a window.";
            break;
        }

        return response;
    }

    public override int command_line(ApplicationCommandLine command_line) {
        string[] args = command_line.get_arguments();

        if (args.length > 1) {
            string command = string.joinv(" ", args[1 : args.length]);
            string response = process_command(command);
            command_line.print(response + "\n");
            return 0;
        }

        activate();
        return 0;
    }
}