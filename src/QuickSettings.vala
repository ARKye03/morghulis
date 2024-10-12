using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/QuickSettings.ui")]
public class QuickSettings : Gtk.Window, ILayerWindow {
    public AstalWp.Endpoint speaker { get; set; }

    public void init_layer_properties () {
        GtkLayerShell.init_for_window (this);
        GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 5);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 5);

        GtkLayerShell.set_namespace (this, namespace);
    }

    public void present_layer () {
        this.present ();
    }
    public string namespace { get; set; }

    [GtkChild]
    public unowned Gtk.Adjustment vol_adjust;

    [GtkCallback]
    public string CurrentVolume(double volume) {
        return @"$(Math.round(volume * 100))%";
    }

    public QuickSettings () {
        Object (
            name: "QuickSettings",
            namespace: "QuickSettings"
        );
        init_layer_properties ();
        speaker = AstalWp.get_default().audio.default_speaker;
        speaker.bind_property("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

    }
}
