using Gtk;
using GtkLayerShell;

public class Zoore.Bar : Gtk.Window {

    public Bar (Gtk.Application app) {
        Object (application: app);

        GtkLayerShell.init_for_window (this);
        GtkLayerShell.auto_exclusive_zone_enable (this);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 10);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, 10);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
        var centerBox = new Gtk.CenterBox ();
        centerBox.set_start_widget (new Gtk.Label ("Hello"));

        set_child (centerBox);
    }
}