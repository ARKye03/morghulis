using Gtk;
using GtkLayerShell;

public class Zoore : Gtk.Application {
    private List<LayerWindow> windows = new List<LayerWindow> ();
    private bool _cssLoaded = false;

    public static void main(string[] args) {
        var app = new Zoore();
        app.run(args);
    }

    construct {
        application_id = "org.gtk.Example";
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

        var nav_bar = new NavBar(this);
        windows.append(nav_bar);
        nav_bar.present_layer();
    }

    void LoadCss() {
        var input = "src/styles/main.scss";
        var output = "/tmp/zoore/style.css";
        string[] argv = { "sass", input, output };

        try {
            var dir = File.new_for_path("/tmp/zoore");
            if (!dir.query_exists()) {
                dir.make_directory_with_parents();
            }
            var subprocess = new GLib.Subprocess.newv(argv, GLib.SubprocessFlags.STDOUT_PIPE);
            subprocess.wait();
        } catch (GLib.Error e) {
            stdout.printf("Error: %s\n", e.message);
        }

        var provider = new Gtk.CssProvider();
        provider.load_from_path(output);

        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}