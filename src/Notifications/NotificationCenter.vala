[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Notifications/NotificationCenter.ui")]
public class NotificationCenter : MorghulWindow {
    public static NotificationCenter instance { get; private set; }

    construct {
        if (instance == null) {
            instance = this;
        } else {
            this.destroy();
        }

        this.notify["visible"].connect(() => {
            if (this.visible) {
                QuickMenu.instance.visible = false;
            }
        });
    }
}
