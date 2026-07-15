[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/Settings.ui")]
public class Settings : Adw.Bin {
    private AstalMpris.Mpris _mpris;
    private GLib.Settings _gsettings;

    public string color_scheme { get; set; }
    public AstalNetwork.Network network { get; private set; }
    public AstalBluetooth.Bluetooth bluetooth { get; private set; }
    public AstalNotifd.Notifd notifd { get; private set; }
    public AstalWp.Wp? wp { get; private set; }
    public Gamma gamma { get; private set; }
    public Clipboard clipboard { get; private set; }
    public Gdk.Paintable no_media_players { get; private set; }
    public static Adw.NavigationView settings_navigation { get; private set; }

    [GtkChild]
    private unowned Adw.NavigationView quick_settings_navigation_view;

    construct {
        network = AstalNetwork.get_default();
        bluetooth = AstalBluetooth.get_default();
        wp = AstalWp.get_default();
        notifd = AstalNotifd.get_default();

        gamma = Gamma.get_default();
        Morghulis.gsettings.bind("night-light", gamma, "night", GLib.SettingsBindFlags.DEFAULT);

        clipboard = Clipboard.get_default();
        Morghulis.gsettings.bind("clipboard-watch", clipboard, "watching", GLib.SettingsBindFlags.DEFAULT);

        _gsettings = new GLib.Settings("org.gnome.desktop.interface");
        _gsettings.bind("color-scheme", this, "color_scheme", GLib.SettingsBindFlags.GET);

        setup_empty_notif();

        _mpris = AstalMpris.get_default();
        _mpris.players.@foreach((p) => on_player_added(p));
        _mpris.player_added.connect((p) => on_player_added(p));
        _mpris.player_closed.connect((p) => on_player_removed(p));

        settings_navigation = quick_settings_navigation_view;
    }

    [GtkCallback]
    public string notif_status(bool dnd) {
        return dnd ? "Don't disturb" : "Enabled";
    }

    [GtkCallback]
    public string notif_icon(bool dnd) {
        return dnd ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic";
    }

    [GtkCallback]
    public void network_clicked() {
        this.network.wifi.enabled = !this.network.wifi.enabled;
    }

    [GtkCallback]
    public void network_clicked_extras() {
        quick_settings_navigation_view.push_by_tag("network");
    }

    [GtkCallback]
    public string conn_status(bool connected) {
        return connected
                           ? "Connected"
                           : "Off";
    }

    [GtkCallback]
    public string network_identity(string? identity) {
        if (identity != null && identity != "") {
            return identity;
        } else {
            return "Wifi";
        }
    }

    [GtkCallback]
    public void bluetooth_clicked() {
        this.bluetooth.adapter.powered = !this.bluetooth.adapter.powered;
    }

    [GtkCallback]
    public void bluetooth_clicked_extras() {
        quick_settings_navigation_view.push_by_tag("bluetooth");
    }

    [GtkCallback]
    public string bluetooth_icon_name(bool connected) {
        return connected
                           ? "bluetooth-active-symbolic"
                           : "bluetooth-disabled-symbolic";
    }

    [GtkCallback]
    public string bluetooth_identity(string? identity) {
        if (identity != null && identity != "") {
            return identity;
        } else {
            return "Bluetooth";
        }
    }

    [GtkCallback]
    public void audio_clicked() {
        wp.audio.default_speaker.mute = !wp.audio.default_speaker.mute;
    }

    [GtkCallback]
    public void audio_clicked_extras() {
        quick_settings_navigation_view.push_by_tag("audio");
    }

    [GtkCallback]
    public string audio_status(bool muted) {
        return muted
                           ? "Muted"
                           : "Unmuted";
    }

    [GtkCallback]
    public void notifications_clicked() {
        notifd.dont_disturb = !notifd.dont_disturb;
    }

    [GtkCallback]
    public void notifications_clicked_extras() {
        quick_settings_navigation_view.push_by_tag("notifications");
    }

    [GtkCallback]
    public void gamma_clicked() {
        gamma.night = !gamma.night;
    }

    [GtkCallback]
    public void clipboard_clicked() {
        clipboard.watching = !clipboard.watching;
    }

    [GtkCallback]
    public void clipboard_clicked_extras() {
        quick_settings_navigation_view.push_by_tag("clipboard");
    }

    [GtkCallback]
    public string clipboard_status(bool watching) {
        return watching ? "On" : "Off";
    }

    [GtkCallback]
    public string gamma_status(bool night) {
        return night ? "On" : "Off";
    }

    public void TODO() {
        message("TODO!");
    }

    [GtkChild]
    private unowned Adw.Carousel players;

    [GtkCallback]
    public string mpris_stack(uint n_pages) {
        return (n_pages > 0) ? "mpris" : "no_mpris";
    }

    private void on_player_added(AstalMpris.Player player) {
        var mpris_widget = new MprisPlayer(player);

        this.players.append(mpris_widget);
    }

    private void on_player_removed(AstalMpris.Player player) {
        MprisPlayer current = (MprisPlayer)this.players.get_first_child();

        while (current != null) {
            if (current.player == player) {
                this.players.remove(current);
                break;
            }
            current = (MprisPlayer)current.get_next_sibling();
        }
    }

    private void setup_empty_notif() {
        try {
            var pixbuf = new Gdk.Pixbuf.from_resource("/com/github/ARKye03/morghulis/assets/wyvern-svgrepo-com.svg");
            if (pixbuf != null) {
                no_media_players = Gdk.Texture.for_pixbuf(pixbuf);
            }
        } catch (Error e) {
            warning("Failed to load image: %s", e.message);
        }
    }

    [GtkCallback]
    private void push_app_settings() {
        quick_settings_navigation_view.push_by_tag("app_settings");
    }

    [GtkCallback]
    private async void color_scheme_clicked() {
        if (color_scheme == "default" || color_scheme == "prefer-light") {
            color_scheme = "prefer-dark";
        } else {
            color_scheme = "prefer-light";
        }
        _gsettings.set_string("color-scheme", color_scheme);
    }

    [GtkCallback]
    private string color_scheme_icon(string? color_scheme) {
        if (color_scheme == null) {
            return "weather-clear-symbolic";
        }
        return color_scheme == "prefer-dark" ? "weather-clear-night-symbolic" : "weather-clear-symbolic";
    }
}
