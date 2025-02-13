[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QButton.ui")]
public class QButton : Gtk.Box {
	public signal void clicked();
	public signal void clicked_extras();

	public string icon { get; set; }
	public string identity { get; set; }
	public string status { get; set; }

	public bool active {
		get {
			return this.main_btn.has_css_class("suggested-action") && this.extra_btn.has_css_class("suggested-action");
		}
		set {
			if (value) {
				this.main_btn.add_css_class("suggested-action");
				this.extra_btn.add_css_class("suggested-action");
			} else {
				this.main_btn.remove_css_class("suggested-action");
				this.extra_btn.remove_css_class("suggested-action");
			}
		}
	}
	public bool inactive {
		get {
			return !this.main_btn.has_css_class("suggested-action") && !this.extra_btn.has_css_class("suggested-action");
		}
		set {
			if (!value) {
				this.main_btn.add_css_class("suggested-action");
				this.extra_btn.add_css_class("suggested-action");
			} else {
				this.main_btn.remove_css_class("suggested-action");
				this.extra_btn.remove_css_class("suggested-action");
			}
		}
	}

	[GtkChild]
	private unowned Gtk.Button main_btn;

	[GtkChild]
	private unowned Gtk.Button extra_btn;

	QButton() {
		Object(
			name: "Button"
		);
	}

	[GtkCallback]
	public void on_clicked() {
		clicked();
	}

	[GtkCallback]
	public void on_clicked_extras() {
		clicked_extras();
	}
}
