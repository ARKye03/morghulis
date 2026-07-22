// Bridge to any org.gnome.Shell.SearchProvider2 DBus provider.
// Ported from https://github.com/kotontrion/kompass (MIT).
[DBus(name = "org.gnome.Shell.SearchProvider2")]
internal interface IGnomeSearchProvider : DBusProxy {
    public abstract async string[] get_initial_result_set(string[] terms) throws DBusError, IOError;
    public abstract async HashTable<string, Variant>[] get_result_metas(string[] ids) throws DBusError, IOError;
    public abstract async void activate_result(string id, string[] terms, uint timestamp) throws DBusError, IOError;
}

public class GnomeSearchProvider : Object {
    private IGnomeSearchProvider proxy;
    private uint search_serial = 0;

    public ListStore results { get; construct; }
    public string provider_name { get; private set; }
    public Icon provider_icon { get; private set; }
    public string ini_path { get; construct; }

    public GnomeSearchProvider(string ini_path) {
        Object(ini_path: ini_path);
    }

    construct {
        results = new ListStore(typeof(SearchResult));

        try {
            var keyfile = new KeyFile();
            keyfile.load_from_data_dirs("gnome-shell/search-providers/" + ini_path, null, KeyFileFlags.NONE);

            string desktop_id = keyfile.get_string("Shell Search Provider", "DesktopId");
            string bus_name = keyfile.get_string("Shell Search Provider", "BusName");
            string object_path = keyfile.get_string("Shell Search Provider", "ObjectPath");

            var desktop_keyfile = new KeyFile();
            desktop_keyfile.load_from_data_dirs("applications/" + desktop_id, null, KeyFileFlags.NONE);
            provider_name = desktop_keyfile.get_string("Desktop Entry", "Name");
            provider_icon = new ThemedIcon(desktop_keyfile.get_string("Desktop Entry", "Icon"));

            Bus.get_proxy.begin<IGnomeSearchProvider>(BusType.SESSION, bus_name, object_path, 0, null, (obj, res) => {
                try {
                    proxy = Bus.get_proxy.end(res);
                } catch (Error e) {
                    warning("Could not create search provider proxy for %s: %s", ini_path, e.message);
                }
            });
        } catch (Error e) {
            warning("Could not load search provider %s: %s", ini_path, e.message);
        }
    }

    public async void search(string query) {
        uint serial = ++search_serial;

        if (proxy == null || query.strip() == "") {
            results.remove_all();
            return;
        }

        string[] terms = query.split(" ");
        HashTable<string, Variant>[] metas = null;
        try {
            var ids = yield proxy.get_initial_result_set(terms);
            if (ids != null && ids.length > 0) {
                metas = yield proxy.get_result_metas(ids);
            }
        } catch (Error e) {
            warning("Search provider query failed: %s", e.message);
            return;
        }

        if (serial != search_serial) {
            return;
        }

        results.remove_all();
        if (metas == null) {
            return;
        }

        foreach (var meta in metas) {
            var search_result = SearchResult.from_dbus_data(meta, (result) => {
                proxy.activate_result.begin(result.id, terms, 0);
            });
            results.append(search_result);
        }
    }
}
