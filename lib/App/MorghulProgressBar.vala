public class MorghulProgressBar : Gtk.Widget {
    private Gtk.ProgressBar _progress_bar;
    private Adw.TimedAnimation? _animation = null;
    private double _current_fraction = 0.0;

    public bool animate { get; set; default = true; }
    public uint animation_duration { get; set; default = 200; }
    public Adw.Easing easing { get; set; default = Adw.Easing.LINEAR; }

    public double fraction {
        get {
            return _current_fraction;
        }
        set {
            if (animate) {
                animate_to(value);
            } else {
                _current_fraction = value;
                _progress_bar.fraction = value;
            }
        }
    }

    construct {
        _progress_bar = new Gtk.ProgressBar();
        _progress_bar.set_parent(this);

        this.layout_manager = new Gtk.BinLayout();
    }

    ~MorghulProgressBar() {
        if (_animation != null) {
            _animation.skip();
        }
        _progress_bar.unparent();
    }

    private void animate_to(double target_fraction) {
        if (!animate) {
            _current_fraction = target_fraction;
            _progress_bar.fraction = target_fraction;
            return;
        }

        if (_animation != null) {
            _animation.skip();
        }

        var target = new Adw.CallbackAnimationTarget((value) => {
            _current_fraction = value;
            _progress_bar.fraction = value;
        });

        _animation = new Adw.TimedAnimation(
            this,
            _current_fraction,
            target_fraction,
            animation_duration,
            target) {
            easing = this.easing
        };

        _animation.play();
    }

    public void set_fraction_animated(double target_fraction) {
        animate_to(target_fraction);
    }

    public void set_fraction_immediate(double target_fraction) {
        if (_animation != null) {
            _animation.skip();
        }
        _current_fraction = target_fraction;
        _progress_bar.fraction = target_fraction;
    }

    public void set_text(string? text) {
        _progress_bar.text = text;
        _progress_bar.show_text = text != null;
    }

    public void set_show_text(bool show) {
        _progress_bar.show_text = show;
    }

    public void set_inverted(bool inverted) {
        _progress_bar.inverted = inverted;
    }

    public new void add_css_class(string css_class) {
        _progress_bar.add_css_class(css_class);
    }

    public new void remove_css_class(string css_class) {
        _progress_bar.remove_css_class(css_class);
    }
}
