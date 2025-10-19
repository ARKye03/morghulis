public abstract class Rolltop : Gtk.Box {
	private Gtk.DrawingArea _underline;
	private double _target_x = 0.0;
	private double _current_x = 0.0;
	private double _item_width = 0.0;
	private const double ANIMATION_SPEED = 0.15;
	private uint _animation_timeout = 0;

	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 0;

		var items_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);

		_underline = new Gtk.DrawingArea() {
			height_request = 3,
			css_classes = { "accent", "background" }
		};

		_underline.set_draw_func((area, context, width, height) => {
			if (_item_width > 0) {
				context.set_source_rgb(1.0, 1.0, 1.0);
				context.rectangle(_current_x - 5, 0, _item_width + 10, height);
				context.fill();
			}
		});

		this.append(items_box);
		this.append(_underline);

		setup_items_container(items_box);
	}

	protected abstract void setup_items_container(Gtk.Box container);

	protected void add_workspace_item(Gtk.Box container, WorkspaceItem item) {
		container.append(item);
	}

	protected void update_underline_position(int focused_index) {
		var items_container = get_items_container();
		var current_child = items_container.get_first_child();

		if (current_child == null) {
			return;
		}

		int current_index = 0;
		while (current_child != null && current_index < focused_index) {
			current_child = current_child.get_next_sibling();
			current_index++;
		}

		if (current_child == null) {
			return;
		}

		double x_pos = 0;
		Graphene.Point point = { 0, 0 };
		bool success = current_child.compute_point(items_container, point, out point);

		if (success) {
			x_pos = point.x;
		}

		_item_width = current_child.get_width();
		_target_x = x_pos;

		start_animation();
	}

	private Gtk.Box get_items_container() {
		return (Gtk.Box)this.get_first_child();
	}

	private void start_animation() {
		if (_animation_timeout != 0) {
			return;
		}

		_animation_timeout = Timeout.add(16, () => {
			double diff = _target_x - _current_x;

			if (Math.fabs(diff) < 0.5) {
				_current_x = _target_x;
				_underline.queue_draw();
				_animation_timeout = 0;
				return false;
			}

			_current_x += diff * ANIMATION_SPEED;
			_underline.queue_draw();
			return true;
		});
	}
}
