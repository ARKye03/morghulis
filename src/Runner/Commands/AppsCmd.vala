[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Commands/AppsCmd.ui")]
public class AppsCmd : Gtk.Widget, ICommand {
    private List<FileMonitor> _data_dirs_monitors;
    private uint _reload_timeout = 0;
    private bool _is_uwsm_session = false;
    public AstalApps.Apps apps { get; construct set; }

    // ICommand interface implementation - not used for apps but required
    public string icon_name { get { return "applications-all-symbolic"; } }

    [GtkChild]
    private unowned Gtk.ListBox app_list;

    [GtkChild]
    private unowned Gtk.Stack apps_stack;

    construct {
        this.apps = new AstalApps.Apps();
        _is_uwsm_session = Environment.get_variable("IS_UWSM_ACTIVE") == "1";

        setup_desktop_file_monitors();
        setup_list_behavior();
        populate_list();
    }

    private void setup_list_behavior() {
        app_list.set_sort_func(sort_func);
        app_list.set_filter_func(filter_func);
    }

    private int sort_func(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
        AppsCmdButton a = (AppsCmdButton)la;
        AppsCmdButton b = (AppsCmdButton)lb;

        if (a.score == b.score) {
            return b.app.frequency - a.app.frequency;
        }
        return (a.score > b.score) ? -1 : 1;
    }

    private bool filter_func(Gtk.ListBoxRow row) {
        AppsCmdButton app = (AppsCmdButton)row;

        return app.score >= 0;
    }

    private void populate_list() {
        if (apps.list == null) {
            return;
        }
        apps.list.foreach(app => {
            var button = new AppsCmdButton(app, _is_uwsm_session);
            // Initialize with a positive score so all apps are visible by default
            button.score = 1.0;
            app_list.append(button);
        });
    }

    public void handle_input(string input) {
        update_apps(input);
    }

    public void on_activate() {
        update_apps("");
    }

    public void on_deactivate() {
        // Nothing special needed when deactivating
    }

    public void on_enter() {
        var first_app = (AppsCmdButton)app_list.get_first_child();

        if (first_app != null) {
            debug("Launching application: " + first_app.app.name);
            first_app.activate();
            Runner.instance.visible = false;
        }
    }

    public void update_apps(string input) {
        bool has_visible_apps = false;
        var child = app_list.get_first_child();

        while (child != null) {
            if (child is AppsCmdButton) {
                var app = (AppsCmdButton)child;
                app.score = apps.fuzzy_score(input, app.app);

                if (!has_visible_apps && app.score >= 0) {
                    has_visible_apps = true;
                }
            }
            child = child.get_next_sibling();
        }

        app_list.invalidate_sort();
        app_list.invalidate_filter();

        string target_page = has_visible_apps ? "apps-list" : "no-results";
        debug(@"Switching to page: $target_page (has_visible_apps: $has_visible_apps)");
        apps_stack.visible_child_name = target_page;
    }

    private void setup_desktop_file_monitors() {
        _data_dirs_monitors = new List<FileMonitor>();

        string? xdg_data_dirs = Environment.get_variable("XDG_DATA_DIRS");
        // This shouldn't happen right?
        if (xdg_data_dirs == null || xdg_data_dirs == "") {
            xdg_data_dirs = "/usr/local/share:/usr/share";
        }

        // Also include XDG_DATA_HOME (usually ~/.local/share)
        string? xdg_data_home = Environment.get_variable("XDG_DATA_HOME");
        if (xdg_data_home == null) {
            xdg_data_home = Path.build_filename(Environment.get_home_dir(), ".local", "share");
        }

        // Combine all data directories
        string all_dirs = @"$xdg_data_home:$xdg_data_dirs";
        string[] data_dirs = all_dirs.split(":");

        foreach (string data_dir in data_dirs) {
            if (data_dir.strip() == "") {
                continue;
            }

            string applications_dir = Path.build_filename(data_dir.strip(), "applications");

            if (!FileUtils.test(applications_dir, FileTest.IS_DIR)) {
                continue;
            }

            try {
                var file = File.new_for_path(applications_dir);
                var monitor = file.monitor_directory(FileMonitorFlags.NONE);

                monitor.changed.connect(on_desktop_files_changed);
                _data_dirs_monitors.append(monitor);

                debug(@"Monitoring desktop files in: $applications_dir");
            } catch (Error e) {
                warning(@"Failed to monitor directory $applications_dir: $(e.message)");
            }
        }
    }

    private void on_desktop_files_changed(File file, File? other_file, FileMonitorEvent event_type) {
        switch (event_type) {
            case FileMonitorEvent.CREATED:
            case FileMonitorEvent.DELETED:
            case FileMonitorEvent.CHANGED:
                // Check if it's a .desktop file
                string filename = file.get_basename();
                if (filename.has_suffix(".desktop")) {
                    debug(@"Desktop file changed: $filename, reloading apps…");
                    // Debounce the reload to avoid excessive reloads
                    debounce_apps_reload();
                }
            break;

            default:
            break;
        }
    }

    private void debounce_apps_reload() {
        if (_reload_timeout > 0) {
            Source.remove(_reload_timeout);
        }

        _reload_timeout = Timeout.add(500, () => {
            apps.reload();

            app_list.remove_all();

            populate_list();
            app_list.invalidate_filter();
            app_list.invalidate_sort();
            _reload_timeout = 0;
            return Source.REMOVE;
        });
    }

    ~AppsCmd() {
        if (_data_dirs_monitors != null) {
            _data_dirs_monitors.foreach(monitor => {
                monitor.cancel();
            });
        }

        if (_reload_timeout > 0) {
            Source.remove(_reload_timeout);
        }
    }
}
