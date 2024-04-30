import 'package:vector_math/vector_math.dart';
import '../matrix/matrix3_util.dart';

final _vector1 = Vector3.zero();
final _normalMatrix = Matrix3.identity();

extension PlaneUtil on Plane{
  Plane clone() {
    return Plane.copy(this);
  }

  Vector3 coplanarPoint(Vector3 target) {
    target.setFrom(normal);
    target.scale(-constant);
    return target;
  }

  Plane applyMatrix4(Matrix4 matrix, [Matrix3? optionalNormalMatrix]) {
    final normalMatrix = optionalNormalMatrix ?? _normalMatrix.getNormalMatrix(matrix);
    final referencePoint = coplanarPoint(_vector1)..applyMatrix4(matrix);
    final normal = this.normal..applyMatrix3(normalMatrix)..normalize();
    constant = -referencePoint.dot(normal).toDouble();
    return this;
  }

  double distanceToPoint(Vector3 point) {
    return normal.dot(point) + constant;
  }

}