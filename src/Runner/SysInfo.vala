public class SysInfo : Gtk.Box {
	private SystemDashboard dashboard;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 12;
		this.margin_top = 12;
		this.margin_bottom = 12;
		this.margin_start = 12;
		this.margin_end = 12;

		dashboard = new SystemDashboard();
		this.append(dashboard);

		// Start the periodic update
		GLib.Timeout.add_seconds(2, () => {
			dashboard.update_all();
			return true;
		});
	}
}

private class SystemDashboard : Gtk.Box {
	// System info components
	private CpuMonitorBar cpu_monitor;
	private MemoryMonitorBar memory_monitor;
	private SwapMonitorBar swap_monitor;
	private LoadAverageBar load_monitor;
	private NetworkMonitorBar network_monitor;
	private DiskMonitorBar disk_monitor;
	private ProcessCountBar process_monitor;
	private UptimeInfoBox uptime_info;
	private SystemInfoBox system_info;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 16;

		// Create main grid for organized layout
		var main_grid = new Gtk.Grid();
		main_grid.row_spacing = 16;
		main_grid.column_spacing = 16;
		main_grid.column_homogeneous = true;

		// Initialize all monitors
		cpu_monitor = new CpuMonitorBar();
		memory_monitor = new MemoryMonitorBar();
		swap_monitor = new SwapMonitorBar();
		load_monitor = new LoadAverageBar();
		network_monitor = new NetworkMonitorBar();
		disk_monitor = new DiskMonitorBar();
		process_monitor = new ProcessCountBar();
		uptime_info = new UptimeInfoBox();
		system_info = new SystemInfoBox();

		// Layout in grid - 3 columns
		main_grid.attach(cpu_monitor, 0, 0, 1, 1);
		main_grid.attach(memory_monitor, 1, 0, 1, 1);
		main_grid.attach(swap_monitor, 2, 0, 1, 1);

		main_grid.attach(load_monitor, 0, 1, 1, 1);
		main_grid.attach(network_monitor, 1, 1, 1, 1);
		main_grid.attach(disk_monitor, 2, 1, 1, 1);

		main_grid.attach(process_monitor, 0, 2, 1, 1);
		main_grid.attach(uptime_info, 1, 2, 1, 1);
		main_grid.attach(system_info, 2, 2, 1, 1);

		this.append(main_grid);
	}

	public void update_all() {
		cpu_monitor.update();
		memory_monitor.update();
		swap_monitor.update();
		load_monitor.update();
		network_monitor.update();
		disk_monitor.update();
		process_monitor.update();
		uptime_info.update();
		system_info.update();
	}
}

private class CpuMonitorBar : Gtk.Box {
	private GTop.Cpu? cpu;
	private CircularProgressBar cpu_bar;
	private Gtk.Label cpu_label;
	private Gtk.Label cpu_details;

	private uint64 last_used;
	private uint64 last_total;
	private float load;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		cpu_bar = new CircularProgressBar();
		cpu_label = new Gtk.Label("CPU Usage");
		cpu_details = new Gtk.Label("0%");

		cpu_bar.line_width = 8;
		cpu_bar.line_cap = Gsk.LineCap.ROUND;
		cpu_bar.percentage = 0;
		cpu_bar.set_size_request(80, 80);

		cpu_label.add_css_class("title-4");
		cpu_details.add_css_class("caption");

		this.append(cpu_bar);
		this.append(cpu_label);
		this.append(cpu_details);
	}

	public void update() {
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

		cpu_bar.percentage = double.min(1.0, load);
		cpu_details.label = "%.1f%%".printf(load * 100);
	}
}

private class MemoryMonitorBar : Gtk.Box {
	private GTop.Memory? mem;
	private CircularProgressBar mem_bar;
	private Gtk.Label mem_label;
	private Gtk.Label mem_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		mem_bar = new CircularProgressBar();
		mem_label = new Gtk.Label("Memory");
		mem_details = new Gtk.Label("0 GB / 0 GB");

		mem_bar.line_width = 8;
		mem_bar.line_cap = Gsk.LineCap.ROUND;
		mem_bar.percentage = 0;
		mem_bar.set_size_request(80, 80);

		mem_label.add_css_class("title-4");
		mem_details.add_css_class("caption");

		this.append(mem_bar);
		this.append(mem_label);
		this.append(mem_details);
	}

	public void update() {
		GTop.get_mem(out mem);

		uint64 available = mem.free + mem.buffer + mem.cached;
		uint64 used = mem.total - available;
		double percentage = (double)used / mem.total;

		mem_bar.percentage = percentage;
		mem_details.label = "%.1f GB / %.1f GB".printf(
			used / (1024.0 * 1024.0 * 1024.0),
			mem.total / (1024.0 * 1024.0 * 1024.0)
		);
	}
}

private class SwapMonitorBar : Gtk.Box {
	private GTop.Swap? swap;
	private CircularProgressBar swap_bar;
	private Gtk.Label swap_label;
	private Gtk.Label swap_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		swap_bar = new CircularProgressBar();
		swap_label = new Gtk.Label("Swap");
		swap_details = new Gtk.Label("0 GB / 0 GB");

		swap_bar.line_width = 8;
		swap_bar.line_cap = Gsk.LineCap.ROUND;
		swap_bar.percentage = 0;
		swap_bar.set_size_request(80, 80);

		swap_label.add_css_class("title-4");
		swap_details.add_css_class("caption");

		this.append(swap_bar);
		this.append(swap_label);
		this.append(swap_details);
	}

	public void update() {
		GTop.get_swap(out swap);

		if (swap.total > 0) {
			double percentage = (double)swap.used / swap.total;
			swap_bar.percentage = percentage;
			swap_details.label = "%.1f GB / %.1f GB".printf(
				swap.used / (1024.0 * 1024.0 * 1024.0),
				swap.total / (1024.0 * 1024.0 * 1024.0)
			);
		} else {
			swap_bar.percentage = 0;
			swap_details.label = "No swap";
		}
	}
}

private class LoadAverageBar : Gtk.Box {
	private GTop.LoadAvg? loadavg;
	private CircularProgressBar load_bar;
	private Gtk.Label load_label;
	private Gtk.Label load_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		load_bar = new CircularProgressBar();
		load_label = new Gtk.Label("Load Average");
		load_details = new Gtk.Label("0.00");

		load_bar.line_width = 8;
		load_bar.line_cap = Gsk.LineCap.ROUND;
		load_bar.percentage = 0;
		load_bar.set_size_request(80, 80);

		load_label.add_css_class("title-4");
		load_details.add_css_class("caption");

		this.append(load_bar);
		this.append(load_label);
		this.append(load_details);
	}

	public void update() {
		GTop.get_loadavg(out loadavg);

		// Normalize load average to percentage (assuming 4 cores max for display)
		double load_1min = loadavg.loadavg[0];
		double percentage = Math.fmin(load_1min / 4.0, 1.0);

		load_bar.percentage = percentage;
		load_details.label = "%.2f, %.2f, %.2f".printf(
			loadavg.loadavg[0],
			loadavg.loadavg[1],
			loadavg.loadavg[2]
		);
	}
}

private class NetworkMonitorBar : Gtk.Box {
	private GTop.NetLoad? netload;
	private CircularProgressBar net_bar;
	private Gtk.Label net_label;
	private Gtk.Label net_details;
	private uint64 last_bytes_in = 0;
	private uint64 last_bytes_out = 0;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		net_bar = new CircularProgressBar();
		net_label = new Gtk.Label("Network");
		net_details = new Gtk.Label("0 KB/s");

		net_bar.line_width = 8;
		net_bar.line_cap = Gsk.LineCap.ROUND;
		net_bar.percentage = 0;
		net_bar.set_size_request(80, 80);

		net_label.add_css_class("title-4");
		net_details.add_css_class("caption");

		this.append(net_bar);
		this.append(net_label);
		this.append(net_details);
	}

	public void update() {
		GTop.get_netload(out netload, "lo");                                                                         // Get loopback as fallback

		// Try to get main network interface
		string[] interfaces = { "eth0", "wlan0", "enp0s3", "wlp2s0" };
		foreach (string iface in interfaces) {
			try {
				GTop.get_netload(out netload, iface);
				break;
			} catch (Error e) {
				continue;
			}
		}

		uint64 current_total = netload.bytes_in + netload.bytes_out;
		uint64 diff = current_total - (last_bytes_in + last_bytes_out);

		// Normalize to percentage based on typical network usage (10MB/s = 100%)
		double percentage = Math.fmin((double)diff / (10.0 * 1024 * 1024), 1.0);

		net_bar.percentage = percentage;
		net_details.label = "↓%.1f KB/s ↑%.1f KB/s".printf(
			(netload.bytes_in - last_bytes_in) / 1024.0,
			(netload.bytes_out - last_bytes_out) / 1024.0
		);

		last_bytes_in = netload.bytes_in;
		last_bytes_out = netload.bytes_out;
	}
}

private class DiskMonitorBar : Gtk.Box {
	private GTop.FsUsage? fsusage;
	private CircularProgressBar disk_bar;
	private Gtk.Label disk_label;
	private Gtk.Label disk_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		disk_bar = new CircularProgressBar();
		disk_label = new Gtk.Label("Disk Usage");
		disk_details = new Gtk.Label("0 GB / 0 GB");

		disk_bar.line_width = 8;
		disk_bar.line_cap = Gsk.LineCap.ROUND;
		disk_bar.percentage = 0;
		disk_bar.set_size_request(80, 80);

		disk_label.add_css_class("title-4");
		disk_details.add_css_class("caption");

		this.append(disk_bar);
		this.append(disk_label);
		this.append(disk_details);
	}

	public void update() {
		try {
			GTop.get_fsusage(out fsusage, "/");

			if (fsusage.blocks > 0) {
				double percentage = (double)fsusage.bavail / fsusage.blocks;
				percentage = 1.0 - percentage;                                                                                                                                                 // Invert to show used space

				disk_bar.percentage = percentage;
				disk_details.label = "%.1f GB / %.1f GB".printf(
					(fsusage.blocks - fsusage.bavail) * fsusage.block_size / (1024.0 * 1024.0 * 1024.0),
					fsusage.blocks * fsusage.block_size / (1024.0 * 1024.0 * 1024.0)
				);
			}
		} catch (Error e) {
			disk_bar.percentage = 0;
			disk_details.label = "N/A";
		}
	}
}

private class ProcessCountBar : Gtk.Box {
	private GTop.ProcList? proclist;
	private CircularProgressBar proc_bar;
	private Gtk.Label proc_label;
	private Gtk.Label proc_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;

		proc_bar = new CircularProgressBar();
		proc_label = new Gtk.Label("Processes");
		proc_details = new Gtk.Label("0 running");

		proc_bar.line_width = 8;
		proc_bar.line_cap = Gsk.LineCap.ROUND;
		proc_bar.percentage = 0;
		proc_bar.set_size_request(80, 80);

		proc_label.add_css_class("title-4");
		proc_details.add_css_class("caption");

		this.append(proc_bar);
		this.append(proc_label);
		this.append(proc_details);
	}

	public void update() {
		GTop.get_proclist(out proclist, GTop.GLIBTOP_KERN_PROC_ALL, 0);

		uint64 process_count = proclist.number;
		// Normalize to percentage (500 processes = 100%)
		double percentage = Math.fmin((double)process_count / 500.0, 1.0);

		proc_bar.percentage = percentage;
		proc_details.label = "%llu processes".printf(process_count);
	}
}

private class UptimeInfoBox : Gtk.Box {
	private GTop.Uptime? uptime;
	private Gtk.Label uptime_label;
	private Gtk.Label uptime_details;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;
		this.halign = Gtk.Align.CENTER;

		uptime_label = new Gtk.Label("Uptime");
		uptime_details = new Gtk.Label("0d 0h 0m");

		uptime_label.add_css_class("title-4");
		uptime_details.add_css_class("caption");

		this.append(uptime_label);
		this.append(uptime_details);
	}

	public void update() {
		GTop.get_uptime(out uptime);

		uint64 seconds = (uint64)uptime.uptime;
		uint64 days = seconds / 86400;
		uint64 hours = (seconds % 86400) / 3600;
		uint64 minutes = (seconds % 3600) / 60;

		uptime_details.label = "%llud %lluh %llum".printf(days, hours, minutes);
	}
}

private class SystemInfoBox : Gtk.Box {
	private Gtk.Label sys_label;
	private Gtk.Label sys_details;
	private uint cpu_count = 0;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 8;
		this.halign = Gtk.Align.CENTER;

		sys_label = new Gtk.Label("System");
		sys_details = new Gtk.Label("Loading...");

		sys_label.add_css_class("title-4");
		sys_details.add_css_class("caption");

		this.append(sys_label);
		this.append(sys_details);

		// Get CPU count once at startup
		get_cpu_count();
	}

	private void get_cpu_count() {
		try {
			string contents;
			FileUtils.get_contents("/proc/cpuinfo", out contents);

			string[] lines = contents.split("\n");
			foreach (string line in lines) {
				if (line.has_prefix("processor")) {
					cpu_count++;
				}
			}
		} catch (Error e) {
			cpu_count = 1;             // Fallback to 1 CPU
		}
	}

	public void update() {
		sys_details.label = "%u CPUs\n%s".printf(
			cpu_count,
			Environment.get_host_name() ?? "Unknown"
		);
	}
}
