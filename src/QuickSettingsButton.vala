[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickSettingsButton.ui")]
public class QuickSettingsButton : Gtk.Box {
    public signal void clicked();
    public signal void clicked_extras();

    public string icon { get; set; }

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
}