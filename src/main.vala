using Gtk;

class ZooreMain : GLib.Object {
    public static int main(string[] argv) {
        var app = new
            Gtk.Application(
                            "zoore.vala",
                            GLib.ApplicationFlags.FLAGS_NONE);

        app.activate.connect(() => {
            var window = new Zoore.Bar(app);
            var applauncher = new Zoore.Apps(app);
            applauncher.present();
            window.present();
        });

        return app.run(argv);
    }
}