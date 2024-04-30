import '../vector/index.dart';
import '../objects/plane.dart';
import '../matrix/index.dart';

class BoundingSphere{
  late Vector3 center;
  late double radius;

  BoundingSphere([Vector3? center, double? radius]){
    this.center = center ?? Vector3.zero();
    this.radius = radius ?? double.infinity;
  } 

  BoundingSphere.copy(BoundingSphere sphere){
    center = Vector3.copy(sphere.center);
    radius = sphere.radius;
  }

  BoundingSphere set(Vector3 center, double radius) {
    this.center.setFrom(center);
    radius = radius;

    return this;
  }

  BoundingSphere clone() {
    return BoundingSphere().setFrom(this);
  }

  BoundingSphere setFrom(BoundingSphere sphere) {
    center.setFrom(sphere.center);
    radius = sphere.radius;

    return this;
  }

  BoundingSphere empty() {
    center.x = 0;
    center.y = 0;
    center.z = 0;
    
    radius = double.infinity;

    return this;
  }

  BoundingSphere applyMatrix4(Matrix4 matrix) {
    center.applyMatrix4(matrix);

    radius = radius * matrix.getMaxScaleOnAxis();

    return this;
  }

  bool intersectsPlane(Plane plane) {
    return plane.distanceToPoint(center).abs() <= radius;
  }
}