public class ScrollableIndicatorMenu : Gtk.Widget, Gtk.Buildable {
    private uint _scroll_indicator_timeout_id = 0;
    private Gtk.Adjustment _vadj;
    private Gtk.Widget? _child;
    private Gtk.Overlay _overlay;
    private Gtk.ScrolledWindow _scrolled_window;
    private Gtk.Revealer _go_down_revealer;

    public Gtk.Widget? child {
        get { return _child; }
        set {
            if (_child == value) {
                return;
            }

            _child = value;

            if (_child != null) {
                _scrolled_window.child = _child;
            }
        }
    }

    public int max_content_height {
        get { return _scrolled_window.max_content_height; }
        set {
            if (value != _scrolled_window.max_content_height) {
                _scrolled_window.max_content_height = value;
            }
        }
    }

    public void add_child(Gtk.Builder builder, Object child, string? type) {
        if (type == null && child is Gtk.Widget) {
            this.child = (Gtk.Widget)child;
        }
    }

    construct {
        layout_manager = new Gtk.BinLayout();

        _overlay = new Gtk.Overlay() {
            css_classes = new string[] { "background" }
        };
        _overlay.set_parent(this);

        setup_ui();
        setup_scroll_indicator();
    }

    ~ScrollableIndicatorMenu() {
        if (_overlay != null) {
            _overlay.unparent();
        }
    }

    private void setup_ui() {
        _scrolled_window = new Gtk.ScrolledWindow() {
            propagate_natural_height = true,
            overflow = Gtk.Overflow.HIDDEN,
            vexpand = true,
            css_classes = new string[] { "rounded" }
        };

        var indicator_image = new Gtk.Image() {
            icon_name = "go-down-symbolic",
            pixel_size = 32,
            margin_bottom = 10
        };

        _go_down_revealer = new Gtk.Revealer() {
            transition_duration = 200,
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            reveal_child = true,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            css_classes = new string[] { "float-y" },
            child = indicator_image
        };

        _overlay.set_child(_scrolled_window);
        _overlay.add_overlay(_go_down_revealer);
    }

    private void setup_scroll_indicator() {
        _vadj = _scrolled_window.vadjustment;

        _vadj.notify["upper"].connect(debounce_scroll_indicator);
        _vadj.notify["page-size"].connect(debounce_scroll_indicator);
        _vadj.notify["value"].connect(debounce_scroll_indicator);
    }

    private void debounce_scroll_indicator() {
        if (_scroll_indicator_timeout_id > 0) {
            Source.remove(_scroll_indicator_timeout_id);
        }

        _scroll_indicator_timeout_id = Timeout.add(0x64, () => {
            update_scroll_indicator();
            _scroll_indicator_timeout_id = 0;
            return Source.REMOVE;
        });
    }

    private void update_scroll_indicator() {
        bool is_scrollable = _vadj.upper > _vadj.page_size;
        bool not_at_bottom = (_vadj.value + _vadj.page_size) < _vadj.upper - 1;

        _go_down_revealer.reveal_child = is_scrollable && not_at_bottom;
    }

    public void refresh_scroll_indicator() {
        debounce_scroll_indicator();
    }

    public Gtk.ScrolledWindow get_scrolled_window() {
        return _scrolled_window;
    }
}
