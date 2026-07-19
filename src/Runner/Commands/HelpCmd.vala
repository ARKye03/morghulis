[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Commands/HelpCmd.ui")]
public class HelpCmd : Gtk.Box {
    private unowned GLib.List<weak Command?> commands;

    [GtkChild]
    private unowned Gtk.Box commands_box;

    public HelpCmd(GLib.List<weak Command?> cmds) {
        Object();
        this.commands = cmds;
        populate_commands();
    }

    private void populate_commands() {
        foreach (var cmd in commands) {
            var cmd_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);

            var name_label = new Gtk.Label(":" + cmd.name) {
                css_classes = { "title-2" },
                halign = Gtk.Align.START,
            };

            var desc_label = new Gtk.Label(cmd.description) {
                css_classes = { "title_5" },
                halign = Gtk.Align.START,
            };

            cmd_box.append(name_label);
            cmd_box.append(desc_label);
            commands_box.append(cmd_box);
        }
    }

    public void refresh() {
        // Clear existing commands
        var child = commands_box.get_first_child();

        while (child != null) {
            var next = child.get_next_sibling();
            commands_box.remove(child);
            child = next;
        }

        // Repopulate
        populate_commands();
    }
}
