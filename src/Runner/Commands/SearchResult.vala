// Ported from https://github.com/kotontrion/kompass (MIT).
public class SearchResult : Object {
    public string id { get; set; }
    public string name { get; set; }
    public string description { get; set; }
    public Icon icon { get; set; }

    public delegate void ActivateResult(SearchResult result);

    private ActivateResult activate_fun;

    public void set_activate_fun(owned ActivateResult activate_fun) {
        this.activate_fun = (owned) activate_fun;
    }

    public void activate() {
        if (activate_fun != null) {
            activate_fun(this);
        }
    }

    internal static SearchResult from_dbus_data(HashTable<string, Variant> meta, owned ActivateResult activate) {
        var result = new SearchResult();

        var id = meta.lookup("id");
        result.id = id != null ? id.get_string() : "";

        var name = meta.lookup("name");
        result.name = name != null ? name.get_string() : "";

        var description = meta.lookup("description");
        result.description = description != null ? description.get_string() : "";

        var icon = meta.lookup("icon");
        var icon_data = meta.lookup("icon-data");
        if (icon != null) {
            result.icon = Icon.deserialize(icon);
        } else if (icon_data != null) {
            int width, height, rowstride, bits_per_sample, n_channels;
            bool has_alpha;
            Variant data;

            icon_data.get("(iiibii@ay)", out width, out height, out rowstride,
                          out has_alpha, out bits_per_sample, out n_channels, out data);
            var bytes = new Bytes(data.get_data_as_bytes().get_data());

            result.icon = new Gdk.MemoryTexture(width, height,
                                                has_alpha ? Gdk.MemoryFormat.R8G8B8A8 : Gdk.MemoryFormat.R8G8B8,
                                                bytes, rowstride);
        }

        result.activate_fun = (owned) activate;

        return result;
    }
}
