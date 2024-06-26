using Gtk;
using GtkLayerShell;

public class Zoore : Gtk.Application {
    public NavBar nav_bar;

    private static Zoore _instance;
    public static Zoore instance {
        get {
            if (_instance == null)
                _instance = new Zoore();

            return _instance;
        }
    }

    construct {
        application_id = "org.gtk.Example";
        flags = ApplicationFlags.FLAGS_NONE;
    }

    public override void activate() {
        if (nav_bar != null) {
            nav_bar.show();
            return;
        }

        nav_bar = new NavBar(this);
        GtkLayerShell.init_for_window(nav_bar);
        GtkLayerShell.auto_exclusive_zone_enable(nav_bar);
        GtkLayerShell.set_margin(nav_bar, GtkLayerShell.Edge.RIGHT, 10);
        GtkLayerShell.set_margin(nav_bar, GtkLayerShell.Edge.LEFT, 10);
        GtkLayerShell.set_anchor(nav_bar, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(nav_bar, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor(nav_bar, GtkLayerShell.Edge.LEFT, true);

        nav_bar.present();
    }

    public static int main(string[] args) {
        var app = Zoore.instance;
        return app.run(args);
    }
}