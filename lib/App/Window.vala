// Taken from https://github.com/Aylur/astal/blob/main/lib/astal/gtk4/src/widget/window.vala
using GtkLayerShell;

[Flags]
public enum WindowAnchor {
    NONE,
    TOP,
    RIGHT,
    LEFT,
    BOTTOM,
}

public enum Exclusivity {
    NORMAL,
    EXCLUSIVE,
    IGNORE,
}

public enum Layer {
    BACKGROUND = 0,
    BOTTOM = 1,
    TOP = 2,
    OVERLAY = 3,
}

public enum Keymode {
    NONE = 0,
    EXCLUSIVE = 1,
    ON_DEMAND = 2,
}

public class MorghulWindow : Adw.Window {
    private bool _is_not_hyprland;
    private Adw.TimedAnimation? _animation = null;
    private Adw.CallbackAnimationTarget? _animation_target = null;
    private Adw.Easing _easing = Adw.Easing.EASE_IN_OUT_CUBIC;

    public Gdk.Monitor get_current_monitor() {
        return Gdk.Display.get_default().get_monitor_at_surface(base.get_surface());
    }

    private bool check(string action) {
        if (!is_supported()) {
            critical(@"can not $action on window: layer shell not supported");
            return true;
        }
        if (!is_layer_window(this)) {
            init_for_window(this);
        }
        return false;
    }

    public new bool visible {
        get { return base.get_visible(); }
        set {
            if (_is_not_hyprland) {
                animate_to(value);
            } else {
                base.visible = value;
            }
        }
    }

    private void animate_to(bool to_visible) {
        if (_animation != null) {
            _animation.skip();
        }
        if (to_visible) {
            _animation = new Adw.TimedAnimation(
                this,
                0, // Start value
                1, // End value
                200,
                _animation_target) {
                easing = this._easing
            };
            base.visible = true;
            _animation.play();
        } else {
            _animation = new Adw.TimedAnimation(
                this,
                1, // Start value
                0, // End value
                200,
                _animation_target) {
                easing = this._easing
            };
            _animation.done.connect(() => {
                base.visible = false;
                _animation = null;
            });
            _animation.play();
        }
    }

    construct {
        // Best boolean of all times
        _is_not_hyprland = !Morghulis.is_hyprland;
        // I don't know rick, is this safe? I'm scared
        if (_is_not_hyprland) {
            opacity = 0;
            _animation_target = new Adw.CallbackAnimationTarget((value) => {
                this.opacity = value;
            });
        }

        height_request = 1;
        width_request = 1;

        check("initialize layer shell");
    }

    public string namespace {
        get { return get_namespace(this); }
        set {
            if (check("set namespace")) {
                return;
            }

            set_namespace(this, value);
        }
    }

    public WindowAnchor anchor {
        set {
            if (check("set anchor")) {
                return;
            }

            set_anchor(this, Edge.TOP, WindowAnchor.TOP in value);
            set_anchor(this, Edge.BOTTOM, WindowAnchor.BOTTOM in value);
            set_anchor(this, Edge.LEFT, WindowAnchor.LEFT in value);
            set_anchor(this, Edge.RIGHT, WindowAnchor.RIGHT in value);
        }
        get {
            var a = 0;
            if (get_anchor(this, Edge.TOP)) {
                a = a | WindowAnchor.TOP;
            }

            if (get_anchor(this, Edge.RIGHT)) {
                a = a | WindowAnchor.RIGHT;
            }

            if (get_anchor(this, Edge.LEFT)) {
                a = a | WindowAnchor.LEFT;
            }

            if (get_anchor(this, Edge.BOTTOM)) {
                a = a | WindowAnchor.BOTTOM;
            }

            if (a == 0) {
                return WindowAnchor.NONE;
            }

            return a;
        }
    }

    public Exclusivity exclusivity {
        set {
            if (check("set exclusivity")) {
                return;
            }

            switch (value) {
                case Exclusivity.NORMAL:
                    set_exclusive_zone(this, 0);
                break;

                case Exclusivity.EXCLUSIVE:
                    auto_exclusive_zone_enable(this);
                break;

                case Exclusivity.IGNORE:
                    set_exclusive_zone(this, -1);
                break;
            }
        }
        get {
            if (auto_exclusive_zone_is_enabled(this)) {
                return Exclusivity.EXCLUSIVE;
            }

            if (get_exclusive_zone(this) == -1) {
                return Exclusivity.IGNORE;
            }

            return Exclusivity.NORMAL;
        }
    }

    public Layer layer {
        get { return (Layer)get_layer(this); }
        set {
            if (check("set layer")) {
                return;
            }

            set_layer(this, (GtkLayerShell.Layer)value);
        }
    }

    public Keymode keymode {
        get { return (Keymode)get_keyboard_mode(this); }
        set {
            if (check("set keymode")) {
                return;
            }

            set_keyboard_mode(this, (GtkLayerShell.KeyboardMode)value);
        }
    }

    public Gdk.Monitor gdkmonitor {
        get { return get_monitor(this); }
        set {
            if (check("set gdkmonitor")) {
                return;
            }

            set_monitor(this, value);
        }
    }

    public new int margin_top {
        get { return GtkLayerShell.get_margin(this, Edge.TOP); }
        set {
            if (check("set margin_top")) {
                return;
            }

            GtkLayerShell.set_margin(this, Edge.TOP, value);
        }
    }

    public new int margin_bottom {
        get { return GtkLayerShell.get_margin(this, Edge.BOTTOM); }
        set {
            if (check("set margin_bottom")) {
                return;
            }

            GtkLayerShell.set_margin(this, Edge.BOTTOM, value);
        }
    }

    public new int margin_left {
        get { return GtkLayerShell.get_margin(this, Edge.LEFT); }
        set {
            if (check("set margin_left")) {
                return;
            }

            GtkLayerShell.set_margin(this, Edge.LEFT, value);
        }
    }

    public new int margin_right {
        get { return GtkLayerShell.get_margin(this, Edge.RIGHT); }
        set {
            if (check("set margin_right")) {
                return;
            }

            GtkLayerShell.set_margin(this, Edge.RIGHT, value);
        }
    }

    public new int margin {
        set {
            if (check("set margin")) {
                return;
            }

            margin_top = value;
            margin_right = value;
            margin_bottom = value;
            margin_left = value;
        }
    }

    public int monitor {
        set {
            if (check("set monitor")) {
                return;
            }

            if (value < 0) {
                set_monitor(this, (Gdk.Monitor)null);
            }

            var m = (Gdk.Monitor)Gdk.Display.get_default().get_monitors().get_item(value);
            set_monitor(this, m);
        }
        get {
            var m = get_monitor(this);
            var mons = Gdk.Display.get_default().get_monitors();
            for (var i = 0; i < mons.get_n_items(); ++i) {
                if (m == mons.get_item(i)) {
                    return i;
                }
            }

            return -1;
        }
    }

    ~MorghulWindow() {
        if (_animation != null) {
            _animation.skip();
        }
    }
}
