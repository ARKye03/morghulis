// Temporary
public class WeatherBox : Gtk.Box {
	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 12;
		this.margin_top = this.margin_bottom = 16;
		this.margin_start = this.margin_end = 16;

		var title = new Gtk.Label("Weather");
		title.add_css_class("title-2");
		this.append(title);

		var weather_info = new Gtk.Label("🌤️ 22°C - Partly Cloudy\n📍 Current Location\n💨 Wind: 5 km/h");
		weather_info.add_css_class("body");
		weather_info.justify = Gtk.Justification.CENTER;
		this.append(weather_info);

		var note = new Gtk.Label("(This is a placeholder - integrate with weather API)");
		note.add_css_class("caption");
		note.add_css_class("dim-label");
		this.append(note);
	}
}
