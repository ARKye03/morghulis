/* Access point wrapper for NetworkManager
 *
 * Provides a simple interface to NM.AccessPoint
 */
public class AccessPoint : GLib.Object {
	private NM.AccessPoint _ap;
	private string? _ssid_cached = null;

	public AccessPoint(NM.AccessPoint ap) {
		_ap = ap;
		_ap.notify.connect(() => {
			notify_property("strength");
			notify_property("icon-name");
			_ssid_cached = null;
		});
	}

	public NM.AccessPoint nm_ap {
		get { return _ap; }
	}

	public uint8 strength {
		get { return _ap.get_strength(); }
	}

	public unowned string ssid {
		get {
			if (_ssid_cached == null) {
				_ssid_cached = NM.Utils.ssid_to_utf8(_ap.get_ssid().get_data());
			}
			return _ssid_cached;
		}
	}

	public unowned string icon_name {
		get {
			return get_icon_for_strength(_ap.get_strength());
		}
	}

	public bool is_secure {
		get {
			return _ap.get_flags() == NM .80211ApFlags.PRIVACY ||
				   _ap.get_wpa_flags() != 0 ||
				   _ap.get_rsn_flags() != 0;
		}
	}

	public NM .80211Mode mode {
		get { return _ap.get_mode(); }
	}

	public uint32 frequency {
		get { return _ap.get_frequency(); }
	}

	public uint32 max_bitrate {
		get { return _ap.get_max_bitrate(); }
	}

	// Helper method to get the icon based on signal strength
	private unowned string get_icon_for_strength(uint8 strength) {
		if (strength > SignalStrength.GOOD) {
			return "network-wireless-signal-excellent-symbolic";
		} else if (strength > SignalStrength.OK) {
			return "network-wireless-signal-good-symbolic";
		} else if (strength > SignalStrength.WEAK) {
			return "network-wireless-signal-ok-symbolic";
		}
		return "network-wireless-signal-weak-symbolic";
	}

	// Cache the access points by their NM.AccessPoint reference
	private static HashTable<NM.AccessPoint, AccessPoint> _cache;

	static construct {
		_cache = new HashTable<NM.AccessPoint, AccessPoint>(direct_hash, direct_equal);
	}

	// Factory method to ensure we reuse AccessPoint instances
	public static AccessPoint @for(NM.AccessPoint ap) {
		var existing = _cache.lookup(ap);

		if (existing != null) {
			return existing;
		}

		var new_ap = new AccessPoint(ap);
		_cache.insert(ap, new_ap);
		return new_ap;
	}
}
