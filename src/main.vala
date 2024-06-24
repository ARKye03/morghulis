#! /usr/bin/env -S vala --pkg gtk4 --pkg gtk4-layer-shell-0

using Gtk;
using GtkLayerShell;
class Zoore : GLib.Object {
    public static int main(string[] argv) {
        var app = new Gtk.Application(
                                      "zoore.vala",
                                      GLib.ApplicationFlags.FLAGS_NONE);

        app.activate.connect(() => {
            var window = NavBar(app);
            window.present();
        });

        return app.run(argv);
    }

    public static Gtk.Window NavBar(Gtk.Application app) {
        var window = new Gtk.ApplicationWindow(app);
        GtkLayerShell.init_for_window(window);
        GtkLayerShell.auto_exclusive_zone_enable(window);
        GtkLayerShell.set_margin(window, GtkLayerShell.Edge.RIGHT, 10);
        GtkLayerShell.set_margin(window, GtkLayerShell.Edge.LEFT, 10);
        GtkLayerShell.set_anchor(window, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(window, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor(window, GtkLayerShell.Edge.LEFT, true);

        var centerBox = new Gtk.CenterBox();
        centerBox.set_start_widget(new Gtk.Button.with_label("Left button!"));
        window.set_child(centerBox);
        return window;
    }
}