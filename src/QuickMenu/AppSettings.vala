[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QuickMenu/AppSettings.ui")]
public class AppSettings : Gtk.Box {
    private GLib.Settings _gsettings;
    private bool _gtk_theme;
    private uint _navbar_anchor;
    private uint _notifications_default_timeout;
    private uint _osd_timeout;
    private uint _math_history_max_days;

    public bool gtk_theme {
        get { return _gtk_theme; }
        set {
            _gtk_theme = value;
            _gsettings.set_boolean("gtk-theme", _gtk_theme);
        }
    }
    public uint navbar_anchor {
        get { return _navbar_anchor; }
        set {
            _navbar_anchor = value;
            _gsettings.set_string("navbar-anchor", value == 0 ? "bottom": "top");
        }
    }
    public uint notifications_default_timeout {
        get { return _notifications_default_timeout; }
        set {
            _notifications_default_timeout = value;
            _gsettings.set_uint("notifications-default-timeout", _notifications_default_timeout);
        }
    }
    public uint osd_timeout {
        get { return _osd_timeout; }
        set {
            _osd_timeout = value;
            _gsettings.set_uint("osd-timeout", _osd_timeout);
        }
    }

    public uint math_history_max_days {
        get { return _math_history_max_days; }
        set {
            _math_history_max_days = value;
            _gsettings.set_uint("math-history-max-days", _math_history_max_days);
        }
    }

    construct {
        _gsettings = Morghulis.gsettings;
        reload_gsettings();
    }

    [GtkCallback]
    public void reload_gsettings() {
        gtk_theme = _gsettings.get_boolean("gtk-theme");
        navbar_anchor = _gsettings.get_string("navbar-anchor") == "bottom" ? 0 : 1;
        notifications_default_timeout = _gsettings.get_uint("notifications-default-timeout");
        osd_timeout = _gsettings.get_uint("osd-timeout");
        math_history_max_days = _gsettings.get_uint("math-history-max-days");
    }
}
