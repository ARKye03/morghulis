using Gtk;
using GtkLayerShell;

public class Morghulis : Gtk.Application {
    public static Morghulis Instance { get; private set; }
    private List<LayerWindow> windows = new List<LayerWindow> ();
    private bool _cssLoaded = false;

    public static void main(string[] args) {
        Instance = new Morghulis();
        Instance.run(args);
    }

    construct {
        application_id = "com.github.arkye03.morghulis";
        flags = ApplicationFlags.FLAGS_NONE;
    }

    public override void activate() {
        if (!_cssLoaded) {
            LoadCss();
            _cssLoaded = true;
        }

        windows.append(new StatusBar(this));
        windows.append(new Mpris(this));

        foreach (var window in windows) {
            window.present_layer();
        }
    }

    public bool ToggleWindow(string name) {
        LayerWindow? w = null;
        foreach (var window in windows) {
            if (window.name == name) {
                w = window;
                break;
            }
        }
        if (w != null) {
            w.visible = !w.visible;
            return true;
        }
        printerr(@"Window $name not found.\n");
        return false;
    }

    void LoadCss() {
        Gtk.CssProvider provider = new Gtk.CssProvider();
        provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}