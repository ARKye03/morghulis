using MuParser;

[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/Runner/Commands/MathCmd.ui")]
public class MathCmd : Gtk.Box, ICommand {
    private MathHistoryManager _history_manager;
    private string? _last_saved_expression = null;
    private string _current_expression = "";
    private Parser _parser;

    public string icon_name { get { return "math-symbolic"; } }
    public bool has_result { get; set; }
    public bool has_valid_result {
        get { return has_result && result_label.visible && !error_label.visible; }
    }

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
        _parser = new Parser(){
            decimal_separator = '.',
            argument_separator = ';'
        };

        _parser.define_constant("pi", 3.14159265359);
        _parser.define_constant("e", 2.718281828459);

        clear_button.clicked.connect(on_clear_history);
        populate_history();
    }

    ~MathCmd() {
        // Vala handles the release of _parser automatically if I'm not wrong
    }

    public void handle_input(string input) {
        if (input.strip() != "") {
            evaluate_expression(input);
        } else {
            reset();
        }
    }

    // Spotlight-style inference: does this unprefixed input look like a solvable
    // math expression? Cheap syntactic gate first (skip probing muparser for
    // ordinary app searches), then confirm by evaluating.
    public bool looks_like_math(string input) {
        string s = input.strip();
        if (s.length == 0) {
            return false;
        }
        // Needs an operator/paren AND a digit or known constant. Rejects bare
        // words ("firefox") and bare numbers ("42").
        if (!Regex.match_simple("[-+*/^%()]", s)) {
            return false;
        }
        if (!Regex.match_simple("[0-9]|\\bpi\\b|\\be\\b", s)) {
            return false;
        }
        // If it opens like an arithmetic expression, stay in math even while
        // half-typed ("2+1 *") — don't flash the apps view. Letter-led strings
        // ("python3-pip", "gtk4-layer-shell") must evaluate cleanly to qualify,
        // so hyphenated app names still route to apps.
        if (s[0].isdigit() || s[0] == '.' || s[0] == '(') {
            return true;
        }
        _parser.expression = s;
        double result = _parser.eval();
        return !_parser.has_error && result.is_finite();
    }

    public void evaluate_expression(string expression) {
        if (expression.strip() == "") {
            show_placeholder();
            return;
        }

        _current_expression = expression;

        _parser.expression = expression;
        double result = _parser.eval();

        if (_parser.has_error) {
            has_result = true;
            error_label.label = "Error: " + _parser.error_message;
            error_label.visible = true;
            result_label.visible = false;
        } else {
            result_label.label = format_result(result);
            has_result = true;
            error_label.visible = false;
            result_label.visible = true;
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
        result_label.label = "Enter a math expression";
        has_result = false;
        error_label.visible = false;
    }

    public void reset() {
        show_placeholder();
    }

    public void on_enter() {
        save_current_calculation();
        if (has_valid_result) {
            Gdk.Display.get_default().get_clipboard().set_text(result_label.label);
        }
    }

    public void on_deactivate() {
        reset();
    }

    private void save_current_calculation() {
        if (has_result && !error_label.visible && result_label.visible) {
            string expr = _current_expression;
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
