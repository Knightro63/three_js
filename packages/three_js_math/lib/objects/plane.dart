import '../bounds/index.dart';
import 'index.dart';
import '../vector/index.dart';
import '../matrix/matrix3.dart';
import '../matrix/matrix4.dart';

class Plane {
  final _vector1 = Vector3.zero();
  final _vector2 = Vector3.zero();
  final _normalMatrix = Matrix3.identity();
  String type = "Plane";

  late Vector3 normal;
  double constant = 0;

  Plane([Vector3? normal, double? constant]) {
    // normal is assumed to be normalized

    this.normal = (normal != null) ? normal : Vector3(1, 0, 0);
    this.constant = (constant != null) ? constant : 0;
  }

  List<double> toList() {
    List<double> data = normal.toList();
    data.add(constant);

    return data;
  }

  Plane set(Vector3 normal, double constant) {
    this.normal.setFrom(normal);
    this.constant = constant;

    return this;
  }

  Plane setComponents(double x, double y, double z, double w) {
    normal.setValues(x, y, z);
    constant = w;

    return this;
  }

  Plane setFromNormalAndCoplanarPoint(Vector3 normal, Vector3 point) {
    this.normal.setFrom(normal);
    constant = -point.dot(this.normal).toDouble();

    return this;
  }

  Plane setFromCoplanarPoints(Vector3 a, Vector3 b, Vector3 c) {
    final normal =
        _vector1.sub2(c, b).cross(_vector2.sub2(a, b)).normalize();

    // Q: should an error be thrown if normal is zero (e.g. degenerate plane)?

    setFromNormalAndCoplanarPoint(normal, a);

    return this;
  }

  Plane clone() {
    return Plane()..copyFrom(this);
  }

  Plane copyFrom(Plane plane) {
    normal.setFrom(plane.normal);
    constant = plane.constant;

    return this;
  }

  Plane normalize() {
    // Note: will lead to a divide by zero if the plane is invalid.

    final inverseNormalLength = 1.0 / normal.length;
    normal.scale(inverseNormalLength);
    constant *= inverseNormalLength;

    return this;
  }

  Plane negate() {
    constant *= -1;
    normal.negate();

    return this;
  }

  double distanceToPoint(Vector3 point) {
    return normal.dot(point) + constant;
  }

  double distanceToSphere(BoundingSphere sphere) {
    return distanceToPoint(sphere.center) - sphere.radius;
  }

  Vector3 projectPoint(Vector3 point, Vector3 target) {
    return target
        .setFrom(normal)
        .scale(-distanceToPoint(point))
        .add(point);
  }
  Vector3? intersectLine(Line3 line, Vector3 target) {
    final direction = line.delta(_vector1);

    final denominator = normal.dot(direction);

    if (denominator == 0) {
      // line is coplanar, return origin
      if (distanceToPoint(line.start) == 0) {
        return target.setFrom(line.start);
      }

      // Unsure if this is the correct method to handle this case.
      return null;
    }

    final t = -(line.start.dot(normal) + constant) / denominator;

    if (t < 0 || t > 1) {
      return null;
    }

    return target.setFrom(direction).scale(t).add(line.start);
  }

  bool intersectsLine(Line3 line) {
    // Note: this tests if a line intersects the plane, not whether it (or its end-points) are coplanar with it.

    final startSign = distanceToPoint(line.start);
    final endSign = distanceToPoint(line.end);

    return (startSign < 0 && endSign > 0) || (endSign < 0 && startSign > 0);
  }

  bool intersectsBox(BoundingBox box) {
    return box.intersectsPlane(this);
  }

  bool intersectsSphere(BoundingSphere sphere) {
    return sphere.intersectsPlane(this);
  }

  Vector3 coplanarPoint(Vector3 target) {
    return target.setFrom(normal).scale(-constant);
  }

  Plane applyMatrix4(Matrix4 matrix, [Matrix3? optionalNormalMatrix]) {
    final normalMatrix =
        optionalNormalMatrix ?? _normalMatrix.getNormalMatrix(matrix);

    final referencePoint = coplanarPoint(_vector1).applyMatrix4(matrix);

    final normal = this.normal.applyMatrix3(normalMatrix).normalize();

    constant = -referencePoint.dot(normal).toDouble();

    return this;
  }

  Plane translate(Vector3 offset) {
    constant -= offset.dot(normal);

    return this;
  }

  bool equals(Plane plane) {
    return plane.normal.equals(normal) && (plane.constant == constant);
  }
}
