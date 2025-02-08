public class CircularProgressSnapshot : Gtk.Widget {
	// This is deprecated, so needs to be changed, but for now, works for testing.
	private Gtk.StyleContext _context;

	private int _line_width;
	private double _percentage;
	private string _center_fill_color;
	private string _radius_fill_color;
	private string _progress_fill_color;
	private Gtk.Widget _child;

	[Description(nick = "Center Fill", blurb = "Center Fill toggle")]
	public bool center_filled { set; get; default = false; }

	[Description(nick = "Radius Fill", blurb = "Radius Fill toggle")]
	public bool radius_filled { set; get; default = false; }

	[Description(nick = "Line Cap", blurb = "Line Cap for stroke as in Cairo.LineCap")]
	public Cairo.LineCap line_cap { set; get; default = Cairo.LineCap.BUTT; }

	[Description(nick = "Inside circle fill color", blurb = "Center pad fill color (Check Gdk.RGBA parse method)")]
	public string center_fill_color {
		get {
			return _center_fill_color;
		}
		set {
			var color = Gdk.RGBA();
			if (color.parse(value)) {
				_center_fill_color = value;
			}
		}
	}

	[Description(nick = "Circular radius fill color", blurb = "The circular pad fill color (Check GdkRGBA parse method)")]
	public string radius_fill_color {
		get {
			return _radius_fill_color;
		}
		set {
			var color = Gdk.RGBA();
			if (color.parse(value)) {
				_radius_fill_color = value;
			}
		}
	}

	[Description(nick = "Progress fill color", blurb = "Progress line color (Check GdkRGBA parse method)")]
	public string progress_fill_color {
		get {
			return _progress_fill_color;
		}
		set {
			var color = Gdk.RGBA();
			if (color.parse(value)) {
				_progress_fill_color = value;
			}
		}
	}

	[Description(nick = "Circle width", blurb = "The circle radius line width")]
	public int line_width {
		get { return _line_width; }
		set {
			if (value < 0) {
				_line_width = 0;
			} else {
				_line_width = value;
			}
			queue_draw();
		}
	}

	[Description(nick = "Percentage/Value", blurb = "The percentage value [0.0 ... 1.0]")]
	public double percentage {
		get {
			return _percentage;
		}
		set {
			if (value > 1.0) {
				_percentage = 1.0;
			} else if (value < 0.0) {
				_percentage = 0.0;
			} else {
				_percentage = value;
			}
		}
	}

	[Description(nick = "Child Widget", blurb = "The child widget contained within the circular progress")]
	public Gtk.Widget? child {
		get { return _child; }
		set {
			if (_child != null) {
				_child.unparent();
			}
			_child = value;
			if (_child != null) {
				_child.set_parent(this);
			}
		}
	}

	construct {
		_context = get_style_context();
		_line_width = 1;
		_percentage = 0;
		_center_fill_color = "#adadad";
		_radius_fill_color = "#d3d3d3";
		_progress_fill_color = "#4a90d9";
		set_layout_manager(new Gtk.BinLayout());
	}

	public CircularProgressSnapshot() {
		Object(
			css_name: "circular-progress"
		);
		notify.connect(() => {
			queue_draw();
		});
	}

	protected override void dispose() {
		if (_child != null) {
			_child.unparent();
			_child = null;
		}
		base.dispose();
	}

	private void draw_progress_arc(
		Gtk.Snapshot snapshot,
		float center_x,
		float center_y,
		float delta,
		float actual_line_width
	) {
		if (percentage <= 0) {
			return;
		}

		var color = Gdk.RGBA();
		_context.lookup_color("accent_color", out color);

		var start_angle = 1.5f * Math.PI;
		var end_angle = start_angle + (percentage * 2 * Math.PI);

		var start_x = center_x + (float)(delta * Math.cos(start_angle));
		var start_y = center_y + (float)(delta * Math.sin(start_angle));
		var end_x = center_x + (float)(delta * Math.cos(end_angle));
		var end_y = center_y + (float)(delta * Math.sin(end_angle));

		var path_builder = new Gsk.PathBuilder();
		path_builder.move_to(start_x, start_y);
		path_builder.svg_arc_to(
			delta, delta, 0.0f,
			percentage > 0.5, true,
			end_x, end_y
		);

		var stroke = new Gsk.Stroke(actual_line_width);
		snapshot.append_stroke(path_builder.to_path(), stroke, color);
	}

	private void draw_center_fill(
		Gtk.Snapshot snapshot,
		float center_x,
		float center_y,
		float delta
	) {
		if (!center_filled) {
			return;
		}

		var color = Gdk.RGBA();
		_context.lookup_color("light_3", out color);

		var bounds = Graphene.Rect().init(
			center_x - delta,
			center_y - delta,
			delta * 2,
			delta * 2
		);

		snapshot.append_color(color, bounds);
	}

	private void draw_radius_fill(
		Gtk.Snapshot snapshot,
		float center_x,
		float center_y,
		float delta,
		float radius,
		float actual_line_width
	) {
		if (!radius_filled) {
			return;
		}

		var color = Gdk.RGBA();
		_context.lookup_color("accent_fg_color", out color);

		var rect = Gsk.RoundedRect() {
			bounds = Graphene.Rect().init(
				center_x - delta,
				center_y - delta,
				delta * 2,
				delta * 2
			)
		};

		var graphene_size = Graphene.Size().init(radius, radius);
		for (int i = 0; i < 4; i++) {
			rect.corner[i] = graphene_size;
		}

		snapshot.append_border(
			rect,
			{ actual_line_width, actual_line_width, actual_line_width, actual_line_width },
			{ color, color, color, color }
		);
	}

	public override void snapshot(Gtk.Snapshot snapshot) {
		var width = get_width();
		var height = get_height();

		var center_x = width / 2.0f;
		var center_y = height / 2.0f;
		var radius = float.min(width / 2.0f, height / 2.0f) - 1;

		var actual_line_width = (float)line_width;
		if (actual_line_width > radius) {
			actual_line_width = radius;
		}

		var delta = radius - (actual_line_width / 2.0f);

		draw_progress_arc(snapshot, center_x, center_y, delta, actual_line_width);
		draw_center_fill(snapshot, center_x, center_y, delta);
		draw_radius_fill(snapshot, center_x, center_y, delta, radius, actual_line_width);

		if (_child != null) {
			_child.snapshot(snapshot);
		}
	}

	public override void measure(Gtk.Orientation orientation,
								 int for_size,
								 out int minimum,
								 out int natural,
								 out int minimum_baseline,
								 out int natural_baseline) {
		minimum = 24;
		natural = minimum;

		// Get child measurements if it exists
		if (_child != null) {
			int child_min, child_nat, child_min_baseline, child_nat_baseline;
			_child.measure(orientation, for_size,
						   out child_min, out child_nat,
						   out child_min_baseline, out child_nat_baseline);

			// Use the larger of our minimum size and child's size
			minimum = int.max(minimum, child_min);
			natural = int.max(natural, child_nat);
		}

		minimum_baseline = -1;
		natural_baseline = -1;
	}
}
