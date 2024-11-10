[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/sdSliderBox.ui")]
public class sdSliderBox : Gtk.Box {
    public AstalWp.Endpoint speaker { get; set; }

[GtkChild]
public unowned Gtk.Adjustment vol_adjust;

[GtkCallback]
public string current_volume (double volume) {
	return @"$(Math.round(volume * 100))%";
}
construct {
	speaker = AstalWp.get_default ().audio.default_speaker;
	speaker.bind_property ("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
}
}