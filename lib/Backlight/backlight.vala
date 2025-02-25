public class Backlight : Object {
	private static Backlight _instance;
	private FileMonitor _b_monitor;
	private File _b_file;
	private uint _brightness;
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
			} else if (value > 96000) {
				_brightness = 96000;
			} else {
				_brightness = value;
			}
		}
	}

	public string icon_name { owned get; private set; }

	construct {
		load_interface();

		_b_file = File.new_for_path(@"$(_b_file_path)/actual_brightness");
		if (_b_file.query_exists()) {
			try {
				_b_monitor = _b_file.monitor_file(GLib.FileMonitorFlags.NONE, null);
				_b_monitor.changed.connect((src, d, e) => load_b(src));
			} catch (IOError e) {
				critical("Error monitoring brightness file: %s", e.message);
			}
		}
	}

	private void load_interface() {
		if (FileUtils.test("/sys/class/backlight/intel_backlight", FileTest.IS_DIR)) {
			b_interface = "intel_backlight";
			_b_file_path = "/sys/class/backlight/intel_backlight";
		} else if (FileUtils.test("/sys/class/backlight/acpi_video0", FileTest.IS_DIR)) {
			b_interface = "acpi_video0";
			_b_file_path = "/sys/class/backlight/acpi_video0";
		} else {
			critical("No supported backlight interface found");
		}
	}

	private void load_b(File src) {
		uint8[] contents;
		string etag_out;
		try {
			if (src.load_contents(null, out contents, out etag_out)) {
				string content = (string)contents;
				brightness = uint.parse(content.strip());
			}
		} catch (Error e) {
			critical("Error reading brightness: %s", e.message);
		}
	}
}
