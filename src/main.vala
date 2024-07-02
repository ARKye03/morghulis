using Gtk;
using GtkLayerShell;

public class Zoore : Gtk.Application {
    public NavBar nav_bar;
    private bool _cssLoaded = false;


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

        // Ensure CSS is loaded only once.
        if (!_cssLoaded) {
            LoadCss();
            _cssLoaded = true;
        }

        nav_bar = new NavBar(this);

        PresentLayer(nav_bar,
                     new GtkLayerShell.Edge[] {
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.RIGHT,
            GtkLayerShell.Edge.LEFT
        },
                     new GtkLayerShell.Edge[] {
            GtkLayerShell.Edge.RIGHT,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.BOTTOM
        },
                     GtkLayerShell.Layer.TOP
        );
    }

    void PresentLayer(Gtk.Window window,
                      GtkLayerShell.Edge[] anchors,
                      GtkLayerShell.Edge[] margins,
                      GtkLayerShell.Layer layer = GtkLayerShell.Layer.TOP) {
        GtkLayerShell.init_for_window(window);
        GtkLayerShell.auto_exclusive_zone_enable(window);
        GtkLayerShell.set_layer(window, layer);

        foreach (var item in anchors) {
            GtkLayerShell.set_anchor(window, item, true);
        }

        foreach (var item in margins) {
            GtkLayerShell.set_margin(window, item, 10);
        }

        window.present();
    }

    void LoadCss() {
        var input = "src/styles/main.scss";
        var output = "/tmp/zoore/style.css";
        string[] argv = { "sassc", input, output };

        try {
            var dir = File.new_for_path("/tmp/zoore");
            if (!dir.query_exists()) {
                dir.make_directory_with_parents();
            }
            var subprocess = new GLib.Subprocess.newv(argv, GLib.SubprocessFlags.STDOUT_PIPE);
            subprocess.wait(); // Ensure the process completes before proceeding
        } catch (GLib.Error e) {
            stdout.printf("Error: %s\n", e.message);
        }

        var provider = new Gtk.CssProvider();
        provider.load_from_path(output);
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public static int main(string[] args) {
        var app = Zoore.instance;
        return app.run(args);
    }
}