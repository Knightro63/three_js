import 'ellipse_curve.dart';

/// Alias for [EllipseCurve].
class ArcCurve extends EllipseCurve{
  bool isArcCurve = true;
  ArcCurve(super.aX, super.aY, super.aRadius,super.aStartAngle,super.aEndAngle,super.aClockwise );
}
