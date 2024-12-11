using GTop;

public class SysInfo : Gtk.Box {
	private AstalWp.Endpoint speaker { get; set; }


	construct {
		speaker = AstalWp.get_default().audio.default_speaker;

		var cpu_bar = new CpuMonitorBar();
		this.append(cpu_bar);

		var mem_bar = new MemMonitorBar();
		this.append(mem_bar);

		// Start the periodic update
		GLib.Timeout.add_seconds(3, () => {
			cpu_bar.update_cpu();
			mem_bar.update_mem();
			return true;
		});
	}
}

private class CpuMonitorBar : Gtk.Box {
	private GTop.Cpu ?cpu;
	private CircularProgressBar cpu_bar;
	private Gtk.Label cpu_label;

	private uint64 last_used;
	private uint64 last_total;
	private float load;

	construct {
		cpu_bar = new CircularProgressBar();
		cpu_label = new Gtk.Label("CPU");
		last_used = 0;
		last_total = 0;

		this.orientation = Gtk.Orientation.VERTICAL;

		cpu_bar.line_width = 10;
		cpu_bar.line_cap = Cairo.LineCap.ROUND;
		cpu_bar.content_height = 50;
		cpu_bar.content_width = 90;
		cpu_bar.percentage = 0;
		cpu_bar.hexpand = true;
		cpu_bar.vexpand = true;

		this.append(cpu_bar);
		this.append(cpu_label);
	}

	public void update_cpu() {
		// Get new CPU stats
		GTop.get_cpu(out cpu);

		// Calculate deltas using unsigned 64-bit arithmetic
		uint64 used = cpu.user + cpu.sys + cpu.nice + cpu.irq + cpu.softirq;
		uint64 total = used + cpu.idle + cpu.iowait;

		uint64 diff_used = used - last_used;
		uint64 diff_total = total - last_total;

		// Avoid division by zero and calculate load
		if (diff_total > 0) {
			load = (float)diff_used / (float)diff_total;
		}
		else {
			load = 0.0f;
		}

		// Update last values
		last_used = used;
		last_total = total;

		// Update the progress bar (clamp between 0-100%)
		cpu_bar.percentage = double.min(1.0, load);
	}
}

private class MemMonitorBar : Gtk.Box {
	private GTop.Memory ?mem;
	private CircularProgressBar mem_bar;
	private Gtk.Label mem_label;

	private uint64 available = 0;
	private uint64 real_used = 0;

	construct {
		mem_bar = new CircularProgressBar();
		mem_label = new Gtk.Label("Memory");

		this.orientation = Gtk.Orientation.VERTICAL;

		mem_bar.line_width = 10;
		mem_bar.line_cap = Cairo.LineCap.ROUND;
		mem_bar.content_height = 50;
		mem_bar.content_width = 90;
		mem_bar.percentage = 0;
		mem_bar.hexpand = true;
		mem_bar.vexpand = true;

		this.append(mem_bar);
		this.append(mem_label);
	}

	public void update_mem() {
		GTop.get_mem(out mem);

		available = mem.free + mem.buffer + mem.cached;
		real_used = mem.total - available;
		mem_bar.percentage = (double)real_used / mem.total;
	}
}
