using GtkLayerShell;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu.ui")]
public class QuickMenu : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }
	public string user_name { get; set; }
	public string user_image { get; set; }
	public Gdk.Paintable user_image_paintable { get; set; }

	public QuickMenu() {
		Object(
			anchor: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT
			);
	}

	construct {
		user_name = @"Hello there $(Environment.get_user_name ())";
		user_image = Environment.get_home_dir() + "/user.png";
		try {
			var pixbuf = new Gdk.Pixbuf.from_file(user_image);
			if (pixbuf != null) {
				user_image_paintable = Gdk.Texture.for_pixbuf(pixbuf);
			}
		} catch (Error e) {
			stderr.printf("Error loading image: %s\n", e.message);
		}
	}
}
