import 'package:three_js_math/three_js_math.dart';

import '../vector/index.dart';
import '../objects/plane.dart';
import '../matrix/index.dart';

/// A sphere defined by a center and radius.
class BoundingSphere{
  late Vector3 center;
  late double radius;

  /// [center] - center of the sphere. Default is a [Vector3]
  /// at `(0, 0, 0)`.
  /// 
  /// [radius] - radius of the sphere. Default is `-1`.
  BoundingSphere([Vector3? center, double? radius]){
    this.center = center ?? Vector3.zero();
    this.radius = radius ?? double.infinity;
  } 

  /// Copies the values of the passed sphere's [center] and
  /// [radius] properties to this sphere.
  BoundingSphere.copy(BoundingSphere sphere){
    center = Vector3.copy(sphere.center);
    radius = sphere.radius;
  }

  /// [center] - center of the sphere.
  /// 
  /// [radius] - radius of the sphere.
  /// 
  /// Sets the [center] and [radius] properties of
  /// this sphere.
  /// 
  /// Please note that this method only copies the values from the given center.
  BoundingSphere set(Vector3 center, double radius) {
    this.center.setFrom(center);
    radius = radius;

    return this;
  }

  /// Returns a new sphere with the same [center] and [radius] as this one.
  BoundingSphere clone() {
    return BoundingSphere().setFrom(this);
  }

  /// Copies the values of the passed sphere's [center] and
  /// [radius] properties to this sphere.
  BoundingSphere setFrom(BoundingSphere sphere) {
    center.setFrom(sphere.center);
    radius = sphere.radius;

    return this;
  }

  /// Makes the sphere empty by setting [center] to (0, 0, 0) and
  /// [radius] to -1.
  BoundingSphere empty() {
    center.x = 0;
    center.y = 0;
    center.z = 0;
    
    radius = double.infinity;

    return this;
  }

  /// [matrix] - the [Matrix4] to apply
  /// 
  /// Transforms this sphere with the provided [Matrix4].
  BoundingSphere applyMatrix4(Matrix4 matrix) {
    center.applyMatrix4(matrix);

    radius = radius * matrix.getMaxScaleOnAxis();

    return this;
  }

  /// [plane] - Plane to check for intersection against.
  /// 
  /// Determines whether or not this sphere intersects a given [plane].
  bool intersectsPlane(Plane plane) {
    return plane.distanceToPoint(center).abs() <= radius;
  }

  /// [box] - [page:Box3] to check for intersection against.
  /// 
  /// Determines whether or not this sphere intersects a given [box].
  bool intersectsBox(BoundingBox box) {
    return box.intersectsSphere(this);
  }
}