[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/QNetworkItem.ui")]
public class QNetworkItem : Gtk.ListBoxRow {
	public AstalNetwork.AccessPoint access_point { get; construct; }
	public AstalNetwork.Network network { get; construct; }
	public bool is_active { get; private set; default = false; }
	public bool is_protected { get; private set; default = false; }

	public bool active {
		get {
			return has_css_class("button_accent_bg");
		}
		set {
			if (value) {
				this.add_css_class("button_accent_bg");
			} else {
				this.remove_css_class("button_accent_bg");
			}
		}
	}

	public QNetworkItem(AstalNetwork.AccessPoint ap, AstalNetwork.Network net) {
		Object(access_point: ap, network: net);
	}

	construct {
		is_protected = access_point.flags != NM .80211ApFlags.NONE;
		check_active_connection();

		// Listen for connection changes
		network.wifi.notify["active-access-point"].connect(check_active_connection);
	}

	[GtkCallback]
	public string ssid_name(string ssid) {
		return ssid ?? "Unknown Network";
	}

	[GtkCallback]
	public void switch_connection() {
		if (is_active) {
			network.wifi.deactivate_connection.begin();
		} else {
			access_point.activate.begin();
		}
	}

	private void check_active_connection() {
		is_active = network.wifi.active_access_point != null &&
					network.wifi.active_access_point.ssid == access_point.ssid;
	}

	[GtkCallback]
	private string status_label(bool is_active) {
		if (is_active) {
			return "Connected";
		} else if (access_point.flags != NM .80211ApFlags.NONE) {
			return "Secured";
		} else {
			return "Open";
		}
	}

	// For sorting - active connections should be at top
	public int compare_to(QNetworkItem other) {
		// Active connections first
		if (this.is_active && !other.is_active) {
			return -1;
		}
		if (!this.is_active && other.is_active) {
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
