public struct HistoryItem {
    public string expression;
    public string result;
    public int64 timestamp;
}

public class MathHistoryManager : Object {
    private KeyFile key_file;
    private string file_path;
    private uint _max_days_to_remember;

    construct {
        //  _max_days_to_remember = Morghulis.gsettings.get_uint("math-history-max-days");
        _max_days_to_remember = 7;

        key_file = new KeyFile();
        string data_dir = Environment.get_user_data_dir();
        string dir_path = Path.build_filename(data_dir, "morghulis");
        file_path = Path.build_filename(dir_path, "math_history.ini");

        if (!FileUtils.test(dir_path, FileTest.EXISTS)) {
            DirUtils.create_with_parents(dir_path, 0755);
        }

        load_history();
    }

    private void load_history() {
        try {
            key_file.load_from_file(file_path, KeyFileFlags.NONE);
        } catch (Error e) {
            // File might not exist yet
            debug("Failed to load history: %s", e.message);
        }
    }

    public void add_entry(string expression, string result) {
        var now = new DateTime.now_local();
        string date_group = now.format("%Y-%m-%d");
        string timestamp = now.to_unix().to_string();
        string value = "%s|%s".printf(expression, result);

        key_file.set_string(date_group, timestamp, value);
        save_history();
        prune_history();
    }

    private void save_history() {
        try {
            string data = key_file.to_data(null);
            FileUtils.set_contents(file_path, data);
        } catch (Error e) {
            warning("Failed to save history: %s", e.message);
        }
    }

    public List<string> get_groups() {
        string[] groups = key_file.get_groups();
        var list = new List<string>();
        foreach (string g in groups) {
            list.append(g);
        }
        list.sort((a, b) => strcmp(b, a));
        return list;
    }

    public List<HistoryItem?> get_items_for_group(string group) {
        var items = new List<HistoryItem?>();
        try {
            string[] keys = key_file.get_keys(group);
            foreach (string key in keys) {
                string val = key_file.get_string(group, key);
                string[] parts = val.split("|", 2);
                if (parts.length == 2) {
                    items.append(HistoryItem() {
                        expression = parts[0],
                        result = parts[1],
                        timestamp = int64.parse(key)
                    });
                }
            }
            // Sort by timestamp descending
            items.sort((a, b) => (int)(b.timestamp - a.timestamp));
        } catch (Error e) {
            warning("Error reading group %s: %s", group, e.message);
        }
        return items;
    }

    public void prune_history() {
        string[] groups = key_file.get_groups();
        if (groups.length <= _max_days_to_remember) {
            return;
        }

        var group_list = new List<string>();
        foreach (string g in groups) {
            group_list.append(g);
        }
        group_list.sort((a, b) => strcmp(b, a)); // Descending

        int count = 0;
        foreach (string g in group_list) {
            count++;
            if (count > _max_days_to_remember) {
                try {
                    key_file.remove_group(g);
                } catch (Error e) {}
            }
        }
        save_history();
    }

    public void clear_history() {
        string[] groups = key_file.get_groups();
        foreach (string group in groups) {
            try {
                key_file.remove_group(group);
            } catch (Error e) {}
        }
        save_history();
    }
}
