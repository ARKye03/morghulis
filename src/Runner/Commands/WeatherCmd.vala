using Gtk;
using Soup;
using Json;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/WeatherCmd.ui")]
public class WeatherBox : Gtk.Box, ICommand {
    private Soup.Session _session;
    private const string IP_API_URL
        = "https://ipapi.co/json/";
    private const string IP_API_Fallback_URL
        = "http://ip-api.com/json";
    private const string GEOCODING_API_URL
        = "https://geocoding-api.open-meteo.com/v1/search?name=%s&count=1&language=%s&format=json";
    private const string OPEN_METEO_FORECAST_API_URL
        = "https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&hourly=temperature_2m,precipitation_probability,apparent_temperature,wind_speed_10m&timezone=auto";

    public string view_state { get; set; default = "initial"; }
    public string temp { get; set; default = "--°C"; }
    public string condition { get; set; default = "Unknown"; }
    public string location { get; set; default = "Detecting..."; }
    public string updated_at { get; set; default = "Never"; }
    public string apparent { get; set; default = "--°C"; }
    public string precip { get; set; default = "--%"; }
    public string wind { get; set; default = "-- km/h"; }
    public string error_msg { get; set; default = "Unknown error"; }

    public string icon_name { get { return "weather-symbolic"; } }

    public void handle_input(string input) {
    }

    public override void on_activate() {
        refresh_weather.begin();
    }

    construct {
        _session = new Soup.Session();
        _session.user_agent = "Morghulis/1.0";
    }

    private async void refresh_weather() {
        if (view_state == "loading") {
            return;
        }
        view_state = "loading";

        try {
            // 1. Get location from IP
            // We use ipapi.co but with User-Agent and status check
            var ip_msg = new Soup.Message("GET", IP_API_URL);
            var ip_bytes = yield _session.send_and_read_async(ip_msg, Priority.DEFAULT, null);

            if (ip_msg.status_code != 200) {
                // Fallback to ip-api.com if ipapi.co fails (it often rate-limits)
                ip_msg = new Soup.Message("GET", IP_API_Fallback_URL);
                ip_bytes = yield _session.send_and_read_async(ip_msg, Priority.DEFAULT, null);
            }

            if (ip_msg.status_code != 200) {
                throw new GLib.Error(Quark.from_string("WeatherError"), 0, "Network error: %u".printf(ip_msg.status_code));
            }

            var ip_parser = new Json.Parser();
            ip_parser.load_from_data((string)ip_bytes.get_data());
            var ip_root = ip_parser.get_root().get_object();

            string? city_name = null;
            if (ip_root.has_member("city")) {
                city_name = ip_root.get_string_member("city");
            } else {
                throw new GLib.Error(Quark.from_string("WeatherError"), 0, "Could not detect city from IP");
            }

            string lang = "en";
            string? locale = GLib.Intl.setlocale(GLib.LocaleCategory.ALL, null);
            if (locale != null) {
                lang = locale.split(".")[0].split("_")[0];
            }

            // 2. Geocoding
            string escaped_city = GLib.Uri.escape_string(city_name, "", false);
            string geo_url = GEOCODING_API_URL.printf(escaped_city, lang);
            var geo_msg = new Soup.Message("GET", geo_url);
            var geo_bytes = yield _session.send_and_read_async(geo_msg, Priority.DEFAULT, null);

            if (geo_msg.status_code != 200) {
                throw new GLib.Error(Quark.from_string("WeatherError"), 0, "Geocoding error: %u".printf(geo_msg.status_code));
            }

            var geo_parser = new Json.Parser();
            geo_parser.load_from_data((string)geo_bytes.get_data());
            var geo_root = geo_parser.get_root().get_object();

            if (!geo_root.has_member("results")) {
                throw new GLib.Error(Quark.from_string("WeatherError"), 1, "Location not found");
            }
            var results = geo_root.get_array_member("results");

            if (results.get_length() == 0) {
                throw new GLib.Error(Quark.from_string("WeatherError"), 1, "Location not found");
            }
            var loc_obj = results.get_object_element(0);
            double lat = loc_obj.get_double_member("latitude");
            double lon = loc_obj.get_double_member("longitude");
            string name = loc_obj.get_string_member("name");
            string country = loc_obj.get_string_member("country");

            // 3. Weather Forecast
            string weather_url = OPEN_METEO_FORECAST_API_URL.printf(lat, lon);
            var weather_msg = new Soup.Message("GET", weather_url);
            var weather_bytes = yield _session.send_and_read_async(weather_msg, Priority.DEFAULT, null);

            if (weather_msg.status_code != 200) {
                throw new GLib.Error(Quark.from_string("WeatherError"), 0, "Forecast error: %u".printf(weather_msg.status_code));
            }

            var weather_parser = new Json.Parser();
            weather_parser.load_from_data((string)weather_bytes.get_data());
            var weather_root = weather_parser.get_root().get_object();
            var hourly = weather_root.get_object_member("hourly");

            var now = new DateTime.now_local();
            int current_hour = now.get_hour();

            var temps = hourly.get_array_member("temperature_2m");
            var apparents = hourly.get_array_member("apparent_temperature");
            var precips = hourly.get_array_member("precipitation_probability");
            var winds = hourly.get_array_member("wind_speed_10m");

            double current_t = temps.get_double_element(current_hour);
            double current_a = apparents.get_double_element(current_hour);
            int current_p = (int)precips.get_int_element(current_hour);
            double current_w = winds.get_double_element(current_hour);

            this.temp = "%.1f°C".printf(current_t);
            this.location = "%s, %s".printf(name, country);
            this.apparent = "%.1f°C".printf(current_a);
            this.precip = "%d%%".printf(current_p);
            this.wind = "%.1f km/h".printf(current_w);
            this.condition = get_condition_text(current_p);
            this.updated_at = "Updated at %02d:00".printf(current_hour);

            this.view_state = "success";
        } catch (Error e) {
            warning("Failed to fetch weather: %s", e.message);
            this.error_msg = e.message;
            this.view_state = "error";
        }
    }

    private string get_condition_text(int precip_prob) {
        if (precip_prob > 70) {
            return "Rainy";
        }
        if (precip_prob > 30) {
            return "Cloudy";
        }
        return "Clear";
    }
}
