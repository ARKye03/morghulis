public static void main (string[] args) {
	var app = new Morghulis();
	init_types();
	app.run(args);
}

private void init_types () {
	typeof(QuickSettings).ensure();
	typeof(QuickSettingsButton).ensure();
	typeof(ImageFrame).ensure();
}