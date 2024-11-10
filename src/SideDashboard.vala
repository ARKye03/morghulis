using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/SideDashboard.ui")]
public class SideDashboard : Astal.Window {
public AstalWp.Endpoint speaker { get; set; }

public SideDashboard () {
	Object (
		anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
		);
}

construct {
	speaker = AstalWp.get_default ().audio.default_speaker;


	speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

	uptime ();
}

private static string stdout;
private void uptime () {
	update_uptime ();
	GLib.Timeout.add (60000, () => {
			update_uptime ();
			return true;
		});
}
private void update_uptime () {
	try {
		Process.spawn_command_line_sync ("uptime -p", out stdout);
	} catch (Error e) {
		warning ("Failed to get uptime: %s", e.message);
	}
	uptime_label.label = stdout.strip ();
}

[GtkChild]
public unowned Gtk.Adjustment vol_adjust;

[GtkCallback]
public string current_volume (double volume) {
	return @"$(Math.round(volume * 100))%";
}

[GtkChild]
public unowned Gtk.Label uptime_label;

}
