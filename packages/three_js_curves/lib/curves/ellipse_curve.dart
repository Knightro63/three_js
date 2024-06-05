import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';

///Creates a 2d curve in the shape of an ellipse. Setting the [xRadius] equal to the [yRadius] will result in a circle.
class EllipseCurve extends Curve {
  late num aX;
  late num aY;
  late num xRadius;
  late num yRadius;

  late num aStartAngle;
  late num aEndAngle;
  late bool aClockwise;
  late num aRotation;

  /// [aX] – The X center of the ellipse. Default is `0`.
  /// 
  /// [aY] – The Y center of the ellipse. Default is `0`.
  /// 
  /// [xRadius] – The radius of the ellipse in the x direction.
  /// Default is `1`.
  /// 
  /// [yRadius] – The radius of the ellipse in the y direction.
  /// Default is `1`.
  /// 
  /// [aStartAngle] – The start angle of the curve in radians
  /// starting from the positive X axis. Default is `0`.
  /// 
  /// [aEndAngle] – The end angle of the curve in radians starting
  /// from the positive X axis. Default is `2 x Math.PI`.
  /// 
  /// [aClockwise] – Whether the ellipse is drawn clockwise.
  /// Default is `false`.
  /// 
  /// [aRotation] – The rotation angle of the ellipse in radians,
  /// counterclockwise from the positive X axis (optional). Default is `0`.
  EllipseCurve(aX, aY, xRadius, yRadius, [aStartAngle, aEndAngle, aClockwise, aRotation]) {

    this.aX = aX ?? 0;
    this.aY = aY ?? 0;

    this.xRadius = xRadius ?? 1;
    this.yRadius = yRadius ?? 1;

    this.aStartAngle = aStartAngle ?? 0;
    this.aEndAngle = aEndAngle ?? 2 * math.pi;

    this.aClockwise = aClockwise ?? false;

    this.aRotation = aRotation ?? 0;

    isEllipseCurve = true;
  }

  EllipseCurve.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    aX = json["aX"];
    aY = json["aY"];

    xRadius = json["xRadius"];
    yRadius = json["yRadius"];

    aStartAngle = json["aStartAngle"];
    aEndAngle = json["aEndAngle"];

    aClockwise = json["aClockwise"];

    aRotation = json["aRotation"];

    isEllipseCurve = true;
  }

  @override
  Vector? getPoint(num t, [Vector? optionalTarget]) {
    final point = optionalTarget ?? Vector2();

    const twoPi = math.pi * 2;
    num deltaAngle = aEndAngle - aStartAngle;
    final samePoints = deltaAngle.abs() < MathUtils.epsilon;

    // ensures that deltaAngle is 0 .. 2 PI
    while (deltaAngle < 0) {
      deltaAngle += twoPi;
    }
    while (deltaAngle > twoPi) {
      deltaAngle -= twoPi;
    }

    if (deltaAngle < MathUtils.epsilon) {
      if (samePoints) {
        deltaAngle = 0;
      } else {
        deltaAngle = twoPi;
      }
    }

    if (aClockwise == true && !samePoints) {
      if (deltaAngle == twoPi) {
        deltaAngle = -twoPi;
      } else {
        deltaAngle = deltaAngle - twoPi;
      }
    }

    final angle = aStartAngle + t * deltaAngle;
    double x = aX + xRadius * math.cos(angle);
    double y = aY + yRadius * math.sin(angle);

    if (aRotation != 0) {
      final cos = math.cos(aRotation);
      final sin = math.sin(aRotation);

      final tx = x - aX;
      final ty = y - aY;

      // Rotate the point about the center of the ellipse.
      x = tx * cos - ty * sin + aX;
      y = tx * sin + ty * cos + aY;
    }

    return point.setValues(x, y);
  }

  @override
  EllipseCurve copy(Curve source) {
    if(source is EllipseCurve){
      super.copy(source);

      aX = source.aX;
      aY = source.aY;

      xRadius = source.xRadius;
      yRadius = source.yRadius;

      aStartAngle = source.aStartAngle;
      aEndAngle = source.aEndAngle;

      aClockwise = source.aClockwise;

      aRotation = source.aRotation;
    }

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["aX"] = aX;
    data["aY"] = aY;

    data["xRadius"] = xRadius;
    data["yRadius"] = yRadius;

    data["aStartAngle"] = aStartAngle;
    data["aEndAngle"] = aEndAngle;

    data["aClockwise"] = aClockwise;

    data["aRotation"] = aRotation;

    return data;
  }
}
