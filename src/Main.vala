public static void main (string[] args) {
	var app = new Morghulis();
	init_types();
	app.run(args);
}

private void init_types () {
	typeof(SideDashboard).ensure();
	typeof(sdButton).ensure();
	typeof(sdPowerBox).ensure();
	typeof(OnScreenDisplay).ensure();
}