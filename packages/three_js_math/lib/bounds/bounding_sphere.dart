import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _v1 = Vector3.zero();
final _v2 = Vector3.zero();
final _box = BoundingBox();

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

	/// Computes the minimum bounding sphere for list of points.
	/// If the optional center point is given, it is used as the sphere's
	/// center. Otherwise, the center of the axis-aligned bounding box
	/// encompassing the points is calculated.
	///
	/// [points] - A list of points in 3D space.
	/// [optionalCenter] - The center of the sphere.
	/// return  A reference to this sphere.
	BoundingSphere setFromPoints(List<Vector3> points, [Vector3? optionalCenter ]) {
		final center = this.center;

		if ( optionalCenter != null ) {
			center.setFrom( optionalCenter );
		} 
    else {
			_box.setFromPoints(points).getCenter(center);
		}

		double maxRadiusSq = 0;

		for (int i = 0, il = points.length; i < il; i ++ ) {
			maxRadiusSq = math.max( maxRadiusSq, center.distanceToSquared( points[ i ] ) );
		}

		this.radius = math.sqrt( maxRadiusSq );

		return this;
	}

	bool isEmpty() {
		return (radius < 0 );
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

  /// [point] - [Vector3] that should be included in the
  /// box.
  ///
  /// Expands the boundaries of this box to include [point].
	BoundingSphere expandByPoint(Vector point ) {
		if(isEmpty()){
			center.setFrom( point );
			radius = 0;
			return this;
		}

		_v1.sub2(point, center);

		final lengthSq = _v1.length2;

		if ( lengthSq > ( radius * radius ) ) {
			// calculate the minimal sphere
			final length = math.sqrt( lengthSq );
			final delta = ( length - radius ) * 0.5;
			center.addScaled( _v1, delta / length );
			radius += delta;
		}

		return this;
	}

  /// [sphere] - Bounding sphere that will be unioned with this
  /// sphere.
  /// 
  /// Expands this sphere to enclose both the original sphere and the given
  /// sphere.
	BoundingSphere union(BoundingSphere sphere ) {
		if (sphere.isEmpty()) {
			return this;
		}

		if (isEmpty()){
			setFrom(sphere);
			return this;
		}

		if(center.equals(sphere.center) == true ) {
			radius = math.max(radius, sphere.radius );
		} else {
			_v2.sub2(sphere.center, center).setLength(sphere.radius);
			expandByPoint(_v1.setFrom( sphere.center ).add(_v2));
			expandByPoint(_v1.setFrom( sphere.center ).sub( _v2));
		}

		return this;
	}
}