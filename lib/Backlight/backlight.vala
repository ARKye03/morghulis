public class Backlight : Object {
	private static Backlight _instance;
	private FileMonitor? _b_monitor;
	private File _b_file;
	private uint _brightness;
	private double _percentage;
	private uint _max_brightness;
	private File _max_b_file;
	private string _b_file_path;
	private bool is_brightnessctl_a_thing = false;

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
	public double percentage {
		get { return _percentage; }
		set {
			if (value < 0.0) {
				_percentage = 0.0;
			} else if (value > 1.0) {
				_percentage = 1.0;
			} else {
				_percentage = value;
			}
			// Only apply brightness changes with brightnessctl after full initialization
			if (is_brightnessctl_a_thing) {
				try {
					Process.spawn_command_line_sync(@"brightnessctl -q set $(_percentage * 100)%");
				} catch (Error e) {
					critical("Failed to set brightness: %s", e.message);
				}
			}
		}
	}

	construct {
		if (!load_interface()) {
			return;
		}
		load_m_b();

		// First load brightness synchronously to avoid the 0 brightness problem
		load_brightness_sync();

		// Then set up monitoring for future changes
		load_b();
		check_brightnessctl();

		// Only set up binding after we have initial values
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
#if DEBUG
			critical("No supported backlight interface found");
#endif
			return false;
		}
	}

	private void check_brightnessctl() {
		try {
			string stdout_data, stderr_data;
			int exit_status;
			Process.spawn_command_line_sync("which brightnessctl",
											out stdout_data,
											out stderr_data,
											out exit_status);
			is_brightnessctl_a_thing = exit_status == 0;
		} catch (Error e) {
			warning("Failed to check for brightnessctl: %s", e.message);
			is_brightnessctl_a_thing = false;
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

	private void load_brightness_sync() {
		try {
			var file = File.new_for_path(@"$(_b_file_path)/actual_brightness");
			if (file.query_exists()) {
				uint8[] contents;
				string etag_out;
				if (file.load_contents(null, out contents, out etag_out)) {
					string content = (string)contents;
					_brightness = uint.parse(content.strip());
					_percentage = _brightness / (double)_max_brightness;
				}
			}
		} catch (Error e) {
			critical("Error reading initial brightness: %s", e.message);
		}
	}
}
