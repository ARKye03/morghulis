[CCode(cname = "mpars_evaluate")]
public extern double mpars_evaluate(string expression, out string? error);

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/MathCmd.ui")]
public class MathCmd : Gtk.Box, ICommand {
    private MathHistoryManager _history_manager;
    private string? _last_saved_expression = null;

    public string icon_name { get { return "math-symbolic"; } }

    [GtkChild]
    private unowned Gtk.Label expression_label;
    [GtkChild]
    private unowned Gtk.Label result_label;
    [GtkChild]
    private unowned Gtk.Label error_label;
    [GtkChild]
    private unowned Gtk.Box history_container;
    [GtkChild]
    private unowned Gtk.Box history_box;
    [GtkChild]
    private unowned Gtk.Button clear_button;

    construct {
        _history_manager = new MathHistoryManager();
        clear_button.clicked.connect(on_clear_history);
        populate_history();
    }

    public void handle_input(string input) {
        if (input.strip() != "") {
            evaluate_expression(input);
        } else {
            reset();
        }
    }

    public void evaluate_expression(string expression) {
        if (expression.strip() == "") {
            show_placeholder();
            return;
        }

        expression_label.label = expression;
        expression_label.visible = true;

        string? error;
        double result = mpars_evaluate(expression, out error);

        if (error == null) {
            result_label.label = format_result(result);
            result_label.visible = true;
            error_label.visible = false;
        } else {
            result_label.visible = false;
            error_label.label = "Error: " + error;
            error_label.visible = true;
        }
    }

    private string format_result(double result) {
        // Format the result nicely
        if (result == Math.floor(result) && result >= int.MIN && result <= int.MAX) {
            // It's a whole number, show as integer
            return "%.0f".printf(result);
        } else {
            // It's a decimal, show with appropriate precision
            return "%.10g".printf(result);
        }
    }

    private void show_placeholder() {
        expression_label.visible = false;
        result_label.label = "Enter a math expression";
        result_label.visible = true;
        error_label.visible = false;
    }

    public void reset() {
        show_placeholder();
    }

    public void on_enter() {
        save_current_calculation();
    }

    public void on_deactivate() {
        save_current_calculation();
    }

    private void save_current_calculation() {
        if (expression_label.visible && !error_label.visible && result_label.visible) {
            string expr = expression_label.label;
            if (expr != _last_saved_expression) {
                _history_manager.add_entry(expr, result_label.label);
                populate_history();
                _last_saved_expression = expr;
            }
        }
    }

    private void on_clear_history() {
        _history_manager.clear_history();
        populate_history();
    }

    private void populate_history() {
        var child = history_box.get_first_child();

        while (child != null) {
            var next = child.get_next_sibling();
            history_box.remove(child);
            child = next;
        }

        var groups = _history_manager.get_groups();
        if (groups.length() == 0) {
            history_container.visible = false;
            return;
        }

        history_container.visible = true;

        foreach (string group in groups) {
            var group_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);

            var header = new Gtk.Label(group) {
                css_classes = new string[] { "title-4", "dim-label" },
                halign = Gtk.Align.START,
                margin_start = 6
            };
            group_box.append(header);

            var list_box = new Gtk.ListBox() {
                selection_mode = Gtk.SelectionMode.NONE,
                css_classes = new string[] { "boxed-list" }
            };
            group_box.append(list_box);

            var items = _history_manager.get_items_for_group(group);
            foreach (HistoryItem item in items) {
                var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
                var expr_lbl = new Gtk.Label(item.expression) {
                    hexpand = true,
                    halign = Gtk.Align.START,
                    margin_top = 4,
                    margin_end = 4,
                    margin_bottom = 4,
                    margin_start = 4,
                };

                var res_lbl = new Gtk.Label(item.result) {
                    css_classes = new string[] { "title-4" },
                    margin_top = 4,
                    margin_end = 4,
                    margin_bottom = 4,
                    margin_start = 4,
                };

                row_box.append(expr_lbl);
                row_box.append(res_lbl);

                list_box.append(row_box);
            }

            history_box.append(group_box);
        }
    }
}
