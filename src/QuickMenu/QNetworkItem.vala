[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetworkItem.ui")]
public class QNetworkItem : Gtk.ListBoxRow {
	public AstalNetwork.AccessPoint access_point { get; construct; }
	public AstalNetwork.Network network { get; construct; }
	private bool _active = false;
	public bool active {
		get {
			return _active;
		}
		set {
			_active = value;
			if (value) {
				this.add_css_class("success");
			} else {
				this.remove_css_class("success");
			}
		}
	}

	public QNetworkItem(AstalNetwork.AccessPoint ap, AstalNetwork.Network net) {
		Object(access_point: ap, network: net);
	}

	[GtkCallback]
	public string ssid_name(string? ssid) {
		return ssid ?? "Unknown Network";
	}

	[GtkCallback]
	public void switch_connection() {
		if (access_point == null) {
			return;
		}

		if (active) {
			network.wifi.deactivate_connection.begin();
		} else {
			access_point.activate.begin();
		}
	}

	public void update_active_state(AstalNetwork.AccessPoint? active_ap) {
		if (access_point == null) {
			active = false;
			return;
		}

		active = active_ap != null && active_ap.ssid == access_point.ssid;
	}

	[GtkCallback]
	private string status_label(bool active) {
		if (active) {
			return "Connected";
		} else if (access_point != null && access_point.requires_password) {
			return "Secured";
		} else {
			return "Open";
		}
	}

	// For sorting - active connections should be at top
	public int compare_to(QNetworkItem other) {
		// Active connections first
		if (this.active && !other.active) {
			return -1;
		}
		if (!this.active && other.active) {
			return 1;
		}

		// Then by signal strength
		if (this.access_point.strength > other.access_point.strength) {
			return -1;
		}
		if (this.access_point.strength < other.access_point.strength) {
			return 1;
		}

		// Finally by SSID alphabetically
		return this.access_point.ssid.collate(other.access_point.ssid);
	}
}
