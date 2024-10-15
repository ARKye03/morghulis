[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/RunnerButton.ui")]
public class RunnerButton : Gtk.ListBoxRow {

public AstalApps.Application app {get; construct;}
public double score { get; set;}

[GtkCallback]
public void clicked () {
	app.launch ();
}
[GtkCallback]
public void activated () {
	app.launch ();
}

public RunnerButton (AstalApps.Application app) {
	Object (app: app);
}

}