public class Backlight : Object {
	private static Backlight _instance;
	private FileMonitor? _b_monitor;
	private File _b_file;
	private uint _brightness;
	private uint _max_brightness;
	private File _max_b_file;
	private string _b_file_path;

	public string b_interface { get; private set; }

	public static Backlight get_default() {
		if (_instance == null) {
			_instance = new Backlight();
		}
		return _instance;
	}

	public uint brightness {
		get {
			return _brightness;
		}
		set {
			if (value < 0.0) {
				_brightness = 0;
			} else if (value > _max_brightness) {
				_brightness = _max_brightness;
			} else {
				_brightness = value;
			}
		}
	}

	public string icon_name { owned get; private set; }
	public double percentage { get; set; }

	construct {
		if (!load_interface()) {
			return;
		}
		load_m_b();
		load_b();

		this.bind_property("brightness", this, "percentage", BindingFlags.SYNC_CREATE, (_, src, ref trgt) => {
			trgt = brightness / (double)_max_brightness;
			return true;
		});

		icon_name = "display-brightness-symbolic";
	}

	private bool load_interface() {
		if (FileUtils.test("/sys/class/backlight/intel_backlight", FileTest.IS_DIR)) {
			b_interface = "intel_backlight";
			_b_file_path = "/sys/class/backlight/intel_backlight";
			return true;
		} else if (FileUtils.test("/sys/class/backlight/acpi_video0", FileTest.IS_DIR)) {
			b_interface = "acpi_video0";
			_b_file_path = "/sys/class/backlight/acpi_video0";
			return true;
		} else {
			critical("No supported backlight interface found");
			return false;
		}
	}

	private void load_m_b() {
		_max_b_file = File.new_for_path(@"$(_b_file_path)/max_brightness");
		if (_max_b_file.query_exists()) {
			try {
				uint8[] contents;
				string etag_out;
				if (_max_b_file.load_contents(null, out contents, out etag_out)) {
					string content = (string)contents;
					_max_brightness = uint.parse(content.strip());
				}
			} catch (Error e) {
				critical("Error reading max brightness: %s", e.message);
			}
		}
	}

	private void load_b() {
		try {
			_b_file = File.new_for_path(@"$(_b_file_path)/actual_brightness");
			_b_monitor = _b_file.monitor_file(FileMonitorFlags.NONE);
			_b_monitor.changed.connect((file, other_file, event_type) => sync_brightness.begin());

			sync_brightness.begin();
		} catch (Error e) {
			critical("Error setting up brightness monitor: %s", e.message);
		}
	}

	private async void sync_brightness() {
		_b_file.load_contents_async.begin(null, (obj, res) => {
			try {
				uint8[] contents;
				string etag_out;

				_b_file.load_contents_async.end(res, out contents, out etag_out);
				if (contents != null) {
					string content = (string)contents;
					brightness = uint.parse(content.strip());
				}
			} catch (Error e) {
				critical("Error reading brightness: %s", e.message);
			}
		});
	}
}
