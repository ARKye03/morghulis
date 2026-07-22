// wl_seat's interface symbol is not exposed by wayland-client.vapi.
[CCode(cheader_filename = "wayland-client.h", cname = "wl_seat_interface")]
private extern Wl.Interface wl_seat_interface;

/** A single clipboard history entry. */
public class ClipboardEntry : Object {
    public string mime { get; construct; }
    public Bytes data { get; construct; }
    public bool is_text { get; construct; }
    public string preview { get; construct; }
    public int64 timestamp { get; construct; }

    public ClipboardEntry(string mime, Bytes data, bool is_text, string preview, int64 timestamp) {
        Object(mime: mime, data: data, is_text: is_text, preview: preview, timestamp: timestamp);
    }
}

/**
 * Clipboard history via ext-data-control-v1.
 *
 * Watches the regular selection on a dedicated Wayland connection, records
 * each new selection into a capped, de-duplicated, disk-persisted history,
 * and can re-publish any stored entry as the current selection.
 */
public class Clipboard : Object {
    private const int MAX_PAYLOAD = 5 * 1024 * 1024; // cap a single entry at 5 MB
    private const int READ_TIMEOUT_MS = 1000;
    private const string[] TEXT_MIMES = {
        "text/plain;charset=utf-8", "text/plain", "UTF8_STRING", "STRING", "TEXT"
    };
    private const string[] IMAGE_MIMES = { "image/png", "image/jpeg", "image/bmp" };

    private static Clipboard? instance;
    public static Clipboard get_default() {
        if (instance == null) {
            instance = new Clipboard();
        }
        return instance;
    }

    public ListStore history { get; private set; }

    private uint _max_entries = 50;
    private bool _persist = true;
    private bool _watching = false;
    public bool watching {
        get { return _watching; }
        set {
            if (_watching == value) {
                return;
            }
            _watching = value;
            if (_watching) {
                ensure_device();
            } else if (device != null) {
                device.destroy();
                device = null;
            }
        }
    }

    private Wl.Display? display;
    private Wl.Registry registry;
    private Wl.Seat? seat;
    private ExtDataControlManagerV1? manager;
    private ExtDataControlDeviceV1? device;
    private WaylandSource? source;

    private OfferData? pending;
    private GenericArray<SourceData> active_sources = new GenericArray<SourceData>();
    private bool ignore_next = false;

    private const Wl.RegistryListener registry_listener = {
        handle_global,
        handle_global_remove
    };
    private const ExtDataControlDeviceV1Listener device_listener = {
        handle_data_offer,
        handle_selection,
        handle_finished,
        handle_primary_selection
    };

    construct {
        history = new ListStore(typeof(ClipboardEntry));

        var settings = Morghulis.gsettings;
        _max_entries = uint.max(1, settings.get_uint("clipboard-max-entries"));
        _persist = settings.get_boolean("clipboard-persist");
        settings.changed["clipboard-max-entries"].connect(() => {
            _max_entries = uint.max(1, settings.get_uint("clipboard-max-entries"));
            trim_history();
            save_history();
        });
        settings.changed["clipboard-persist"].connect(() => {
            _persist = settings.get_boolean("clipboard-persist");
            if (_persist) {
                save_history();
            }
        });

        if (_persist) {
            load_history();
        }

        display = new Wl.Display.connect(Environment.get_variable("WAYLAND_DISPLAY") ?? "wayland-0");
        if (display == null) {
            warning("clipboard: could not connect to a Wayland display");
            return;
        }
        registry = display.get_registry();
        registry.add_listener(registry_listener, this);
        display.roundtrip();

        if (manager == null) {
            warning("clipboard: compositor does not implement ext-data-control");
            return;
        }

        source = new WaylandSource(display);
        source.attach(null);

        _watching = true;
        ensure_device();
    }

    private void handle_global(Wl.Registry reg, uint32 name, string iface, uint32 version) {
        if (iface == "ext_data_control_manager_v1") {
            manager = reg.bind<ExtDataControlManagerV1>(
                name, ref ExtDataControlManagerV1.iface, uint.min(version, 1));
        } else if (iface == "wl_seat" && seat == null) {
            seat = reg.bind<Wl.Seat>(name, ref wl_seat_interface, uint.min(version, 2));
        }
    }

    private void handle_global_remove(Wl.Registry reg, uint32 name) { }

    private void ensure_device() {
        if (manager == null || seat == null || device != null) {
            return;
        }
        device = manager.get_data_device(seat);
        device.add_listener(device_listener, this);
        if (display != null) {
            display.flush();
        }
    }

    private void handle_data_offer(ExtDataControlDeviceV1 dev, ExtDataControlOfferV1 offer) {
        clear_pending();
        pending = new OfferData(offer);
    }

    private void handle_selection(ExtDataControlDeviceV1 dev, ExtDataControlOfferV1? offer) {
        if (offer != null && !ignore_next && pending != null) {
            store_offer(pending);
        }
        ignore_next = false;
        clear_pending();
    }

    private void clear_pending() {
        if (pending != null) {
            pending.cleanup();
            pending = null;
        }
    }

    private void handle_finished(ExtDataControlDeviceV1 dev) {
        device = null;
    }

    private void handle_primary_selection(ExtDataControlDeviceV1 dev, ExtDataControlOfferV1? offer) { }

    private void store_offer(OfferData od) {
        string? mime = pick_mime(od.mimes);
        if (mime == null) {
            return;
        }
        bool is_text = is_text_mime(mime);

        int[] fds = new int[2];
        if (Posix.pipe(fds) != 0) {
            return;
        }
        od.offer.receive(mime, fds[1]);
        Posix.close(fds[1]);
        display.flush();

        // Drain the pipe without blocking the UI: non-blocking fd, bounded by a
        // per-wait timeout and a total size cap so a stalled or flooding source
        // client can neither freeze the shell nor exhaust memory.
        int rfd = fds[0];
        Posix.fcntl(rfd, Posix.F_SETFL, Posix.O_NONBLOCK);

        var ba = new ByteArray();
        uint8[] buf = new uint8[4096];
        bool ok = true;
        while (true) {
            Posix.pollfd[] pfds = new Posix.pollfd[1];
            pfds[0].fd = rfd;
            pfds[0].events = (int16) Posix.POLLIN;
            int pr = Posix.poll(pfds, READ_TIMEOUT_MS);
            if (pr <= 0) {
                ok = false; // timeout or poll error
                break;
            }
            ssize_t n = Posix.read(rfd, buf, buf.length);
            if (n < 0) {
                if (Posix.errno == Posix.EAGAIN) {
                    continue;
                }
                ok = false;
                break;
            }
            if (n == 0) {
                break; // EOF
            }
            ba.append(buf[0 : (int) n]);
            if (ba.len > MAX_PAYLOAD) {
                ok = false; // oversized payload, drop it
                break;
            }
        }
        Posix.close(rfd);

        if (!ok || ba.len == 0) {
            return;
        }
        Bytes data = new Bytes(ba.data);
        int64 ts = new DateTime.now_local().to_unix();
        add_entry(new ClipboardEntry(mime, data, is_text, make_preview(mime, data, is_text), ts));
    }

    private void add_entry(ClipboardEntry entry) {
        // Skip if identical to the most-recent entry.
        if (history.get_n_items() > 0) {
            var top = (ClipboardEntry) history.get_item(0);
            if (top.mime == entry.mime && top.data.compare(entry.data) == 0) {
                return;
            }
        }
        // Drop any earlier duplicate so re-copying an old entry bumps it to top.
        for (uint i = 1; i < history.get_n_items(); i++) {
            var e = (ClipboardEntry) history.get_item(i);
            if (e.mime == entry.mime && e.data.compare(entry.data) == 0) {
                history.remove(i);
                break;
            }
        }
        history.insert(0, entry);
        trim_history();
        save_history();
    }

    private void trim_history() {
        while (history.get_n_items() > _max_entries) {
            history.remove(history.get_n_items() - 1);
        }
    }

    /** Re-publish a stored entry as the current selection. */
    public void copy(ClipboardEntry entry) {
        if (manager == null || device == null) {
            return;
        }
        var src = manager.create_data_source();
        var holder = new SourceData(this, (owned) src, entry);
        active_sources.add(holder);

        if (entry.is_text) {
            foreach (string m in TEXT_MIMES) {
                holder.source.offer(m);
            }
        } else {
            holder.source.offer(entry.mime);
        }

        ignore_next = true;
        device.set_selection(holder.source);
        display.flush();

        add_entry(entry); // bump to top
    }

    private void drop_source(SourceData holder) {
        for (uint i = 0; i < active_sources.length; i++) {
            if (active_sources[i] == holder) {
                active_sources.remove_index(i);
                return;
            }
        }
    }

    private static string? pick_mime(GenericArray<string> mimes) {
        foreach (string want in TEXT_MIMES) {
            for (uint i = 0; i < mimes.length; i++) {
                if (mimes[i] == want) {
                    return want;
                }
            }
        }
        foreach (string want in IMAGE_MIMES) {
            for (uint i = 0; i < mimes.length; i++) {
                if (mimes[i] == want) {
                    return want;
                }
            }
        }
        return null;
    }

    private static bool is_text_mime(string mime) {
        if (mime.has_prefix("text/")) {
            return true;
        }
        foreach (string t in TEXT_MIMES) {
            if (mime == t) {
                return true;
            }
        }
        return false;
    }

    private static string make_preview(string mime, Bytes data, bool is_text) {
        if (is_text) {
            // Clipboard bytes are not NUL-terminated: bound the conversion by length.
            unowned uint8[] raw = data.get_data();
            var sb = new StringBuilder();
            sb.append_len((string) raw, raw.length);
            var s = sb.str.strip();
            if (s.char_count() > 80) {
                s = s.substring(0, s.index_of_nth_char(80)) + "…";
            }
            return s.replace("\n", " ");
        }
        return "%s (%s KB)".printf(mime, (data.length / 1024).to_string());
    }

    // ---- persistence: a single JSON file of base64-encoded blobs ----

    private string history_path() {
        return Path.build_filename(
            Environment.get_user_data_dir(), "morghulis", "clipboard", "history.json");
    }

    private void save_history() {
        if (!_persist) {
            return;
        }
        var builder = new Json.Builder();
        builder.begin_array();
        for (uint i = 0; i < history.get_n_items(); i++) {
            var e = (ClipboardEntry) history.get_item(i);
            builder.begin_object();
            builder.set_member_name("mime"); builder.add_string_value(e.mime);
            builder.set_member_name("is_text"); builder.add_boolean_value(e.is_text);
            builder.set_member_name("preview"); builder.add_string_value(e.preview);
            builder.set_member_name("ts"); builder.add_int_value(e.timestamp);
            builder.set_member_name("data");
            builder.add_string_value(Base64.encode(e.data.get_data()));
            builder.end_object();
        }
        builder.end_array();

        var gen = new Json.Generator();
        gen.set_root(builder.get_root());
        try {
            var path = history_path();
            var dir = File.new_for_path(path).get_parent();
            if (dir != null && !dir.query_exists()) {
                dir.make_directory_with_parents();
                FileUtils.chmod(dir.get_path(), 0700);
            }
            gen.to_file(path);
            // History can hold secrets (passwords, tokens) — keep it owner-only.
            FileUtils.chmod(path, 0600);
        } catch (Error e) {
            warning("clipboard: failed to save history: %s", e.message);
        }
    }

    private void load_history() {
        var path = history_path();
        if (!FileUtils.test(path, FileTest.EXISTS)) {
            return;
        }
        try {
            var parser = new Json.Parser();
            parser.load_from_file(path);
            var arr = parser.get_root().get_array();
            arr.foreach_element((a, i, node) => {
                var obj = node.get_object();
                uint8[] data = Base64.decode(obj.get_string_member("data"));
                int64 ts = obj.has_member("ts") ? obj.get_int_member("ts") : 0;
                history.append(new ClipboardEntry(
                    obj.get_string_member("mime"),
                    new Bytes.take((owned) data),
                    obj.get_boolean_member("is_text"),
                    obj.get_string_member("preview"),
                    ts));
            });
        } catch (Error e) {
            warning("clipboard: failed to load history: %s", e.message);
        }
    }

    private class OfferData : Object {
        // The offer proxy is owned by the client until destroy(); libwayland
        // never frees it for us, so hold it unowned and destroy it in cleanup().
        public unowned ExtDataControlOfferV1 offer;
        public GenericArray<string> mimes = new GenericArray<string>();

        private const ExtDataControlOfferV1Listener offer_listener = {
            handle_offer
        };

        public OfferData(ExtDataControlOfferV1 offer) {
            this.offer = offer;
            this.offer.add_listener(offer_listener, this);
        }

        public void cleanup() {
            offer.destroy();
        }

        private void handle_offer(ExtDataControlOfferV1 o, string mime) {
            mimes.add(mime);
        }
    }

    private class SourceData : Object {
        public unowned Clipboard clipboard;
        public ExtDataControlSourceV1 source;
        public ClipboardEntry entry;

        private const ExtDataControlSourceV1Listener source_listener = {
            handle_send,
            handle_cancelled
        };

        public SourceData(Clipboard clipboard, owned ExtDataControlSourceV1 source, ClipboardEntry entry) {
            this.clipboard = clipboard;
            this.source = (owned) source;
            this.entry = entry;
            this.source.add_listener(source_listener, this);
        }

        private void handle_send(ExtDataControlSourceV1 s, string mime, int32 fd) {
            unowned uint8[] d = entry.data.get_data();
            Posix.write(fd, (void*) d, d.length);
            Posix.close(fd);
        }

        private void handle_cancelled(ExtDataControlSourceV1 s) {
            clipboard.drop_source(this);
        }
    }
}
