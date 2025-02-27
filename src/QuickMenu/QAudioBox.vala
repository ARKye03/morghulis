[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/QAudioBox.ui")]
public class QAudioBox : Gtk.Box {
	public AstalWp.Wp? wp { get; private set; }
	public AstalWp.Endpoint speaker { get; private set; }
	public AstalWp.Endpoint microphone { get; private set; }

	public Gtk.Adjustment speaker_adj { get; private set; }
	public Gtk.Adjustment microphone_adj { get; private set; }

	[GtkChild]
	public unowned Gtk.ListBox sources;

	[GtkChild]
	public unowned Gtk.ListBox mixers;

	[GtkChild]
	public unowned Gtk.ListBox sinks;

	construct {
		this.wp = AstalWp.get_default();
		if (wp == null) {
			critical("Failed to initialize wp");
		} else {
			this.speaker = wp.audio.default_speaker;
			this.microphone = wp.audio.default_microphone;
		}
		this.speaker_adj = new Gtk.Adjustment(speaker.volume, 0, 1, 0, 0, 0);
		this.microphone_adj = new Gtk.Adjustment(microphone.volume, 0, 1, 0, 0, 0);

		speaker.bind_property(
			"volume",
			speaker_adj,
			"value",
			BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
		);

		microphone.bind_property(
			"volume",
			microphone_adj,
			"value",
			BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
		);

		wp.audio.speakers.@foreach((e) => on_added(e, sinks));
		wp.audio.microphones.@foreach((e) => on_added(e, sources));
		wp.audio.streams.@foreach((e) => on_added(e, mixers));

		wp.audio.speaker_added.connect((e) => on_added(e, sinks));
		wp.audio.speaker_removed.connect((e) => on_removed(e, sinks));

		wp.audio.microphone_added.connect((e) => on_added(e, sources));
		wp.audio.microphone_removed.connect((e) => on_removed(e, sources));

		wp.audio.stream_added.connect((e) => on_added(e, mixers));
		wp.audio.stream_removed.connect((e) => on_removed(e, mixers));
	}

	[GtkCallback]
	void toggle_speaker() {
		speaker.mute = !speaker.mute;
	}

	[GtkCallback]
	void toggle_microphone() {
		microphone.mute = !microphone.mute;
	}

	private void on_added(AstalWp.Endpoint e, Gtk.ListBox l) {
		l.append(new QAudioItem(e));
	}

	private void on_removed(AstalWp.Endpoint e, Gtk.ListBox l) {
		var current = (QAudioItem)l.get_first_child();

		while (current != null) {
			if (current.endpoint == e) {
				l.remove(current);
				break;
			}
			current = (QAudioItem)current.get_next_sibling();
		}
	}
}
