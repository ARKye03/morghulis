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
        centerBox.set_start_widget (Left ());
        centerBox.set_center_widget (Center ());
        centerBox.set_end_widget (Right ());

        set_child (centerBox);
    }

    Gtk.Box Left () {
        var LeftBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        LeftBox.set_halign (Gtk.Align.START);

        var LauncherButton = new Gtk.Button ();
        LauncherButton.set_label ("Launch");
        LauncherButton.clicked.connect (() => {
            print ("xd");
        });
        LeftBox.append (LauncherButton);



        return LeftBox;
    }

    Gtk.Box Center () {
        var BTIITC = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        BTIITC.set_halign (Gtk.Align.CENTER);
        var MediaButton = new Gtk.Button.with_label ("EXSISHON");
        BTIITC.append (MediaButton);
        return BTIITC;
    }

    Gtk.Box Right () {
        var RightBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        RightBox.set_halign (Gtk.Align.END);
        return RightBox;
    }
}
class Zoore.Apps : Gtk.Window {
    public Apps (Gtk.Application app) {
        Object (application: app);
        GtkLayerShell.init_for_window (this);
        GtkLayerShell.auto_exclusive_zone_enable (this);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.TOP, 10);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, 10);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);

        var bvb = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        bvb.append (new Gtk.Label ("Helo"));
        bvb.append (new Gtk.Label ("Helo"));
        bvb.append (new Gtk.Label ("Helo"));
        bvb.append (new Gtk.Label ("Helo"));

        visible = false;
        set_child (bvb);
    }
}