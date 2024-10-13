public class Morghulis : Adw.Application {
public static Morghulis instance { get; private set; }
private List<ILayerWindow> windows = new List<ILayerWindow> ();
private bool css_loaded = false;
private Daemon daemon;

public static void main (string[] args) {
	instance = new Morghulis ();
	instance.init_types ();
	instance.run (args);
}

construct {
	application_id = "com.github.arkye03.morghulis";
	flags = ApplicationFlags.HANDLES_COMMAND_LINE;
}
private void init_types () {
	typeof (QuickSettings).ensure ();
	typeof (QuickSettingsButton).ensure ();
}

public override void activate () {
	if (!css_loaded) {
		load_css ();
		css_loaded = true;
	}

	windows.append (new StatusBar (this));
	// windows.append(new Mpris());
	windows.append (new QuickSettings ());

	foreach (var window in windows) {
		window.present_layer ();
	}

	daemon = new Daemon (this);
	daemon.setup_socket_service ();
}

public bool toggle_window (string name) {
	ILayerWindow? w = null;
	foreach (var window in windows) {
		if (window.name.down () == name.down ()) {
			w = window;
			break;
		}
	}
	if (w != null) {
		w.visible = !w.visible;
		return true;
	}
	printerr (@"Window $name not found.\n");
	return false;
}

void load_css () {
	Gtk.CssProvider provider = new Gtk.CssProvider ();
	provider.load_from_resource ("com/github/ARKye03/morghulis/morghulis.css");
	Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider,
						   Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
}

public string process_command (string command) {
	string[] args = command.split (" ");
	string response = "";

	switch (args[0]) {
	case "-T" :
	case "--toggle-window" :
		if (args.length > 1) {
			string window_name = args[1];
			bool result = toggle_window (window_name);
			response = result ? @"$window_name toggled" : @"Failed to toggle $window_name";
		} else {
			response = "Error: Window name not provided";
		}
		break;
	case "-Q":
	case "--quit":
		this.quit ();
		break;
	case "-I":
	case "--inspector":
		response = "Not implemented.";
		break;
	case "-h":
	case "--help":
		response = print_help ();
		break;
	default:
		response = "Unknown command. Use -h to see help.";
		break;
	}
	return response;
}

private string print_help () {
	return "Usage: morghulis [options]\n"
	       + "Options:\n"
	       + "  \033[34m-T|--toggle-window\033[0m \033[32m<window>\033[0m  | Toggle visibility of the specified window\n"
	       + "  \033[34m-Q|--quit\033[0m                    | Quit the application\n"
	       + "  \033[34m-I|--inspector\033[0m               | Open the GTK inspector\n"
	       + "  \033[34m-h|--help\033[0m                    | Show this help message";
}

public override int command_line (ApplicationCommandLine command_line) {
	string[] args = command_line.get_arguments ();

	if (args.length > 1) {
		string command = string.joinv (" ", args[1 : args.length]);
		string response = process_command (command);
		command_line.print (response + "\n");
		return 0;
	}

	activate ();
	return 0;
}
}