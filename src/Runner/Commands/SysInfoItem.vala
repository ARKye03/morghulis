[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/SysInfoItem.ui")]
public class SysInfoItem : Gtk.Box {
    public double percentage_value { get; private set; }
    public string title { get; private set; }
    public string details_value { get; private set; }
    public string icon { get; private set; }

    public SysInfoItem(string title, string icon_name) {
        Object();
        this.title = title;
        this.icon = icon_name;
    }

    public void set_percentage(double percentage) {
        this.percentage_value = percentage;
    }

    public void set_details(string details) {
        this.details_value = details;
    }

    public virtual void update() {
        // Override in subclasses
    }
}
