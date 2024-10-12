using GtkLayerShell;

[GtkTemplate (ui = "/com/github/ARKye03/morghulis/ui/QuickSettings.ui")]
public class QuickSettings : Gtk.Window, ILayerWindow {
    public AstalWp.Endpoint speaker { get; set; }
    public AstalNetwork.Network network { get; set; }
    public AstalBluetooth.Bluetooth bluetooth { get; set; }
    public AstalNotifd.Notifd notifd {get; private set;}
    public AstalMpris.Mpris mpris {get; private set;}


    public QuickSettings () {
        Object (
            name: "QuickSettings",
            namespace: "QuickSettings"
        );
        init_layer_properties ();
        
        speaker.bind_property("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
        
    }
    construct {
        speaker = AstalWp.get_default().audio.default_speaker;
        network = AstalNetwork.get_default();
        mpris = AstalMpris.get_default();
        bluetooth = AstalBluetooth.get_default();
        this.mpris.players.@foreach((p) => this.on_player_added(p));
        this.mpris.player_added.connect((p) => this.on_player_added(p));
        this.mpris.player_closed.connect((p) => this.on_player_removed(p));
    }

    [GtkChild]
    public unowned Gtk.Adjustment vol_adjust;

    [GtkCallback]
    public string CurrentVolume(double volume) {
        return @"$(Math.round(volume * 100))%";
    }

    [GtkCallback]
    public void network_clicked() {
        this.network.wifi.enabled = !this.network.wifi.enabled;
    }
    [GtkCallback]
    public void bluetooth_clicked() {
        this.bluetooth.adapter.powered = !this.bluetooth.adapter.powered;
    }
    [GtkCallback]
    public void bluetooth_clicked_extras() {
        //TODO
    }
    [GtkCallback]
    public string bluetooth_icon_name(bool connected) {
        return connected
            ? "bluetooth-active-symbolic"
            : "bluetooth-disabled-symbolic";
    }
    [GtkCallback]
    public string ActiveVPN(AstalNetwork.Network network) {
        return network.wifi.active_connection.vpn ? "network-vpn-symbolic" : "network-vpn-disabled-symbolic";
    }
    [GtkCallback]
    public void toggle_vpn() {
        try {
            if (network.wifi.active_connection.vpn)
                Process.spawn_command_line_async("protonvpn-cli d");
            else
                Process.spawn_command_line_async("protonvpn-cli c --cc US -p udp");
        } catch (GLib.Error e) {
            print("Error executing command: %s\n", e.message);
        }
    }

    [GtkCallback]
    public string dont_disturb_icon(bool dnd) {
      return dnd 
        ? "notifications-disabled-symbolic"
        : "user-available-symbolic";
    }
    [GtkCallback]
    public void toggle_disturb() {
        this.notifd.dont_disturb = !this.notifd.dont_disturb;
    }

    [GtkCallback]
    public void on_notif_arrow_clicked() {
        //  nav_view.push_by_tag("notifications");
    }  
    [GtkChild]
    private unowned Adw.Carousel players;

    private void on_player_added(AstalMpris.Player player) {
        this.players.append(new Mpris(player));
    }

    private void on_player_removed(AstalMpris.Player player) {
      for(int i = 0; i < this.players.n_pages; i++) {
        Mpris p = (Mpris) this.players.get_nth_page(i);
        if (p.player == player)
          this.players.remove(p);
      }
    }
    public void init_layer_properties () {
        GtkLayerShell.init_for_window (this);
        GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 5);
        GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 5);

        GtkLayerShell.set_namespace (this, namespace);
    }

    public void present_layer () {
        this.present ();
    }
    public string namespace { get; set; }
}
