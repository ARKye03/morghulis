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
				var app_executable_field = app.executable;
				if (app_executable_field != null) {
					// Extract just the binary name, removing parameters like %U, %F, etc.
					string binary_name = app_executable_field.split("%")[0];
					try {
						Process.spawn_command_line_async(@"uwsm app -- $binary_name");
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
