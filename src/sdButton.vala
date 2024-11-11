[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/sdButton.ui")]
public class sdButton : Gtk.Box {
	public AstalNetwork.Network network { get; set; }

	public signal void clicked();
	public signal void clicked_extras();

	public string icon { get; set; }

	public bool active {
		get {
			return this.has_css_class("quick_settings_button-active");
		}
		set {
			if (value) {
				this.add_css_class("quick_settings_button-active");
			}
			else{
				this.remove_css_class("quick_settings_button-active");
			}
		}
	}
	public bool inactive {
		get {
			return !this.has_css_class("quick_settings_button-active");
		}
		set {
			if (!value) {
				this.add_css_class("quick_settings_button-active");
			}
			else{
				this.remove_css_class("quick_settings_button-active");
			}
		}
	}

	[GtkCallback]
	public void on_clicked() {
		clicked();
	}

	[GtkCallback]
	public void on_clicked_extras() {
		clicked_extras();
	}

	static construct {
		set_css_name("quick_settings_button");
	}
	sdButton() {
		Object(
			name: "sdButton"
			);
		network = AstalNetwork.get_default();
	}
}
