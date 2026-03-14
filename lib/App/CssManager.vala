public class CssManager : Object {
    private File _user_css_file;
    private FileMonitor? _css_file_monitor;
    private Gtk.CssProvider? _user_css_provider;
    private uint _reload_count = 0;

    public signal void css_reloaded(uint count);
    public signal void css_created();

    public CssManager() {
        _user_css_file = File.new_for_path(@"$(Environment.get_user_config_dir())/morghulis/main.css");
        setup_monitoring();
    }

    public void load_app_css() {
        bool use_built_in_gtk_theme = Morghulis.gsettings.get_boolean("gtk-theme");

        if (use_built_in_gtk_theme) {
            var app_css_provider = new Gtk.CssProvider();
            app_css_provider.load_from_resource("com/github/ARKye03/morghulis/app.css");
            add_provider(app_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        var main_css_provider = new Gtk.CssProvider();

        main_css_provider.load_from_resource("com/github/ARKye03/morghulis/morghulis.css");
        add_provider(main_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void load_user_css() {
        if (!_user_css_file.query_exists()) {
            return;
        }

        // Remove old user CSS provider
        if (_user_css_provider != null) {
            remove_provider(_user_css_provider);
        }

        // Create and add new user CSS provider
        _user_css_provider = new Gtk.CssProvider();
        _user_css_provider.load_from_path(_user_css_file.get_path());
        add_provider(_user_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }

    public void reload_user_css() {
        load_user_css();
        _reload_count++;
        css_reloaded(_reload_count);
    }

    private void setup_monitoring() {
        try {
            _css_file_monitor = _user_css_file.monitor_file(
                GLib.FileMonitorFlags.WATCH_HARD_LINKS
                | GLib.FileMonitorFlags.WATCH_MOUNTS
                | GLib.FileMonitorFlags.WATCH_MOVES
            );

            _css_file_monitor.changed.connect((file, other_file, event_type) => {
                switch (event_type) {
                        case FileMonitorEvent.CHANGED:
                            reload_user_css();
                        break;

                        case FileMonitorEvent.CREATED:
                            load_user_css();
                            css_created();
                        break;

                        default:
                            warning("Unknown CSS file event");
                        break;
                }
            });
        } catch (IOError e) {
            critical("Error setting up CSS monitoring: %s", e.message);
        }
    }

    private void add_provider(Gtk.CssProvider provider, uint priority) {
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            priority
        );
    }

    private void remove_provider(Gtk.CssProvider? provider) {
        if (provider != null) {
            Gtk.StyleContext.remove_provider_for_display(
                Gdk.Display.get_default(),
                provider
            );
        }
    }
}
