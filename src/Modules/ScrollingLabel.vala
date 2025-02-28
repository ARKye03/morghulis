/**
 * Original work from https://github.com/kotontrion/kompass
 */
public enum ScrollBehaviour {
	ALTERNATE,
	SLIDE
}

public class ScrollingLabel : Gtk.Widget {
	private Gtk.Label _scroll_label;
	private double _position = 0;
	private int _scroll_direction = -1;
	private int64 _last_time = 0;
	private int64 _delay = 0;

	public double speed { get; set; default = 0.5; }

	public int direction_change_delay { get; set; default = 500; }

	public Gtk.Orientation direction { get; set; default = Gtk.Orientation.HORIZONTAL; }

	public ScrollBehaviour behaviour { get; set; default = ScrollBehaviour.ALTERNATE; }

	public string label {
		get { return this._scroll_label.label; }
		set { this._scroll_label.label = value; }
	}

	construct {
		this._scroll_label = new Gtk.Label("");

		this.overflow = Gtk.Overflow.HIDDEN;

		this._scroll_label.set_parent(this);
		this.add_tick_callback(update_position);
	}

	protected override void measure(Gtk.Orientation orientation,
									int for_size,
									out int minimum,
									out int natural,
									out int minimum_baseline,
									out int natural_baseline) {
		int min = 0;
		int nat = 0;

		this._scroll_label.measure(orientation, -1, out min, out nat, null, null);
		minimum = 0;
		natural = nat;
		minimum_baseline = -1;
		natural_baseline = -1;
	}

	protected override void size_allocate(int width, int height, int baseline) {
		int child_width = 0;
		int child_height = 0;

		Gtk.Requisition child_req;
		this._scroll_label.get_preferred_size(out child_req, null);

		child_width = child_req.width;
		child_height = child_req.height;
		if (this.direction == Gtk.Orientation.HORIZONTAL) {
			this._scroll_label.allocate_size({ (int)this._position, 0, child_width, child_height }, -1);
		} else {
			this._scroll_label.allocate_size({ 0, (int)this._position, child_width, child_height }, -1);
		}
	}

	protected override Gtk.SizeRequestMode get_request_mode() {
		return Gtk.SizeRequestMode.CONSTANT_SIZE;
	}

	private bool update_position(Gtk.Widget widget, Gdk.FrameClock clock) {
		int64 current_time = clock.get_frame_time();

		if (this._last_time == 0) {
			this._last_time = current_time;
			return Source.CONTINUE;
		}

		int64 elapsed = current_time - this._last_time;
		this._last_time = current_time;
		double delta = this.speed * elapsed / 10000;

		bool is_horizontal = (this.direction == Gtk.Orientation.HORIZONTAL);
		double limit = is_horizontal ? this.get_width() : this.get_height();
		double label_size = is_horizontal ? this._scroll_label.get_width() : this._scroll_label.get_height();

		if (this._delay >= 0) {
			this._delay += elapsed / 1000;
			if (this._delay > this.direction_change_delay) {
				this._delay = -1;
			} else {
				return Source.CONTINUE;
			}
		}

		if (this.behaviour == ScrollBehaviour.ALTERNATE) {
			if (this._scroll_direction < 0) {
				if (this._position + label_size > limit) {
					this._position = double.max(limit - label_size, this._position - delta);
				} else {
					this._scroll_direction = 1;
					this._delay = 0;
				}
			} else {
				if (this._position < 0) {
					this._position = double.min(0, this._position + delta);
				} else {
					this._scroll_direction = -1;
					this._delay = 0;
				}
			}
		} else {
			if (this._position + label_size > 0) {
				this._position -= delta;
			} else {
				this._position = limit;
			}
		}

		this.queue_resize();
		return Source.CONTINUE;
	}

	~ScrollingLabel() {
		this._scroll_label.unparent();
	}
}
