import 'package:three_js/three_js.dart';
import 'bezier.dart';
import 'enums.dart';
import 'types.dart';
import 'dart:math' as math;

class Utils{
  static void calculateRandomPositionAndVelocityOnSphere(
    Vector3 position,
    Quaternion quaternion,
    Vector3 velocity,
    double speed,
    Sphere sphere
  ){
    final radius = sphere.radius!;
    final arc = sphere.arc!;
    final radiusThickness = sphere.radiusThickness!;
    final u = math.Random().nextDouble() * (arc / 360);
    final v = math.Random().nextDouble();
    final randomizedDistanceRatio = math.Random().nextDouble();
    final theta = 2 * math.pi * u;
    final phi = math.acos(2 * v - 1);
    final sinPhi = math.sin(phi);

    final xDirection = sinPhi * math.cos(theta);
    final yDirection = sinPhi * math.sin(theta);
    final zDirection = math.cos(phi);
    final normalizedThickness = 1 - radiusThickness;

    position.x =
      radius * normalizedThickness * xDirection +
      radius * radiusThickness * randomizedDistanceRatio * xDirection;
    position.y =
      radius * normalizedThickness * yDirection +
      radius * radiusThickness * randomizedDistanceRatio * yDirection;
    position.z =
      radius * normalizedThickness * zDirection +
      radius * radiusThickness * randomizedDistanceRatio * zDirection;

    position.applyQuaternion(quaternion);

    final speedMultiplierByPosition = 1 / position.length;
    velocity.setValues(
      position.x * speedMultiplierByPosition * speed,
      position.y * speedMultiplierByPosition * speed,
      position.z * speedMultiplierByPosition * speed
    );
    velocity.applyQuaternion(quaternion);
  }

  static void calculateRandomPositionAndVelocityOnCone(
    Vector3 position,
    Quaternion quaternion,
    Vector3 velocity,
    double speed,
    Cone cone
  ){
    final double radius = cone.radius!;
    final double radiusThickness = cone.radiusThickness!;
    final double arc = cone.arc!;
    final double angle = cone.angle ?? 90.0;

    final theta = 2 * math.pi * math.Random().nextDouble() * (arc / 360);
    final randomizedDistanceRatio = math.Random().nextDouble();

    final xDirection = math.cos(theta);
    final yDirection = math.sin(theta);
    final normalizedThickness = 1 - radiusThickness;

    position.x =
      radius * normalizedThickness * xDirection +
      radius * radiusThickness * randomizedDistanceRatio * xDirection;
    position.y =
      radius * normalizedThickness * yDirection +
      radius * radiusThickness * randomizedDistanceRatio * yDirection;
    position.z = 0;

    position.applyQuaternion(quaternion);

    final positionLength = position.length;
    final normalizedAngle = (
      (positionLength / radius) * MathUtils.degToRad(angle)
    ).abs();
    final sinNormalizedAngle = math.sin(normalizedAngle);

    final speedMultiplierByPosition = 1 / positionLength;
    velocity.setValues(
      position.x * sinNormalizedAngle * speedMultiplierByPosition * speed,
      position.y * sinNormalizedAngle * speedMultiplierByPosition * speed,
      math.cos(normalizedAngle) * speed
    );
    velocity.applyQuaternion(quaternion);
  }

  static void calculateRandomPositionAndVelocityOnBox(
    Vector3 position,
    Quaternion quaternion,
    Vector3 velocity,
    double speed,
    Box box
  ){
    final _scale = box.scale!;
    final emitFrom = box.emitFrom!;
    switch (emitFrom) {
      case EmitFrom.volume:
        position.x = math.Random().nextDouble() * _scale.x - _scale.x / 2;
        position.y = math.Random().nextDouble() * _scale.y - _scale.y / 2;
        position.z = math.Random().nextDouble() * _scale.z - _scale.z / 2;
        break;

      case EmitFrom.shell:
        final side = (math.Random().nextDouble() * 6).floor();
        final perpendicularAxis = side % 3;
        final shellResult = [];
        shellResult[perpendicularAxis] = side > 2 ? 1 : 0;
        shellResult[(perpendicularAxis + 1) % 3] = math.Random().nextDouble();
        shellResult[(perpendicularAxis + 2) % 3] = math.Random().nextDouble();
        position.x = shellResult[0] * _scale.x - _scale.x / 2;
        position.y = shellResult[1] * _scale.y - _scale.y / 2;
        position.z = shellResult[2] * _scale.z - _scale.z / 2;
        break;

      case EmitFrom.edge:
        final side2 = (math.Random().nextDouble() * 6).floor();
        final perpendicularAxis2 = side2 % 3;
        final edge = (math.Random().nextDouble() * 4).floor();
        final edgeResult = [];
        edgeResult[perpendicularAxis2] = side2 > 2 ? 1 : 0;
        edgeResult[(perpendicularAxis2 + 1) % 3] =
          edge < 2 ? math.Random().nextDouble() : edge - 2;
        edgeResult[(perpendicularAxis2 + 2) % 3] =
          edge < 2 ? edge : math.Random().nextDouble();
        position.x = edgeResult[0] * _scale.x - _scale.x / 2;
        position.y = edgeResult[1] * _scale.y - _scale.y / 2;
        position.z = edgeResult[2] * _scale.z - _scale.z / 2;
        break;
    }

    position.applyQuaternion(quaternion);

    velocity.setValues(0, 0, speed);
    velocity.applyQuaternion(quaternion);
  }

  static void calculateRandomPositionAndVelocityOnCircle(
    Vector3 position,
    Quaternion quaternion,
    Vector3 velocity,
    double speed,
    Circle circle
  ){
    final double radius = circle.radius!;
    final double radiusThickness = circle.radiusThickness!;
    final double arc = circle.arc!;

    final theta = 2 * math.pi * math.Random().nextDouble() * (arc / 360);
    final randomizedDistanceRatio = math.Random().nextDouble();

    final xDirection = math.cos(theta);
    final yDirection = math.sin(theta);
    final normalizedThickness = 1 - radiusThickness;

    position.x =
      radius * normalizedThickness * xDirection +
      radius * radiusThickness * randomizedDistanceRatio * xDirection;
    position.y =
      radius * normalizedThickness * yDirection +
      radius * radiusThickness * randomizedDistanceRatio * yDirection;
    position.z = 0;

    position.applyQuaternion(quaternion);

    final positionLength = position.length;
    final speedMultiplierByPosition = 1 / positionLength;
    velocity.setValues(
      position.x * speedMultiplierByPosition * speed,
      position.y * speedMultiplierByPosition * speed,
      0
    );
    velocity.applyQuaternion(quaternion);
  }

  static void calculateRandomPositionAndVelocityOnRectangle(
    Vector3 position,
    Quaternion quaternion,
    Vector3 velocity,
    double speed,
    Rectangle rect
  ){
    final _scale = rect.scale!;
    final _rotation = rect.rotation!;

    final xOffset = math.Random().nextDouble() * _scale.x - _scale.x / 2;
    final yOffset = math.Random().nextDouble() * _scale.y - _scale.y / 2;
    final rotationX = MathUtils.degToRad(_rotation.x);
    final rotationY = MathUtils.degToRad(_rotation.y);
    position.x = xOffset * math.cos(rotationY);
    position.y = yOffset * math.cos(rotationX);
    position.z = xOffset * math.sin(rotationY) - yOffset * math.sin(rotationX);

    position.applyQuaternion(quaternion);

    velocity.setValues(0, 0, speed);
    velocity.applyQuaternion(quaternion);
  }

  /**
   * Creates a default white circle texture using CanvasTexture.
   * @returns {CanvasTexture | null} The generated texture or null if context fails.
   */
  static CanvasTexture? createDefaultParticleTexture(){
    int width = 12;
    int height = 12;
    Uint8Array rgbaData = Uint8Array(width * height * 4);
    double radius = 6;
    double centerX = (width - 1) / 2;
    double centerY = (height - 1) / 2;

    for (int i = 0; i < width * height; i++) {
      // Calculate the x and y coordinates for the current pixel.
      int x = i % width;
      int y = i ~/ width; // Integer division to get the row (y)

      // Calculate the distance of the pixel from the center.
      double distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));

      // Determine if the pixel is inside or outside the circle.
      if (distance <= radius) {
        // Inside the circle: set to red (R=255, G=0, B=0) with full opacity (A=255).
        int rgbaIndex = i * 4;
        rgbaData[rgbaIndex] = 255; // Red
        rgbaData[rgbaIndex + 1] = 255;   // Green
        rgbaData[rgbaIndex + 2] = 255;   // Blue
        rgbaData[rgbaIndex + 3] = 255; // Alpha (fully opaque)
      } else {
        // Outside the circle: set to fully transparent (A=0).
        int rgbaIndex = i * 4;
        rgbaData[rgbaIndex] = 0;   // Red
        rgbaData[rgbaIndex + 1] = 0;   // Green
        rgbaData[rgbaIndex + 2] = 0;   // Blue
        rgbaData[rgbaIndex + 3] = 0;   // Alpha (fully transparent)
      }
    }

    final temp = ImageElement(
      width: 2,
      height: 2,
      data: rgbaData
    );
    return CanvasTexture(temp);
  }

  static bool isLifeTimeCurve(
    value,//: finalant | RandomBetweenTwofinalants | LifetimeCurve
  ){
    return (value !is num && value !is int && value !is double) && value is CurveBase;//typeof value !== 'number' && 'type' in value;
  }

  static CurveFunction getCurveFunctionFromConfig(
    int particleSystemId,
    LifetimeCurve lifetimeCurve 
  ){
    if (lifetimeCurve is BezierCurve) {
      return Bezier.createBezierCurveFunction(
        particleSystemId,
        lifetimeCurve.bezierPoints
      ); // Bézier curve
    }

    if (lifetimeCurve is EasingCurve) {
      return lifetimeCurve.curveFunction!; // Easing curve
    }

    throw('Unsupported value type: ${lifetimeCurve}');
  }

  static double calculateValue(
    int particleSystemId,
    value,//: finalant | RandomBetweenTwoConstants | LifetimeCurve,
    [double time = 0]
  ){
    if (value is num || value is double || value is int) {
      return value; // finalant value
    }

    if(value is RandomBetweenTwoConstants){//'min' in value && 'max' in value) {
      if (value.min == value.max) {
        return value.min ?? 0; // finalant value
      }
      final low = value.min ?? 0;
      final high = value.max ?? 0;
      return low + math.Random().nextDouble() * ( high - low );
    }

    final lifetimeCurve = value as LifetimeCurve;
    return (
      getCurveFunctionFromConfig(particleSystemId, lifetimeCurve)(time) *
      (lifetimeCurve.scale ?? 1)
    );
  }
}