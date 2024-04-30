/// Bezier Curves formulas obtained from
/// http://en.wikipedia.org/wiki/Bézier_curve
class PathInterpolations{
  static double catmullRom(double t, double p0, double p1, double p2, double p3) {
    final v0 = (p2 - p0) * 0.5;
    final v1 = (p3 - p1) * 0.5;
    final t2 = t * t;
    final t3 = t * t2;
    return (2 * p1 - 2 * p2 + v0 + v1) * t3 +
        (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 +
        v0 * t +
        p1;
  }

  //

  static double quadraticBezierP0(double t, double p) {
    final k = 1 - t;
    return k * k * p;
  }

  static double quadraticBezierP1(double t, double p) {
    return 2 * (1 - t) * t * p;
  }

  static double quadraticBezierP2(double t, double p) {
    return t * t * p;
  }

  static double quadraticBezier(double t, double p0, double p1, double p2) {
    return quadraticBezierP0(t, p0) +
        quadraticBezierP1(t, p1) +
        quadraticBezierP2(t, p2);
  }

  //

  static double cubicBezierP0(double t, double p) {
    final k = 1 - t;
    return k * k * k * p;
  }

  static double cubicBezierP1(double t, double p) {
    final k = 1 - t;
    return 3 * k * k * t * p;
  }

  static double cubicBezierP2(double t, double p) {
    return 3 * (1 - t) * t * t * p;
  }

  static double cubicBezierP3(double t, double p) {
    return t * t * t * p;
  }

  static double cubicBezier(double t, double p0, double p1, double p2, double p3) {
    return cubicBezierP0(t, p0) +
        cubicBezierP1(t, p1) +
        cubicBezierP2(t, p2) +
        cubicBezierP3(t, p3);
  }
}
