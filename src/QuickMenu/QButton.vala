[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QButton.ui")]
public class QButton : Gtk.Box {
    public signal void clicked();
    public signal void clicked_extras();

    public string icon { get; set; }
    public string identity { get; set; }
    public string status { get; set; }

    public bool active {
        get {
            return this.has_css_class("qbutton");
        }
        set {
            if (value) {
                this.add_css_class("qbutton");
            } else {
                this.remove_css_class("qbutton");
            }
        }
    }
    public bool inactive {
        get {
            return !this.has_css_class("qbutton");
        }
        set {
            if (!value) {
                this.add_css_class("qbutton");
            } else {
                this.remove_css_class("qbutton");
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
}
