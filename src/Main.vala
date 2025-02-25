public static void main(string[] args) {
	var app = new Morghulis();

	init_types();
	app.run(args);
}

private void init_types() {
#if river
	typeof(RiverTags).ensure();
#endif
#if hyprland
	typeof(HyprWorkspaces).ensure();
#endif
	typeof(QuickMenu).ensure();
	typeof(Backlight).ensure();
	typeof(SysInfo).ensure();
	typeof(QButton).ensure();
	typeof(QNetwork).ensure();
	typeof(QBluetooth).ensure();
	typeof(QPowerProfiles).ensure();
	typeof(QAudioBox).ensure();
	typeof(PowerBox).ensure();
	typeof(Settings).ensure();
	typeof(OnScreenDisplay).ensure();
	typeof(NotificationItem).ensure();
	typeof(QNotifications).ensure();
	typeof(CircularProgressBar).ensure();
	typeof(Tray).ensure();
}
