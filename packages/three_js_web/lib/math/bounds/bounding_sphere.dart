import 'dart:math' as math;
import 'dart:js_interop';

@JS('Sphere')
class BoundingSphere{
  external Vector3 center;
  external double radius;

  external BoundingSphere([Vector3? center, double? radius]);

  BoundingSphere.copy(BoundingSphere sphere){
    BoundingSphere(sphere.center,sphere.radius);
  }

  external BoundingSphere set(Vector3 center, double radius);
  external BoundingSphere clone();
  external BoundingSphere copy(BoundingSphere box);

  BoundingSphere setFrom(BoundingSphere sphere) {
    return copy(sphere);
  }

	external BoundingSphere setFromPoints(List<Vector3> points, [Vector3? optionalCenter ]);

	external bool isEmpty();

	external bool containsPoint(Vector3 point );

  BoundingSphere empty() {
    return makeEmpty();
  }
  external BoundingSphere makeEmpty();
  external BoundingSphere applyMatrix4(Matrix4 matrix);

  external bool intersectsPlane(Plane plane);
  external bool intersectsBox(BoundingBox box);

	external BoundingSphere expandByPoint(Vector point );
	external BoundingSphere union(BoundingSphere sphere );
}