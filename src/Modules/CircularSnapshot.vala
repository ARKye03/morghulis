public class CircularProgressSnapshot : Gtk.Widget {
	private int _line_width;
	private int _font_size;
	private string _icon_name;
	private double _percentage;
	private string _center_fill_color;
	private string _radius_fill_color;
	private string _progress_fill_color;

	[Description(nick = "Center Fill", blurb = "Center Fill toggle")]
	public bool center_filled { set; get; default = false; }

	[Description(nick = "Radius Fill", blurb = "Radius Fill toggle")]
	public bool radius_filled { set; get; default = false; }

	[Description(nick = "Font", blurb = "Font description without size, just the font name")]
	public string font { set; get; default = "FreeSerifBold"; }

	[Description(nick = "Line Cap", blurb = "Line Cap for stroke as in Cairo.LineCap")]
	public Cairo.LineCap line_cap { set; get; default = Cairo.LineCap.BUTT; }

	[Description(nick = "Font Size", blurb = "Size of the percentage text")]
	public int font_size {
		get { return _font_size; }
		set {
			if (value < 1) {
				_font_size = 1;
			} else {
				_font_size = value;
			}
			queue_draw();
		}
	}

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

	[Description(nick = "Icon Name", blurb = "System icon name to display instead of percentage")]
	public string? icon_name {
		get { return _icon_name; }
		set {
			_icon_name = value;
			queue_draw();
		}
	}

	construct {
		_line_width = 1;
		_percentage = 0;
		_center_fill_color = "#adadad";
		_radius_fill_color = "#d3d3d3";
		_progress_fill_color = "#4a90d9";
		_font_size = 24;
		_icon_name = null;
	}

	public CircularProgressSnapshot() {
		notify.connect(() => {
			queue_draw();
		});
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

		// Center fill
		if (center_filled) {
			var color = Gdk.RGBA();
			color.parse(center_fill_color);

			var bounds = Graphene.Rect().init(
				center_x - delta,
				center_y - delta,
				delta * 2,
				delta * 2
			);

			snapshot.append_color(color, bounds);
		}

		// Radius fill (circle outline)
		if (radius_filled) {
			var color = Gdk.RGBA();
			color.parse(radius_fill_color);

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

		// Progress arc
		if (percentage > 0) {
			var color = Gdk.RGBA();
			color.parse(progress_fill_color);

			var start_angle = 1.5f * Math.PI;
			var end_angle = start_angle + (percentage * 2 * Math.PI);

			// Calculate end point on circle
			var end_x = center_x + (float)(delta * Math.cos(end_angle));
			var end_y = center_y + (float)(delta * Math.sin(end_angle));

			var path = new Gsk.PathBuilder();
			path.move_to(center_x, center_y);
			path.svg_arc_to(
				delta,
				delta,
				0.0f,
				false,
				true,
				end_x,
				end_y
			);
			path.close();

			var stroke = new Gsk.Stroke(actual_line_width);
			snapshot.append_stroke(path.to_path(), stroke, color);
		}

		// Text or Icon
		if (icon_name != null) {
			var icon_size = (int)float.min(width, height) / 2;
			var icon_theme = Gtk.IconTheme.get_for_display(get_display());
			var paintable = icon_theme.lookup_icon(
				icon_name, null, icon_size,
				get_scale_factor(), Gtk.TextDirection.NONE, 0
			);

			if (paintable != null) {
				paintable.snapshot(snapshot, icon_size, icon_size);
			}
		} else {
			var color = get_style_context().get_color();
			var layout = create_pango_layout("%d".printf((int)(percentage * 100)));
			var font_desc = Pango.FontDescription.from_string(@"$font $font_size");
			layout.set_font_description(font_desc);

			int text_width, text_height;
			layout.get_size(out text_width, out text_height);

			var text_x = center_x - (text_width / Pango.SCALE / 2);
			var text_y = center_y - (text_height / Pango.SCALE / 2);

			snapshot.translate({ text_x, text_y });
			snapshot.append_layout(layout, color);
		}
	}

	public override void measure(Gtk.Orientation orientation,
								 int for_size,
								 out int minimum,
								 out int natural,
								 out int minimum_baseline,
								 out int natural_baseline) {
		minimum = 24;
		natural = icon_name != null ? minimum : int.max(minimum, font_size * 2);
		minimum_baseline = -1;
		natural_baseline = -1;
	}
}
