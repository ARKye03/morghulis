public class Daemon : Object {
private SocketService service;
public string socket_path { get; private set; }
private Morghulis app;

public Daemon (Morghulis app) {
	this.app = app;
}

public void setup_socket_service () {
	var rundir = GLib.Environment.get_user_runtime_dir ();
	socket_path = @"$rundir/morghulis.sock";

	if (FileUtils.test (socket_path, GLib.FileTest.EXISTS)) {
		try {
			File.new_for_path (socket_path).delete (null);
		} catch (Error err) {
			critical (err.message);
		}
	}

	try {
		service = new SocketService ();
		service.add_address (
			new UnixSocketAddress (socket_path),
			SocketType.STREAM,
			SocketProtocol.DEFAULT,
			null,
			null
			);

		service.incoming.connect ((conn) => {
				handle_socket_request.begin (conn);
				return true;
			});

		info ("Socket service started: %s", socket_path);
	} catch (Error err) {
		critical ("Could not start socket service: %s", err.message);
	}
}

private async void handle_socket_request (SocketConnection conn) {
	try {
		var input = new DataInputStream (conn.input_stream);
		size_t length;
		var message = yield input.read_upto_async ("\0", -1, Priority.DEFAULT, null, out length);

		if (message != null) {
			var response = app.process_command (message);
			yield conn.output_stream.write_async (response.data, Priority.DEFAULT);
		}
	} catch (Error err) {
		critical ("Error handling socket request: %s", err.message);
	}
}
}