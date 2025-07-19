[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/SysInfo/SysInfoCmd.ui")]
public class SysInfo : Gtk.Box {
	[GtkChild]
	private unowned Gtk.Grid main_grid;

	private CpuMonitorItem cpu_monitor;
	private MemoryMonitorItem memory_monitor;
	private SwapMonitorItem swap_monitor;
	private LoadAverageItem load_monitor;
	private NetworkMonitorItem network_monitor;
	private DiskMonitorItem disk_monitor;
	private ProcessCountItem process_monitor;
	private SysInfoData system_info;

	construct {
		// Initialize all monitors
		cpu_monitor = new CpuMonitorItem();
		memory_monitor = new MemoryMonitorItem();
		swap_monitor = new SwapMonitorItem();
		load_monitor = new LoadAverageItem();
		network_monitor = new NetworkMonitorItem();
		disk_monitor = new DiskMonitorItem();
		process_monitor = new ProcessCountItem();
		system_info = new SysInfoData();

		// Layout in grid - 3 columns
		main_grid.attach(system_info, 0, 0, 2, 1);
		main_grid.attach(cpu_monitor, 2, 0, 1, 1);

		main_grid.attach(memory_monitor, 0, 1, 1, 1);
		main_grid.attach(swap_monitor, 1, 1, 1, 1);
		main_grid.attach(disk_monitor, 2, 1, 1, 1);

		main_grid.attach(load_monitor, 0, 2, 1, 1);
		main_grid.attach(network_monitor, 1, 2, 1, 1);
		main_grid.attach(process_monitor, 2, 2, 1, 1);
	}

	public void update_all() {
		cpu_monitor.update();
		memory_monitor.update();
		swap_monitor.update();
		load_monitor.update();
		network_monitor.update();
		disk_monitor.update();
		process_monitor.update();
	}
}

private class CpuMonitorItem : SysInfoItem {
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

private class MemoryMonitorItem : SysInfoItem {
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

private class SwapMonitorItem : SysInfoItem {
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

private class LoadAverageItem : SysInfoItem {
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

private class NetworkMonitorItem : SysInfoItem {
	private GTop.NetLoad? netload;
	private uint64 last_bytes_in = 0;
	private uint64 last_bytes_out = 0;
	private string? active_interface = null;
	private bool interface_found = false;

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
						active_interface = preferred;
						interface_found = true;
						return;
					}
				}
			}

			foreach (string iface in found_interfaces) {
				if (is_interface_active(iface)) {
					active_interface = iface;
					interface_found = true;
					return;
				}
			}

			active_interface = "lo";
			interface_found = true;
		} catch (Error e) {
			active_interface = "lo";
			interface_found = true;
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
		if (!interface_found || active_interface == null) {
			set_details("No interface");
			set_percentage(0);
			return;
		}

		GTop.get_netload(out netload, active_interface);

		uint64 current_bytes_in = netload.bytes_in;
		uint64 current_bytes_out = netload.bytes_out;

		uint64 diff_in = 0;
		uint64 diff_out = 0;

		if (last_bytes_in > 0 && last_bytes_out > 0) {
			diff_in = current_bytes_in - last_bytes_in;
			diff_out = current_bytes_out - last_bytes_out;
		}

		uint64 total_diff = diff_in + diff_out;
		double percentage = Math.fmin((double)total_diff / (1024.0 * 1024.0), 1.0);

		set_percentage(percentage);

		if (diff_in == 0 && diff_out == 0 && last_bytes_in > 0) {
			set_details("Idle (%s)".printf(active_interface));
		} else {
			set_details("↓%.1f KB/s ↑%.1f KB/s\n(%s)".printf(
							diff_in / 1024.0,
							diff_out / 1024.0,
							active_interface
			));
		}

		last_bytes_in = current_bytes_in;
		last_bytes_out = current_bytes_out;
	}
}

private class DiskMonitorItem : SysInfoItem {
	private GTop.FsUsage? fsusage;

	public DiskMonitorItem() {
		base("Disk Usage", "device-floppy-symbolic");
	}

	public override void update() {
		GTop.get_fsusage(out fsusage, "/");

		if (fsusage.blocks > 0) {
			double percentage = (double)fsusage.bavail / fsusage.blocks;
			percentage = 1.0 - percentage;                                                                                                                                                                                                                                                                                                                                                                                     // Invert to show used space

			set_percentage(percentage);
			set_details("%.1f GB / %.1f GB".printf(
							(fsusage.blocks - fsusage.bavail) * fsusage.block_size / (1024.0 * 1024.0 * 1024.0),
							fsusage.blocks * fsusage.block_size / (1024.0 * 1024.0 * 1024.0)
			));
		}
	}
}

private class ProcessCountItem : SysInfoItem {
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
