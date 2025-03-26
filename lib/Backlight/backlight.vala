// Refactor this shite
public class Backlight : Object {
	private static Backlight _instance;
	private FileMonitor? _brightness_monitor;
	private uint _brightness;
	private double _percentage;
	private uint _max_brightness;
	private string _brightness_file_path;

	public string brightness_interface_name { get; private set; }

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
			if (value < 0) {
				_brightness = 0;
			} else if (value > _max_brightness) {
				_brightness = _max_brightness;
			} else {
				_brightness = value;
				set_brightness_file(_brightness);
			}
		}
	}

	public string icon_name { owned get; private set; default = "display-brightness-symbolic"; }
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
			uint new_brightness = (uint)(_percentage * _max_brightness);
			if (new_brightness != _brightness) {
				brightness = new_brightness;
			}
		}
	}

	construct {
		if (!load_interface()) {
			return;
		}

		load_max_brightness();
		load_brightness_sync();
		load_brightness();

		// Create bidirectional binding between brightness and percentage
		this.bind_property(
			"brightness", this, "percentage",
			BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
			(binding, src_val, ref target_val) => {
			uint brightness_val = (uint)src_val;
			target_val = brightness_val / (double)_max_brightness;
			return true;
		},
			(binding, src_val, ref target_val) => {
			double percentage_val = (double)src_val;
			target_val = (uint)(percentage_val * _max_brightness);
			return true;
		}
		);
	}

	private bool load_interface() {
		try {
			string? name = null;
			string[] interfaces = {};

			Dir dir = Dir.open("/sys/class/backlight", 0);
			if (dir == null) {
				debug("No backlight interface found");
				return false;
			}

			// Read all available interfaces (not just the first one)
			while ((name = dir.read_name()) != null) {
				if (name != "." && name != "..") {
					interfaces += name;
				}
			}

			if (interfaces.length == 0) {
				debug("No backlight interfaces found");
				return false;
			}

			// Use the first valid interface
			brightness_interface_name = interfaces[0];
			_brightness_file_path = "/sys/class/backlight/" + brightness_interface_name;
			debug("Using backlight interface: %s", brightness_interface_name);
			return true;
		} catch (FileError e) {
			if (e.code == FileError.NOENT) {
				debug("No backlight interface found");
				return false;
			} else {
				critical("Error opening backlight directory: %s", e.message);
				return false;
			}
		}
	}

	private bool set_brightness_file(uint value) {
		try {
			var file = File.new_for_path(@"$(_brightness_file_path)/brightness");
			if (file.query_exists()) {
				var os = file.replace(null, false, FileCreateFlags.NONE);
				var dos = new DataOutputStream(os);
				dos.put_string(value.to_string());
				debug("Set brightness file to: %u", value);
				return true;
			}
		} catch (Error e) {
			critical("Error writing brightness: %s", e.message);
		}
		return false;
	}

	private void load_max_brightness() {
		var max_brightness_file = File.new_for_path(@"$(_brightness_file_path)/max_brightness");
		if (max_brightness_file.query_exists()) {
			try {
				uint8[] contents;
				string etag_out;
				if (max_brightness_file.load_contents(null, out contents, out etag_out)) {
					string content = (string)contents;
					_max_brightness = uint.parse(content.strip());
					debug("Max brightness: %u", _max_brightness);
				}
			} catch (Error e) {
				critical("Error reading max brightness: %s", e.message);
			}
		}
	}

	private void load_brightness() {
		try {
			var brightness_file = File.new_for_path(@"$(_brightness_file_path)/brightness");

			_brightness_monitor = brightness_file.monitor_file(FileMonitorFlags.NONE);
			_brightness_monitor.changed.connect((file, other_file, event_type) => {
				if (event_type == FileMonitorEvent.CHANGED ||
					event_type == FileMonitorEvent.CREATED) {
					debug("Brightness file changed externally, syncing...");
					sync_brightness.begin(brightness_file);
				}
			});

			// Initial sync
			sync_brightness.begin(brightness_file);
		} catch (Error e) {
			critical("Error setting up brightness monitor: %s", e.message);
		}
	}

	private async void sync_brightness(File brightness_file) {
		try {
			uint8[] contents;
			string etag_out;

			yield brightness_file.load_contents_async(null, out contents, out etag_out);

			if (contents != null) {
				string content = (string)contents;
				uint new_brightness = uint.parse(content.strip());
				debug("External brightness change detected: %u", new_brightness);

				if (new_brightness != _brightness) {
					this.brightness = new_brightness;
				}
			}
		} catch (Error e) {
			critical("Error reading brightness: %s", e.message);
		}
	}

	private void load_brightness_sync() {
		try {
			var file = File.new_for_path(@"$(_brightness_file_path)/actual_brightness");
			if (!file.query_exists()) {
				file = File.new_for_path(@"$(_brightness_file_path)/brightness");
				if (!file.query_exists()) {
					critical("Cannot find brightness file");
					return;
				}
			}

			uint8[] contents;
			string etag_out;
			if (file.load_contents(null, out contents, out etag_out)) {
				string content = (string)contents;
				uint new_val = uint.parse(content.strip());
				brightness = new_val;
				debug("Initial brightness: %u (%.1f%%)", _brightness, _percentage * 100);
			}
		} catch (Error e) {
			critical("Error reading initial brightness: %s", e.message);
		}
	}
}
