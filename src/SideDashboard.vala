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
}

[GtkChild]
public unowned Gtk.Adjustment vol_adjust;

[GtkCallback]
public string current_volume (double volume) {
	return @"$(Math.round(volume * 100))%";
}
}
