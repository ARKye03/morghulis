public static void main(string[] args) {
	var app = new Morghulis();

	init_types();
	app.run(args);
}

private void init_types() {
	typeof(HyprWorkspaces).ensure();
	typeof(QuickMenu).ensure();
	typeof(SysInfo).ensure();
	typeof(QButton).ensure();
	typeof(QNetwork).ensure();
	typeof(QBluetooth).ensure();
	typeof(QPowerProfiles).ensure();
	typeof(PowerBox).ensure();
	typeof(Settings).ensure();
	typeof(SliderBox).ensure();
	typeof(OnScreenDisplay).ensure();
	typeof(NotifPop).ensure();
	typeof(NotifWindow).ensure();
	typeof(CircularProgressBar).ensure();
	typeof(Tray).ensure();
}
