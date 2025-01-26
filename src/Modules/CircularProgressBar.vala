/*
 * Original work from José Miguel Fonte
 * https://github.com/phastmike/vala-circular-progress-bar
 */

using Gtk;
using Cairo;
public class CircularProgressBar : Gtk.DrawingArea {
	private int _line_width;
	private int _font_size;
	private string _icon_name;
	private double _percentage;
	private string _center_fill_color;
	private string _radius_fill_color;
	private string _progress_fill_color;

	private Cairo.Surface? _cached_icon_surface = null;
	private int _cached_icon_size = 0;
	private string? _cached_icon_name = null;

	[Description(nick = "Center Fill", blurb = "Center Fill toggle")]
	public bool center_filled { set; get; default = false; }

	[Description(nick = "Radius Fill", blurb = "Radius Fill toggle")]
	public bool radius_filled { set; get; default = false; }

	[Description(nick = "Font", blurb = "Font description without size, just the font name")]
	public string font { set; get; default = "URW Gothic"; }

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

	public CircularProgressBar() {
		set_draw_func(draw);

		notify.connect(() => {
			queue_draw();
		});
	}

	public override Gtk.SizeRequestMode get_request_mode() {
		return Gtk.SizeRequestMode.CONSTANT_SIZE;
	}

	public void draw(DrawingArea da, Cairo.Context cr, int width, int height) {
		int w, h;
		int delta;
		Gdk.RGBA color;
		Pango.Layout layout;
		Pango.FontDescription desc;

		cr.save();

		color = Gdk.RGBA();

		int center_x = width / 2;
		int center_y = height / 2;
		int radius = int.min(width / 2, height / 2) - 1;

		int actual_line_width = line_width;
		if (actual_line_width > radius) {
			actual_line_width = radius;
		}

		if (radius - actual_line_width < 0) {
			delta = 0;
			actual_line_width = radius;
		} else {
			delta = radius - (actual_line_width / 2);
		}

		cr.set_line_cap(line_cap);
		cr.set_line_width(actual_line_width);

		// Center Fill
		if (center_filled == true) {
			cr.arc(center_x, center_y, delta, 0, 2 * Math.PI);
			color.parse(center_fill_color);
			Gdk.cairo_set_source_rgba(cr, color);
			cr.fill();
		}

		// Radius Fill
		if (radius_filled == true) {
			cr.arc(center_x, center_y, delta, 0, 2 * Math.PI);
			color.parse(radius_fill_color);
			Gdk.cairo_set_source_rgba(cr, color);
			cr.stroke();
		}

		// Progress/Percentage Fill
		if (percentage > 0) {
			color.parse(progress_fill_color);
			Gdk.cairo_set_source_rgba(cr, color);

			if (line_width == 0) {
				cr.move_to(center_x, center_y);
				cr.arc(center_x,
					   center_y,
					   delta + 1,
					   1.5 * Math.PI,
					   (1.5 + percentage * 2) * Math.PI);
				cr.fill();
			} else {
				cr.arc(center_x,
					   center_y,
					   delta,
					   1.5 * Math.PI,
					   (1.5 + percentage * 2) * Math.PI);
				cr.stroke();
			}
		}

		// Textual information
		var context = get_style_context();
		context.save();
		// FIXME: Gtk4 has changes in the styles that need to be reviewed
		// For now we get the text color from the defaut context.
		color = context.get_color();
		Gdk.cairo_set_source_rgba(cr, color);

		if (icon_name != null) {
			int icon_size = int.min(width, height) / 2;

			// Rebuild cache only if something changed
			if (_cached_icon_surface == null ||
				icon_name != _cached_icon_name ||
				icon_size != _cached_icon_size) {
				_cached_icon_surface = null;
				_cached_icon_name = icon_name;
				_cached_icon_size = icon_size;

				var icon_theme = Gtk.IconTheme.get_for_display(get_display());
				var paintable = icon_theme.lookup_icon(icon_name,
													   null,
													   icon_size,
													   get_scale_factor(),
													   Gtk.TextDirection.NONE,
													   0);
				if (paintable != null) {
					var snapshot = new Gtk.Snapshot();
					paintable.snapshot(snapshot, icon_size, icon_size);

					var node = snapshot.to_node();
					if (node != null) {
						_cached_icon_surface = new Cairo.Surface.similar(
							cr.get_target(),
							Cairo.Content.COLOR_ALPHA,
							icon_size,
							icon_size
							);
						var surface_cr = new Cairo.Context(_cached_icon_surface);
						node.draw(surface_cr);
					}
				}
			}

			// Paint from cache if valid
			if (_cached_icon_surface != null) {
				cr.save();
				cr.translate(center_x - icon_size / 2, center_y - icon_size / 2);
				cr.set_source_surface(_cached_icon_surface, 0, 0);
				cr.paint();
				cr.restore();
			}
		} else {
			layout = Pango.cairo_create_layout(cr);
			int rounded_percentage = (int)Math.round(percentage * 100.0);
			layout.set_text("%d".printf(rounded_percentage), -1);
			desc = Pango.FontDescription.from_string(@"$font $font_size");
			layout.set_font_description(desc);
			Pango.cairo_update_layout(cr, layout);
			layout.get_size(out w, out h);
			cr.move_to(center_x - ((w / Pango.SCALE) / 2), center_y - ((h / Pango.SCALE) / 2));
			Pango.cairo_show_layout(cr, layout);
		}
	}
}
