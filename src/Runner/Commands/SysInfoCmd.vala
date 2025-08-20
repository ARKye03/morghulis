[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/SysInfoCmd.ui")]
public class SysInfo : Gtk.Box, ICommand {
	// System info properties
	public string hostname { get; set; }
	public string kernel { get; set; }
	public string distro { get; set; }
	public string desktop { get; set; }
	public string display { get; set; }

	// Monitor items
	private CpuMonitorItem _cpu_monitor;
	private MemoryMonitorItem _memory_monitor;
	private SwapMonitorItem _swap_monitor;
	private LoadAverageItem _load_monitor;
	private NetworkMonitorItem _network_monitor;
	private DiskMonitorItem _disk_monitor;
	private ProcessCountItem _process_monitor;

	// Update timeout for periodic updates
	private uint _update_timeout = 0;

	[GtkChild]
	private unowned Gtk.Grid main_grid;

	construct {
		// Gather system information first
		gather_system_info();

		// Create monitor items
		_cpu_monitor = new CpuMonitorItem();
		_memory_monitor = new MemoryMonitorItem();
		_swap_monitor = new SwapMonitorItem();
		_load_monitor = new LoadAverageItem();
		_network_monitor = new NetworkMonitorItem();
		_disk_monitor = new DiskMonitorItem();
		_process_monitor = new ProcessCountItem();

		// Layout in grid - system info takes 2 columns in first row
		main_grid.attach(_cpu_monitor, 2, 0, 1, 1);

		main_grid.attach(_memory_monitor, 0, 1, 1, 1);
		main_grid.attach(_swap_monitor, 1, 1, 1, 1);
		main_grid.attach(_disk_monitor, 2, 1, 1, 1);

		main_grid.attach(_load_monitor, 0, 2, 1, 1);
		main_grid.attach(_network_monitor, 1, 2, 1, 1);
		main_grid.attach(_process_monitor, 2, 2, 1, 1);
	}

	private void gather_system_info() {
		try {
			string contents;
			FileUtils.get_contents("/etc/hostname", out contents);
			hostname = contents.strip();
		} catch (Error e) {
			hostname = Environment.get_host_name();
		}

		// Get distro info
		try {
			string contents;
			if (FileUtils.get_contents("/etc/os-release", out contents)) {
				string[] lines = contents.split("\n");
				foreach (string line in lines) {
					if (line.has_prefix("PRETTY_NAME=")) {
						distro = line.substring(12).replace("\"", "");
						break;
					}
				}
			}
		} catch (Error e) {
			distro = "Unknown Linux";
		}

		// Get kernel info
		try {
			string output;
			Process.spawn_command_line_sync("uname -r", out output);
			kernel = output.strip();
		} catch (Error e) {
			kernel = "Unknown";
		}

		// Detect display server and desktop environment
		detect_display_environment();
	}

	private void detect_display_environment() {
		string display_server = "Unknown";
		string desktop_env = "";

		// Check for Wayland
		if (Environment.get_variable("WAYLAND_DISPLAY") != null) {
			display_server = "Wayland";

			// Try to detect Wayland compositor
			string? compositor = Environment.get_variable("XDG_CURRENT_DESKTOP");
			if (compositor == null) {
				compositor = Environment.get_variable("DESKTOP_SESSION");
			}

			if (compositor != null) {
				desktop_env = compositor;
			} else {
				// Try to detect specific compositors
				if (Environment.get_variable("HYPRLAND_INSTANCE_SIGNATURE") != null) {
					desktop_env = "Hyprland";
				} else if (Environment.get_variable("SWAYSOCK") != null) {
					desktop_env = "Sway";
				}
			}
		}
		// Check for X11
		else if (Environment.get_variable("DISPLAY") != null) {
			display_server = "X11";

			string? desktop = Environment.get_variable("XDG_CURRENT_DESKTOP");
			if (desktop == null) {
				desktop = Environment.get_variable("DESKTOP_SESSION");
			}

			if (desktop != null) {
				desktop_env = desktop;
			}
		}

		display = display_server;
		if (desktop_env != "") {
			desktop = desktop_env;
		}
	}

	public void update_all() {
		_cpu_monitor.update();
		_memory_monitor.update();
		_swap_monitor.update();
		_load_monitor.update();
		_network_monitor.update();
		_disk_monitor.update();
		_process_monitor.update();
	}

	// ICommand interface implementation
	public string icon_name { get { return "linux-symbolic"; } }

	public void handle_input(string input) {
		// SysInfo doesn't need to handle input filtering
		// but we could potentially add search functionality here
	}

	public void on_activate() {
		// Update immediately when activated
		update_all();

		// Start periodic updates every 3 seconds
		if (_update_timeout == 0) {
			_update_timeout = Timeout.add_seconds(3, () => {
				update_all();
				return true;                                                 // Continue the timeout
			});
		}
	}

	public void on_deactivate() {
		// Stop periodic updates when deactivated
		if (_update_timeout > 0) {
			Source.remove(_update_timeout);
			_update_timeout = 0;
		}
	}

	public void on_enter() {
		// SysInfo doesn't need special Enter handling
		// Could potentially copy system info to clipboard here
	}

	~SysInfo() {
		// Clean up timeout on destruction
		if (_update_timeout > 0) {
			Source.remove(_update_timeout);
		}
	}
}

public class CpuMonitorItem : SysInfoItem {
	private GTop.Cpu? cpu;
	private uint64 last_used;
	private uint64 last_total;
	private float load;

	public CpuMonitorItem() {
		base("CPU Usage", "cpu-symbolic");
	}

	public override void update() {
		GTop.get_cpu(out cpu);

		uint64 used = cpu.user + cpu.sys + cpu.nice + cpu.irq + cpu.softirq;
		uint64 total = used + cpu.idle + cpu.iowait;

		uint64 diff_used = used - last_used;
		uint64 diff_total = total - last_total;

		if (diff_total > 0) {
			load = (float)diff_used / (float)diff_total;
		} else {
			load = 0.0f;
		}

		last_used = used;
		last_total = total;

		set_percentage(double.min(1.0, load));
		set_details("%.1f%%".printf(load * 100));
	}
}

public class MemoryMonitorItem : SysInfoItem {
	private GTop.Memory? mem;

	public MemoryMonitorItem() {
		base("Memory", "mem-ram-symbolic");
	}

	public override void update() {
		GTop.get_mem(out mem);

		uint64 available = mem.free + mem.buffer + mem.cached;
		uint64 used = mem.total - available;
		double percentage = (double)used / mem.total;

		set_percentage(percentage);
		set_details("%.1f GB / %.1f GB".printf(
						used / (1024.0 * 1024.0 * 1024.0),
						mem.total / (1024.0 * 1024.0 * 1024.0)
		));
	}
}

public class SwapMonitorItem : SysInfoItem {
	private GTop.Swap? swap;

	public SwapMonitorItem() {
		base("Swap", "swap-ram-symbolic");
	}

	public override void update() {
		GTop.get_swap(out swap);

		if (swap.total > 0) {
			double percentage = (double)swap.used / swap.total;
			set_percentage(percentage);
			set_details("%.1f GB / %.1f GB".printf(
							swap.used / (1024.0 * 1024.0 * 1024.0),
							swap.total / (1024.0 * 1024.0 * 1024.0)
			));
		} else {
			set_percentage(0);
			set_details("No swap");
		}
	}
}

public class LoadAverageItem : SysInfoItem {
	private GTop.LoadAvg? loadavg;

	public LoadAverageItem() {
		base("Load Average", "timeline-symbolic");
	}

	public override void update() {
		GTop.get_loadavg(out loadavg);

		// Normalize load average to percentage (assuming 4 cores max for display)
		double load_1min = loadavg.loadavg[0];
		double percentage = Math.fmin(load_1min / 4.0, 1.0);

		set_percentage(percentage);
		set_details("%.2f, %.2f, %.2f".printf(
						loadavg.loadavg[0],
						loadavg.loadavg[1],
						loadavg.loadavg[2]
		));
	}
}

public class NetworkMonitorItem : SysInfoItem {
	private GTop.NetLoad? _netload;
	private uint64 _last_bytes_in = 0;
	private uint64 _last_bytes_out = 0;
	private string? _active_interface = null;
	private bool _interface_found = false;
	private double _max_bytes_per_second = 1024.0 * 1024.0;
	private const double UPDATE_INTERVAL = 3.0;

	public NetworkMonitorItem() {
		base("Network", "network-symbolic");
		set_details("Detecting...");
		find_network_interface();
	}

	private void find_network_interface() {
		try {
			var net_dir = File.new_for_path("/sys/class/net");
			var enumerator = net_dir.enumerate_children("standard::name", FileQueryInfoFlags.NONE);

			FileInfo? info = null;
			string[] preferred_interfaces = { "wlan0", "eth0", "enp0s3", "wlp2s0", "eno1", "wlo1" };
			string[] found_interfaces = {};

			while ((info = enumerator.next_file()) != null) {
				string iface_name = info.get_name();
				if (iface_name != "lo") {
					found_interfaces += iface_name;
				}
			}

			foreach (string preferred in preferred_interfaces) {
				if (preferred in found_interfaces) {
					if (is_interface_active(preferred)) {
						_active_interface = preferred;
						_interface_found = true;
						return;
					}
				}
			}

			foreach (string iface in found_interfaces) {
				if (is_interface_active(iface)) {
					_active_interface = iface;
					_interface_found = true;
					return;
				}
			}

			_active_interface = "lo";
			_interface_found = true;
		} catch (Error e) {
			_active_interface = "lo";
			_interface_found = true;
		}
	}

	private bool is_interface_active(string interface_name) {
		try {
			string operstate_path = "/sys/class/net/%s/operstate".printf(interface_name);
			string contents;
			FileUtils.get_contents(operstate_path, out contents);
			return contents.strip() == "up";
		} catch (Error e) {
			return true;
		}
	}

	public override void update() {
		if (!_interface_found || _active_interface == null) {
			set_details("No interface");
			set_percentage(0);
			return;
		}

		GTop.get_netload(out _netload, _active_interface);

		uint64 current_bytes_in = _netload.bytes_in;
		uint64 current_bytes_out = _netload.bytes_out;

		uint64 diff_in = 0;
		uint64 diff_out = 0;

		if (_last_bytes_in > 0 && _last_bytes_out > 0) {
			diff_in = current_bytes_in - _last_bytes_in;
			diff_out = current_bytes_out - _last_bytes_out;
		}

		// Calculate current bytes per second
		uint64 total_diff = diff_in + diff_out;
		double current_bytes_per_second = (double)total_diff / UPDATE_INTERVAL;

		// Update maximum if current activity is higher
		if (current_bytes_per_second > _max_bytes_per_second) {
			_max_bytes_per_second = current_bytes_per_second;
		}

		// Calculate percentage based on adaptive maximum
		double percentage = 0.0;
		if (_max_bytes_per_second > 0) {
			percentage = Math.fmin(current_bytes_per_second / _max_bytes_per_second, 1.0);
		}

		set_percentage(percentage);

		if (diff_in == 0 && diff_out == 0 && _last_bytes_in > 0) {
			set_details("Idle (%s)".printf(_active_interface));
		} else {
			// Show current speed and peak speed
			double current_mbps = current_bytes_per_second * 8.0 / (1024.0 * 1024.0);                                                                                                                                     // Convert to Mbps
			double peak_mbps = _max_bytes_per_second * 8.0 / (1024.0 * 1024.0);

			set_details("↓%.1f KB/s ↑%.1f KB/s\n%.1f/%.1f Mbps (%s)".printf(
							diff_in / 1024.0,
							diff_out / 1024.0,
							current_mbps,
							peak_mbps,
							_active_interface
			));
		}

		_last_bytes_in = current_bytes_in;
		_last_bytes_out = current_bytes_out;
	}
}

public class DiskMonitorItem : SysInfoItem {
	private GTop.FsUsage? fsusage;

	public DiskMonitorItem() {
		base("Disk Usage", "device-floppy-symbolic");
	}

	public override void update() {
		GTop.get_fsusage(out fsusage, "/");

		if (fsusage.blocks > 0) {
			double percentage = (double)fsusage.bavail / fsusage.blocks;
			percentage = 1.0 - percentage;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             // Invert to show used space

			set_percentage(percentage);
			set_details("%.1f GB / %.1f GB".printf(
							(fsusage.blocks - fsusage.bavail) * fsusage.block_size / (1024.0 * 1024.0 * 1024.0),
							fsusage.blocks * fsusage.block_size / (1024.0 * 1024.0 * 1024.0)
			));
		}
	}
}

public class ProcessCountItem : SysInfoItem {
	private GTop.ProcList? proclist;

	public ProcessCountItem() {
		base("Processes", "timeline-symbolic");
	}

	public override void update() {
		GTop.get_proclist(out proclist, GTop.GLIBTOP_KERN_PROC_ALL, 0);

		uint64 process_count = proclist.number;
		// Normalize to percentage (500 processes = 100%)
		double percentage = Math.fmin((double)process_count / 500.0, 1.0);

		set_percentage(percentage);
		set_details("%llu processes".printf(process_count));
	}
}
