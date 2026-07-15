/**
 * A circular progress bar widget for GTK4.
 *
 * CircularProgressBar displays progress along a circular arc. Angles are given
 * in radians and measured **clockwise from the positive x-axis** (the 3 o'clock
 * position), matching the widget's screen coordinate system. The track spans
 * clockwise from [property@Astal.CircularProgressBar:start-at] to
 * [property@Astal.CircularProgressBar:end-at]; the filled portion is controlled
 * by [property@Astal.CircularProgressBar:percentage].
 */
internal class CircularProgressBar : Gtk.Widget, Gtk.Buildable {
    private Gizmo _progress_arc;
    private Gizmo _center_fill;
    private Gizmo _radius_fill;
    private Gtk.Widget _child;

    private int _line_width;
    private double _percentage;
    private double _start_at;
    private double _end_at;

    private double _target_percentage;
    private uint _tick_id = 0;
    private double _anim_from;
    private double _anim_to;
    private int64 _anim_start_us;

    /**
     * Whether the progress fills counter-clockwise from
     * [property@Astal.CircularProgressBar:end-at] back toward
     * [property@Astal.CircularProgressBar:start-at], instead of clockwise from
     * start toward end.
     *
     * The track endpoints are unaffected: only the origin and growth direction
     * of the filled portion change, matching the semantics of
     * [property@Gtk.Range:inverted].
     */
    public bool inverted { get; set; default = false; }

    /**
     * Whether the disc enclosed by the track is filled.
     */
    public bool center_filled { get; set; default = false; }

    /**
     * Whether the full track arc is drawn as a background behind the progress.
     */
    public bool radius_filled { get; set; default = false; }

    /**
     * The width of the track line in pixels.
     *
     * If the value is 0, the progress is drawn as a pie/segment instead of a stroke.
     * Negative values are clamped to 0.
     */
    public int line_width {
        get { return _line_width; }
        set {
            int v = value < 0 ? 0 : value;
            if (_line_width == v) {
                return;
            }
            _line_width = v;
        }
    }

    /**
     * The line cap style for the progress stroke.
     *
     * See [enum@Gsk.LineCap].
     */
    public Gsk.LineCap line_cap { get; set; default = Gsk.LineCap.BUTT; }

    /**
     * The fill rule for the center fill area.
     *
     * See [enum@Gsk.FillRule].
     */
    public Gsk.FillRule fill_rule { get; set; default = Gsk.FillRule.WINDING; }

    /**
     * The progress value between 0.0 and 1.0.
     *
     * Values outside [0.0, 1.0] are clamped. When
     * [property@Astal.CircularProgressBar:animate] is true and the widget is
     * mapped, changes are tweened using [property@Astal.CircularProgressBar:bezier]
     * over [property@Astal.CircularProgressBar:transition-duration] milliseconds.
     */
    public double percentage {
        get { return _target_percentage; }
        set {
            double v = value.clamp(0.0, 1.0);
            if (_target_percentage == v) {
                return;
            }
            _target_percentage = v;

            if (animate && get_mapped()) {
                start_percentage_animation();
            } else {
                _percentage = v;
                queue_draw();
            }
        }
    }

    /**
     * The starting angle of the track, in radians, ranging from -2π to 2π,
     * measured clockwise from the positive x-axis (the 3 o'clock position).
     */
    public double start_at {
        get { return _start_at; }
        set {
            double v = value.clamp(-2 * Math.PI, 2 * Math.PI);
            if (_start_at == v) {
                return;
            }
            _start_at = v;
        }
    }

    /**
     * The ending angle of the track, in radians, ranging from -2π to 2π,
     * measured clockwise from the positive x-axis (the 3 o'clock position).
     *
     * The track is the clockwise arc from
     * [property@Astal.CircularProgressBar:start-at] to this angle.
     */
    public double end_at {
        get { return _end_at; }
        set {
            double v = value.clamp(-2 * Math.PI, 2 * Math.PI);
            if (_end_at == v) {
                return;
            }
            _end_at = v;
        }
    }

    /**
     * Whether [property@Astal.CircularProgressBar:percentage] changes are
     * animated via a frame-clock tick callback.
     */
    public bool animate { get; set; default = false; }

    /**
     * Duration of the [property@Astal.CircularProgressBar:percentage] transition,
     * in milliseconds.
     */
    public uint transition_duration { get; set; default = 400; }

    /**
     * Easing curve used when [property@Astal.CircularProgressBar:animate] is true.
     *
     * Assign a preset (e.g. [func@Astal.CubicBezier.ease_out]) or a custom
     * [class@Astal.CubicBezier]. Defaults to ease-out.
     */
    public CubicBezier bezier { get; set; }

    /**
     * The child widget contained within the circular progress.
     */
    public Gtk.Widget? child {
        get { return _child; }
        set {
            if (_child == value) {
                return;
            }

            if (_child != null) {
                _child.unparent();
            }

            _child = value;

            if (_child != null) {
                _child.set_parent(this);
            }
        }
    }

    /*
     * Implements Gtk.Buildable interface.
     */
    public void add_child(Gtk.Builder builder, GLib.Object child, string? type) {
        if (child is Gtk.Widget) {
            this.child = (Gtk.Widget) child;
        } else {
            base.add_child(builder, child, type);
        }
    }

    static construct {
        set_css_name("circularprogress");
    }

    construct {
        _start_at = 0.0;
        _end_at = 2 * Math.PI;
        _percentage = 0.0;
        _target_percentage = 0.0;
        bezier = CubicBezier.ease_out();

        _progress_arc = new Gizmo(
            "progress",
            calculate_measurement,
            null,
            progress_arc_snapshot,
            null, null, null
        );

        _center_fill = new Gizmo(
            "center",
            calculate_measurement,
            null,
            draw_center_fill,
            null, null, null
        );

        _radius_fill = new Gizmo(
            "radius",
            calculate_measurement,
            null,
            draw_radius_fill,
            null, null, null
        );

        _progress_arc.set_parent(this);
        _center_fill.set_parent(this);
        _radius_fill.set_parent(this);

        notify.connect(() => {
            queue_draw();
        });
    }

    public CircularProgressBar() {
        Object(name: "circularprogress");
    }

    protected override void dispose() {
        if (_tick_id != 0) {
            remove_tick_callback(_tick_id);
            _tick_id = 0;
        }
        if (_child != null) {
            _child.unparent();
            _child = null;
        }
        _progress_arc.unparent();
        _progress_arc = null;
        _center_fill.unparent();
        _center_fill = null;
        _radius_fill.unparent();
        _radius_fill = null;
        base.dispose();
    }

    private void start_percentage_animation() {
        if (_tick_id != 0) {
            remove_tick_callback(_tick_id);
            _tick_id = 0;
        }

        unowned var clock = get_frame_clock();
        if (clock == null) {
            _percentage = _target_percentage;
            queue_draw();
            return;
        }

        _anim_from = _percentage;
        _anim_to = _target_percentage;
        _anim_start_us = clock.get_frame_time();
        _tick_id = add_tick_callback(on_animation_tick);
    }

    private bool on_animation_tick(Gtk.Widget widget, Gdk.FrameClock clock) {
        double duration_us = (double) transition_duration * 1000.0;
        double t = duration_us <= 0.0
            ? 1.0
            : (double) (clock.get_frame_time() - _anim_start_us) / duration_us;

        if (t < 0.0) {
            t = 0.0;
        }
        if (t >= 1.0) {
            _percentage = _anim_to;
            _tick_id = 0;
            queue_draw();
            return GLib.Source.REMOVE;
        }

        double eased = (bezier ?? CubicBezier.linear()).solve(t);
        _percentage = _anim_from + (_anim_to - _anim_from) * eased;
        queue_draw();
        return GLib.Source.CONTINUE;
    }

    protected override void snapshot(Gtk.Snapshot snapshot) {
        // Draw back to front.
        if (center_filled) {
            _center_fill.snapshot(snapshot);
        }
        if (radius_filled) {
            _radius_fill.snapshot(snapshot);
        }
        _progress_arc.snapshot(snapshot);

        if (_child != null) {
            snapshot_child(_child, snapshot);
        }
    }

    protected override Gtk.SizeRequestMode get_request_mode() {
        return Gtk.SizeRequestMode.WIDTH_FOR_HEIGHT;
    }

    protected override void size_allocate(int width, int height, int baseline) {
        var radius = float.min(width / 2.0f, height / 2.0f) - 1;
        var half_line_width = (float) line_width / 2.0f;
        var delta = radius - half_line_width;

        if (delta < 0) {
            delta = 0;
        }

        if (_child != null) {
            var max_child_size = (int) (delta * Math.sqrt(2));

            var child_x = (width - max_child_size) / 2;
            var child_y = (height - max_child_size) / 2;

            var child_allocation = Gtk.Allocation() {
                x = child_x,
                y = child_y,
                width = max_child_size,
                height = max_child_size
            };

            _child.allocate_size(child_allocation, baseline);
        }
    }

    protected override void measure(Gtk.Orientation orientation,
                                    int for_size,
                                    out int minimum,
                                    out int natural,
                                    out int minimum_baseline,
                                    out int natural_baseline) {
        minimum = natural = 0;
        minimum_baseline = natural_baseline = -1;

        if (_child != null) {
            int child_minimum, child_natural;
            int child_minimum_baseline, child_natural_baseline;

            _child.measure(orientation, for_size,
                           out child_minimum, out child_natural,
                           out child_minimum_baseline, out child_natural_baseline);

            var padding = (int) (_line_width * 4);
            minimum = child_minimum + padding;
            natural = child_natural + padding;
        } else {
            minimum = natural = 40;
        }
    }

    private void calculate_measurement(Gtk.Orientation orientation,
                                       int for_size,
                                       out int minimum,
                                       out int natural,
                                       out int minimum_baseline,
                                       out int natural_baseline) {
        minimum = natural = get_width();
        minimum_baseline = natural_baseline = -1;
    }

    // Geometry helpers. Angles are clockwise-positive in the widget's y-down
    // coordinate system, so a point at angle θ is (cx + r·cosθ, cy + r·sinθ)
    // and increasing θ rotates clockwise on screen.

    private inline float arc_x(double angle, float cx, float delta) {
        return cx + (float) (delta * Math.cos(angle));
    }

    private inline float arc_y(double angle, float cy, float delta) {
        return cy + (float) (delta * Math.sin(angle));
    }

    // Clockwise angular extent of the track, in [0, 2π].
    private double track_sweep() {
        double sweep = _end_at - _start_at;
        while (sweep < 0) {
            sweep += 2 * Math.PI;
        }
        if (sweep > 2 * Math.PI) {
            sweep = 2 * Math.PI;
        }
        return sweep;
    }

    // Build a clockwise arc path from a0 to a1 (a1 >= a0). When `as_pie`, the arc
    // is closed through the center. When `full`, a complete circle is emitted.
    private Gsk.Path build_arc_path(double a0, double a1,
                                    float cx, float cy, float delta,
                                    bool as_pie, bool full) {
        var pb = new Gsk.PathBuilder();

        if (full) {
            pb.add_circle(Graphene.Point().init(cx, cy), delta);
            return pb.to_path();
        }

        bool large_arc = (a1 - a0) > Math.PI;

        if (as_pie) {
            pb.move_to(cx, cy);
            pb.line_to(arc_x(a0, cx, delta), arc_y(a0, cy, delta));
            pb.svg_arc_to(delta, delta, 0.0f, large_arc, true,
                          arc_x(a1, cx, delta), arc_y(a1, cy, delta));
            pb.line_to(cx, cy);
            pb.close();
        } else {
            pb.move_to(arc_x(a0, cx, delta), arc_y(a0, cy, delta));
            pb.svg_arc_to(delta, delta, 0.0f, large_arc, true,
                          arc_x(a1, cx, delta), arc_y(a1, cy, delta));
        }

        return pb.to_path();
    }

    private void progress_arc_snapshot(Gtk.Snapshot snapshot) {
        if (_percentage <= 0) {
            return;
        }

        int width = get_width();
        int height = get_height();
        float radius = float.min(width / 2.0f, height / 2.0f) - 1;
        float half_line_width = (float) line_width / 2.0f;
        float delta = radius - half_line_width;
        float center_x = width / 2.0f;
        float center_y = height / 2.0f;

        if (delta < 0) {
            delta = 0;
        }

        float actual_line_width = (float) line_width;
        if (actual_line_width > radius * 2) {
            actual_line_width = radius * 2;
        }

        double sweep = track_sweep();
        if (sweep <= 0) {
            return;
        }

        double fill = _percentage * sweep;

        // Fixed track endpoints; `inverted` only flips the fill origin/direction.
        double a0, a1;
        if (inverted) {
            a0 = _end_at - fill;
            a1 = _end_at;
        } else {
            a0 = _start_at;
            a1 = _start_at + fill;
        }

        bool as_pie = actual_line_width <= 0;
        bool full = fill >= 2 * Math.PI - 1e-9;
        var color = _progress_arc.get_color();
        var path = build_arc_path(a0, a1, center_x, center_y, delta, as_pie, full);

        if (as_pie) {
            snapshot.append_fill(path, Gsk.FillRule.EVEN_ODD, color);
        } else {
            var stroke = new Gsk.Stroke(actual_line_width);
            stroke.set_line_cap(line_cap);
            snapshot.append_stroke(path, stroke, color);
        }
    }

    private void draw_center_fill(Gtk.Snapshot snapshot) {
        if (!center_filled) {
            return;
        }

        var width = get_width();
        var height = get_height();
        var radius = float.min(width / 2.0f, height / 2.0f) - 1;
        var half_line_width = (float) line_width / 2.0f;
        var delta = radius - half_line_width;

        if (delta < 0) {
            delta = 0;
        }

        var color = _center_fill.get_color();
        var path_builder = new Gsk.PathBuilder();
        path_builder.add_circle(
            Graphene.Point().init(width / 2.0f, height / 2.0f),
            delta
        );

        snapshot.append_fill(path_builder.to_path(), fill_rule, color);
    }

    private void draw_radius_fill(Gtk.Snapshot snapshot) {
        if (!radius_filled) {
            return;
        }

        int width = get_width();
        int height = get_height();
        float radius = float.min(width / 2.0f, height / 2.0f) - 1;
        float half_line_width = (float) line_width / 2.0f;
        float delta = radius - half_line_width;
        float center_x = width / 2.0f;
        float center_y = height / 2.0f;

        if (delta < 0) {
            delta = 0;
        }

        double sweep = track_sweep();
        if (sweep <= 0) {
            return;
        }

        // The track background spans the whole arc from start to end.
        double a0 = _start_at;
        double a1 = _start_at + sweep;
        bool full = sweep >= 2 * Math.PI - 1e-9;
        bool as_pie = _line_width <= 0;
        var color = _radius_fill.get_color();
        var path = build_arc_path(a0, a1, center_x, center_y, delta, as_pie, full);

        if (as_pie) {
            snapshot.append_fill(path, Gsk.FillRule.EVEN_ODD, color);
        } else {
            var stroke = new Gsk.Stroke(_line_width);
            stroke.set_line_cap(line_cap);
            snapshot.append_stroke(path, stroke, color);
        }
    }
}
