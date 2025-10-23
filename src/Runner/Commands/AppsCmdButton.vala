[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/AppsCmdButton.ui")]
public class AppsCmdButton : Gtk.ListBoxRow {
    private delegate void launch_app();

    public AstalApps.Application app { get; construct; }
    public double score { get; set; }

    private launch_app app_launch_handler;

    [GtkCallback]
    public void clicked() {
        app_launch_handler();
    }

    [GtkCallback]
    public void activated() {
        app_launch_handler();
    }

    public AppsCmdButton(AstalApps.Application app, bool is_uwsm_session) {
        Object(app: app);
        if (is_uwsm_session) {
            app_launch_handler = () => {
                var app_executable_field = app.entry;
                if (app_executable_field != null) {
                    try {
                        Process.spawn_command_line_async(@"uwsm app -- $app_executable_field");
                    } catch (SpawnError e) {
                        warning("Failed to launch app: %s\n", e.message);
                    }
                }
            };
        } else {
            app_launch_handler = () => app.launch();
        }
    }
}
