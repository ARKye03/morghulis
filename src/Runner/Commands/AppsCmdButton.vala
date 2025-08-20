[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/AppsCmdButton.ui")]
public class AppsCmdButton : Gtk.ListBoxRow {
	public AstalApps.Application app { get; construct; }
	public double score { get; set; }

	[GtkCallback]
	public void clicked() {
		app.launch();
	}

	[GtkCallback]
	public void activated() {
		app.launch();
	}

	public AppsCmdButton(AstalApps.Application app) {
		Object(app: app);
	}
}
