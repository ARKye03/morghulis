using GtkLayerShell;
using AstalMpris;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/OnScreenDisplay.ui")]
public class OnScreenDisplay : Astal.Window {
	public AstalWp.Endpoint speaker { get; set; }

	[GtkChild]
	public unowned Gtk.Stack stack_osd;

	[GtkChild]
	public unowned Gtk.Overlay volume_osd;

	private uint hide_timeout_id = 0;

	construct {
		speaker = AstalWp.get_default().audio.default_speaker;

		//  speaker.bind_property("volume", vol_adjust, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
		speaker.notify["volume"].connect(() => {
			this.visible = true;
			this.stack_osd.visible_child_name = "volume_osd";
			handle_timeout();
		});
	}
	public OnScreenDisplay() {
		Object(namespace : "OnScreenDisplay");
	}

	private void handle_timeout() {
		// Remove the existing timeout if it exists
		if (hide_timeout_id != 0) {
			GLib.Source.remove(hide_timeout_id);
			hide_timeout_id = 0;
		}

		// Set a new timeout
		hide_timeout_id = GLib.Timeout.add(3000, () => {
			this.visible = false;
			hide_timeout_id = 0;
			return false;
		});
	}
}
