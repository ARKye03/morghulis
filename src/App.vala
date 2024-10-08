using Gtk;
using GtkLayerShell;

public class Morghulis : Gtk.Application {
    private List<LayerWindow> windows = new List<LayerWindow> ();
    private bool _cssLoaded = false;

    public static void main(string[] args) {
        var app = new Morghulis();
        app.run(args);
    }

    construct {
        application_id = "com.github.arkye03.morghulis";
        flags = ApplicationFlags.FLAGS_NONE;
    }

    public override void activate() {
        if (windows.length() > 0) {
            foreach (var window in windows) {
                window.present_layer();
            }
            return;
        }

        if (!_cssLoaded) {
            LoadCss();
            _cssLoaded = true;
        }

        var nav_bar = new StatusBar(this);
        windows.append(nav_bar);
        nav_bar.present_layer();
    }

    void LoadCss() {
        Gtk.CssProvider provider = new Gtk.CssProvider();
        provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}