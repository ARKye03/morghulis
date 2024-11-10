using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/SideDashboard.ui")]
public class SideDashboard : Astal.Window {
public AstalWp.Endpoint speaker { get; set; }
public string user_name { get; set; }
public string user_image { get; set; }

public SideDashboard () {
	Object (
		anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
		);
}
construct {
	user_name = @"Hello there $(Environment.get_user_name ())";
	user_image = Environment.get_home_dir () + "/user.png";
}

}
