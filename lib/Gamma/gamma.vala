// wl_output's interface symbol is not exposed by wayland-client.vapi.
[CCode(cheader_filename = "wayland-client.h", cname = "wl_output_interface")]
private extern Wl.Interface wl_output_interface;

/**
 * Night light via wlr-gamma-control-unstable-v1.
 *
 * Holds a dedicated Wayland connection, binds the gamma-control manager and
 * every output, and uploads per-output gamma ramps. Toggling {@link night}
 * switches every output between a neutral day temperature and a warm night
 * temperature.
 */
public class Gamma : Object {
    public const int DAY_TEMP = 6500;

    private int _night_temp = 4000;
    public int night_temp {
        get { return _night_temp; }
        set {
            int v = value.clamp(2500, 6500);
            if (_night_temp == v) {
                return;
            }
            _night_temp = v;
            if (_night) {
                apply_all();
            }
        }
    }

    private static Gamma? instance;
    public static Gamma get_default() {
        if (instance == null) {
            instance = new Gamma();
        }
        return instance;
    }

    private bool _night = false;
    public bool night {
        get { return _night; }
        set {
            if (_night == value) {
                return;
            }
            _night = value;
            apply_all();
        }
    }

    private bool ready = false;
    private Wl.Display? display;
    private Wl.Registry registry;
    private ZwlrGammaControlManagerV1? manager;
    private GenericArray<Output> outputs = new GenericArray<Output>();
    private WaylandSource? source;

    private const Wl.RegistryListener registry_listener = {
        handle_global,
        handle_global_remove
    };

    construct {
        display = new Wl.Display.connect(null);
        if (display == null) {
            warning("gamma: could not connect to a Wayland display");
            return;
        }
        registry = display.get_registry();
        registry.add_listener(registry_listener, this);
        display.roundtrip(); // enumerate globals, create gamma controls
        display.roundtrip(); // receive gamma_size events

        if (manager == null) {
            warning("gamma: compositor does not implement wlr-gamma-control");
        }

        source = new WaylandSource(display);
        source.attach(null);

        ready = true;
        apply_all();
    }

    private void handle_global(Wl.Registry reg, uint32 name, string iface, uint32 version) {
        if (iface == "zwlr_gamma_control_manager_v1") {
            manager = reg.bind<ZwlrGammaControlManagerV1>(
                name, ref ZwlrGammaControlManagerV1.iface, uint.min(version, 1));
            for (uint i = 0; i < outputs.length; i++) {
                unowned Output o = outputs[i];
                o.ensure_control(manager);
            }
        } else if (iface == "wl_output") {
            var wl_output = reg.bind<Wl.Output>(
                name, ref wl_output_interface, uint.min(version, 4));
            var output = new Output(this, (owned) wl_output, name);
            output.ensure_control(manager);
            outputs.add(output);
        }
    }

    private void handle_global_remove(Wl.Registry reg, uint32 name) {
        for (uint i = 0; i < outputs.length; i++) {
            unowned Output o = outputs[i];
            if (o.global_name == name) {
                outputs.remove_index(i);
                return;
            }
        }
    }

    private int current_temp() {
        return _night ? _night_temp : DAY_TEMP;
    }

    // Re-apply the current temperature to a single output (e.g. once a
    // hot-plugged monitor reports its gamma size). Skipped during the initial
    // sync — construct's apply_all() covers the first batch and we must not
    // roundtrip re-entrantly from inside a dispatch.
    private void apply_single(Output o) {
        if (display == null || !ready) {
            return;
        }
        int fd = o.apply(current_temp());
        if (fd >= 0) {
            display.flush(); // flush transmits the fd; safe to close after
            Posix.close(fd);
        }
    }

    private void apply_all() {
        if (display == null) {
            return;
        }
        int temp = current_temp();
        int[] fds = {};
        for (uint i = 0; i < outputs.length; i++) {
            unowned Output o = outputs[i];
            int fd = o.apply(temp);
            if (fd >= 0) {
                fds += fd;
            }
        }
        display.flush();
        display.roundtrip();
        foreach (int fd in fds) {
            Posix.close(fd);
        }
    }

    // Blackbody approximation (Tanner Helland), returning each channel in [0, 1].
    public static void temperature_to_rgb(int temp, out double r, out double g, out double b) {
        double t = temp / 100.0;
        double red, green, blue;

        if (t <= 66) {
            red = 255;
        } else {
            red = 329.698727446 * GLib.Math.pow(t - 60, -0.1332047592);
        }

        if (t <= 66) {
            green = 99.4708025861 * GLib.Math.log(t) - 161.1195681661;
        } else {
            green = 288.1221695283 * GLib.Math.pow(t - 60, -0.0755148492);
        }

        if (t >= 66) {
            blue = 255;
        } else if (t <= 19) {
            blue = 0;
        } else {
            blue = 138.5177312231 * GLib.Math.log(t - 10) - 305.0447927307;
        }

        r = red.clamp(0, 255) / 255.0;
        g = green.clamp(0, 255) / 255.0;
        b = blue.clamp(0, 255) / 255.0;
    }

    private class Output : Object {
        private unowned Gamma gamma;
        public Wl.Output wl_output;
        public uint32 global_name;
        private ZwlrGammaControlV1? control;
        private uint32 gamma_size = 0;
        private bool failed = false;

        private const ZwlrGammaControlV1Listener gamma_listener = {
            handle_gamma_size,
            handle_failed
        };

        public Output(Gamma gamma, owned Wl.Output wl_output, uint32 global_name) {
            this.gamma = gamma;
            this.wl_output = (owned) wl_output;
            this.global_name = global_name;
        }

        public void ensure_control(ZwlrGammaControlManagerV1? manager) {
            if (manager == null || control != null) {
                return;
            }
            control = manager.get_gamma_control(wl_output);
            control.add_listener(gamma_listener, this);
        }

        private void handle_gamma_size(ZwlrGammaControlV1 c, uint32 size) {
            gamma_size = size;
            failed = false;
            gamma.apply_single(this);
        }

        private void handle_failed(ZwlrGammaControlV1 c) {
            failed = true;
        }

        // Builds and uploads the ramp; returns the fd (caller closes it after
        // the display is flushed), or -1 when nothing was sent.
        public int apply(int temp) {
            if (control == null || failed || gamma_size == 0) {
                return -1;
            }
            uint32 size = gamma_size;
            double r, g, b;
            Gamma.temperature_to_rgb(temp, out r, out g, out b);

            size_t n = (size_t) (3 * size * sizeof(uint16));
            int fd = Linux.memfd_create("morghulis-gamma", Linux.MemfdFlags.CLOEXEC);
            if (fd < 0) {
                return -1;
            }
            if (Posix.ftruncate(fd, (Posix.off_t) n) < 0) {
                Posix.close(fd);
                return -1;
            }

            uint16[] table = new uint16[3 * size];
            for (uint32 i = 0; i < size; i++) {
                double v = size > 1 ? (double) i / (double) (size - 1) : 0.0;
                table[i]            = (uint16) (v * r * 65535.0 + 0.5);
                table[size + i]     = (uint16) (v * g * 65535.0 + 0.5);
                table[2 * size + i] = (uint16) (v * b * 65535.0 + 0.5);
            }

            Posix.write(fd, (void*) table, n);
            Posix.lseek(fd, 0, Posix.SEEK_SET); // compositor reads from offset 0
            control.set_gamma(fd);
            return fd;
        }
    }
}
