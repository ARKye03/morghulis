[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/SysInfo/MathCmd.ui")]
public class MathCmd : Gtk.Box {
	[GtkChild]
	private unowned Gtk.Label expression_label;
	[GtkChild]
	private unowned Gtk.Label result_label;
	[GtkChild]
	private unowned Gtk.Label error_label;

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
}
