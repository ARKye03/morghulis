public static void main(string[] args) {
    var app = new Morghulis();

    init_types();
    app.run(args);
}

private void init_types() {
    typeof(MorghulWindow).ensure();
    typeof(MorghulProgressBar).ensure();
    typeof(ScrollableIndicatorMenu).ensure();
#if river
    typeof(RiverTags).ensure();
#endif
#if hyprland
    typeof(HyprWorkspaces).ensure();
#endif
    typeof(QuickMenu).ensure();
    typeof(AppSettings).ensure();
    typeof(Backlight).ensure();
    typeof(QButton).ensure();
    typeof(QNetwork).ensure();
    typeof(QBluetooth).ensure();
    typeof(BatteryBox).ensure();
    typeof(QAudioBox).ensure();
    typeof(PowerBox).ensure();
    typeof(Settings).ensure();
    typeof(OnScreenDisplay).ensure();
    typeof(NotificationItem).ensure();
    typeof(NotificationContent).ensure();
    typeof(QNotifications).ensure();
    typeof(Tray).ensure();
    typeof(SysInfoItem).ensure();
    typeof(CircularProgressBar).ensure();
    typeof(AppsCmd).ensure();
}
