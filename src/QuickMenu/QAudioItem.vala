[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QAudioItem.ui")]
public class QAudioItem : Gtk.ListBoxRow {
    public AstalWp.Node endpoint { get; construct; }

    [GtkChild]
    private unowned Gtk.Adjustment volume_adjust;

    public QAudioItem(AstalWp.Node endpoint) {
        Object(endpoint: endpoint);

        this.endpoint.bind_property(
            "volume",
            volume_adjust,
            "value",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
        );
    }

    [GtkCallback]
    public string fallback_icon(string? icon_name) {
        switch (icon_name) {
            case "audio-card-analog-pci":
                return "audio-card-symbolic";

            case "audio-headset-bluetooth":
                return "audio-headset-symbolic";

            default:
                return icon_name;
        }
    }
}
