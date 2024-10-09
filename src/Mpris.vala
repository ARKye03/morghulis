using AstalMpris;
using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Mpris.ui")]
public class Mpris : Gtk.Window, LayerWindow {

    public AstalMpris.Mpris mpris = AstalMpris.Mpris.get_default();


    public Mpris(Gtk.Application app) {
        Object(application: app);
        init_layer_properties();
    }

    public void init_layer_properties() {
        GtkLayerShell.init_for_window(this);
        GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);

        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 50);
        GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 5);
        // GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 10);
    }

    public void present_layer() {
        this.present();
    }
}