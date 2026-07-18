/**
 * CSS-style cubic Bézier easing curve: y = f(x) for x in [0, 1].
 *
 * Use a preset ({@link linear}, {@link ease}, {@link ease_in}, {@link ease_out},
 * {@link ease_in_out}) or construct with four control-point coordinates for a
 * custom curve (P1 = x1,y1 and P2 = x2,y2; P0 = 0,0 and P3 = 1,1 are fixed).
 */
public class CubicBezier : GLib.Object {
    public double x1 { get; construct; }
    public double y1 { get; construct; }
    public double x2 { get; construct; }
    public double y2 { get; construct; }

    // Polynomial coefficients (WebKit UnitBezier form)
    private double ax; private double bx; private double cx;
    private double ay; private double by; private double cy;

    public CubicBezier(double x1, double y1, double x2, double y2) {
        Object(x1: x1, y1: y1, x2: x2, y2: y2);
    }

    construct {
        cx = 3.0 * x1;
        bx = 3.0 * (x2 - x1) - cx;
        ax = 1.0 - cx - bx;
        cy = 3.0 * y1;
        by = 3.0 * (y2 - y1) - cy;
        ay = 1.0 - cy - by;
    }

    public static CubicBezier linear()     { return new CubicBezier(0.0, 0.0, 1.0, 1.0); }
    public static CubicBezier ease()        { return new CubicBezier(0.25, 0.1, 0.25, 1.0); }
    public static CubicBezier ease_in()     { return new CubicBezier(0.42, 0.0, 1.0, 1.0); }
    public static CubicBezier ease_out()    { return new CubicBezier(0.0, 0.0, 0.58, 1.0); }
    public static CubicBezier ease_in_out() { return new CubicBezier(0.42, 0.0, 0.58, 1.0); }

    private double sample_x(double t) { return ((ax * t + bx) * t + cx) * t; }
    private double sample_y(double t) { return ((ay * t + by) * t + cy) * t; }
    private double sample_dx(double t) { return (3.0 * ax * t + 2.0 * bx) * t + cx; }

    // Find parametric t for a given x, then read y off the curve.
    private double solve_t(double x) {
        double t = x;
        for (int i = 0; i < 8; i++) {              // Newton-Raphson
            double err = sample_x(t) - x;
            if (err.abs() < 1e-6) return t;
            double d = sample_dx(t);
            if (d.abs() < 1e-6) break;
            t -= err / d;
        }

        double lo = 0.0, hi = 1.0;                 // bisection fallback
        t = x;
        for (int i = 0; i < 24; i++) {
            double xv = sample_x(t);
            if ((xv - x).abs() < 1e-6) break;
            if (x > xv) lo = t; else hi = t;
            t = (lo + hi) / 2.0;
        }
        return t;
    }

    public double solve(double x) {
        if (x <= 0.0) return 0.0;
        if (x >= 1.0) return 1.0;
        return sample_y(solve_t(x));
    }
}
