// Drives a dedicated Wl.Display connection from the GLib main loop:
// flush outgoing requests in prepare(), dispatch incoming events on IN.
// Shared by the Wayland-protocol backends (gamma, clipboard).
internal class WaylandSource : GLib.Source {
    internal unowned Wl.Display display;
    internal void* tag;
    internal int err;

    public WaylandSource(Wl.Display display) {
        base();
        this.display = display;
        this.tag = this.add_unix_fd(
            display.get_fd(),
            IOCondition.IN | IOCondition.ERR | IOCondition.HUP);
    }

    public override bool prepare(out int timeout) {
        // EAGAIN just means the send buffer is momentarily full; not fatal.
        if (display.flush() < 0 && Posix.errno != Posix.EAGAIN) {
            err = Posix.errno;
        }
        timeout = -1;
        return false;
    }

    public override bool check() {
        return query_unix_fd(tag) > 0;
    }

    public override bool dispatch(SourceFunc? callback) {
        IOCondition revents = query_unix_fd(tag);
        if (err > 0 || (revents & (IOCondition.ERR | IOCondition.HUP)) != 0) {
            return GLib.Source.REMOVE;
        }
        if ((revents & IOCondition.IN) != 0 && display.dispatch() < 0) {
            return GLib.Source.REMOVE;
        }
        return GLib.Source.CONTINUE;
    }
}
