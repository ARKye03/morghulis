public class AppsCmd : Gtk.Widget, ICommand {
	private Gtk.ScrolledWindow _scrolled_window;
	private Gtk.ListBox _app_list;
	private List<FileMonitor> _data_dirs_monitors;
	private uint _reload_timeout = 0;
	public AstalApps.Apps apps { get; construct set; }

	construct {
		this.layout_manager = new Gtk.BinLayout();
		this._app_list = new Gtk.ListBox() {
			selection_mode = Gtk.SelectionMode.NONE,
			overflow = Gtk.Overflow.HIDDEN,
			css_classes = new string[] { "bg_transparent", "bottom_left_right_corner_borders" }
		};
		this._scrolled_window = new Gtk.ScrolledWindow() {
			max_content_height = 400,
			propagate_natural_height = true,
			child = this._app_list
		};

		this._scrolled_window.set_parent(this);
		this.apps = new AstalApps.Apps();

		setup_desktop_file_monitors();
		setup_list_behavior();
		populate_list();
	}

	private void setup_list_behavior() {
		this._app_list.set_sort_func(sort_func);
		this._app_list.set_filter_func(filter_func);
	}

	private int sort_func(Gtk.ListBoxRow la, Gtk.ListBoxRow lb) {
		AppsCmdButton a = (AppsCmdButton)la;
		AppsCmdButton b = (AppsCmdButton)lb;

		if (a.score == b.score) {
			return b.app.frequency - a.app.frequency;
		}
		return (a.score > b.score) ? -1 : 1;
	}

	private bool filter_func(Gtk.ListBoxRow row) {
		AppsCmdButton app = (AppsCmdButton)row;

		return app.score >= 0;
	}

	private void populate_list() {
		if (apps.list == null) {
			return;
		}
		apps.list.foreach(app => {
			this._app_list.append(new AppsCmdButton(app));
		});
	}

	// ICommand interface implementation
	public void handle_input(string input) {
		update_apps(input);
	}

	public void on_activate() {
		// When the apps command becomes active, make sure we have the latest data
		// and trigger an initial filter with empty input to show all apps
		update_apps("");
	}

	public void on_deactivate() {
		// Nothing special needed when deactivating
	}

	public void on_enter() {
		var first_app = (AppsCmdButton)this._app_list.get_first_child();

		message("Launching application: " + first_app.app.name);

		if (first_app != null) {
			first_app.activate();
			// Hide the runner window
			Runner.instance.visible = false;
		}
	}

	public void update_apps(string input) {
		var child = this._app_list.get_first_child();

		while (child != null) {
			if (child is AppsCmdButton) {
				var app = (AppsCmdButton)child;
				app.score = apps.fuzzy_score(input, app.app);
			}
			child = child.get_next_sibling();
		}

		this._app_list.invalidate_sort();
		this._app_list.invalidate_filter();
	}

	private void setup_desktop_file_monitors() {
		_data_dirs_monitors = new List<FileMonitor>();

		string? xdg_data_dirs = Environment.get_variable("XDG_DATA_DIRS");
		// This shouldn't happen right?
		if (xdg_data_dirs == null || xdg_data_dirs == "") {
			xdg_data_dirs = "/usr/local/share:/usr/share";
		}

		// Also include XDG_DATA_HOME (usually ~/.local/share)
		string? xdg_data_home = Environment.get_variable("XDG_DATA_HOME");
		if (xdg_data_home == null) {
			xdg_data_home = Path.build_filename(Environment.get_home_dir(), ".local", "share");
		}

		// Combine all data directories
		string all_dirs = @"$xdg_data_home:$xdg_data_dirs";
		string[] data_dirs = all_dirs.split(":");

		foreach (string data_dir in data_dirs) {
			if (data_dir.strip() == "") {
				continue;
			}

			string applications_dir = Path.build_filename(data_dir.strip(), "applications");

			if (!FileUtils.test(applications_dir, FileTest.IS_DIR)) {
				continue;
			}

			try {
				var file = File.new_for_path(applications_dir);
				var monitor = file.monitor_directory(FileMonitorFlags.NONE);

				monitor.changed.connect(on_desktop_files_changed);
				_data_dirs_monitors.append(monitor);

				debug(@"Monitoring desktop files in: $applications_dir");
			} catch (Error e) {
				warning(@"Failed to monitor directory $applications_dir: $(e.message)");
			}
		}
	}

	private void on_desktop_files_changed(File file, File? other_file, FileMonitorEvent event_type) {
		switch (event_type) {
			case FileMonitorEvent.CREATED:
			case FileMonitorEvent.DELETED:
			case FileMonitorEvent.CHANGED:
				// Check if it's a .desktop file
				string filename = file.get_basename();
				if (filename.has_suffix(".desktop")) {
					debug(@"Desktop file changed: $filename, reloading apps...");
					// Debounce the reload to avoid excessive reloads
					debounce_apps_reload();
				}
			break;

			default:
			break;
		}
	}

	private void debounce_apps_reload() {
		if (_reload_timeout > 0) {
			Source.remove(_reload_timeout);
		}

		_reload_timeout = Timeout.add(500, () => {
			apps.reload();

			_app_list.remove_all();

			populate_list();
			this._app_list.invalidate_filter();
			this._app_list.invalidate_sort();
			_reload_timeout = 0;
			return false;
		});
	}

	~AppsCmd() {
		if (_data_dirs_monitors != null) {
			_data_dirs_monitors.foreach(monitor => {
				monitor.cancel();
			});
		}

		if (_reload_timeout > 0) {
			Source.remove(_reload_timeout);
		}
	}
}
