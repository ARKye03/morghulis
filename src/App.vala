// This file is kept for backward compatibility
// The main application logic has been moved to lib/App/Application.vala

// Alias for accessing the new application instance
public class Morghulis {
	public static MorghulisApplication instance {
		get { return MorghulisApplication.instance; }
	}

	public static GLib.Settings gsettings {
		get { return MorghulisApplication.gsettings; }
	}

	public static Gdk.Display? display {
		get { return MorghulisApplication.display; }
	}

	public static Gdk.Monitor? primary_monitor {
		get { return MorghulisApplication.primary_monitor; }
	}

	public static string clock_format {
		get { return MorghulisApplication.clock_format; }
	}

	public static string user_name {
		get { return MorghulisApplication.user_name; }
	}

	public string uptime {
		get { return MorghulisApplication.instance.uptime; }
	}
}
