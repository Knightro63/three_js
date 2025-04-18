import 'dart:math' as math;
import 'dart:js_interop';

@JS('Box3')
class BoundingBox{
  external BoundingBox([Vector3? min, Vector3? max]);

  BoundingBox.copy(BoundingBox box){
    BoundingBox(box.min,box.max);
  }

  external BoundingBox copy(BoundingBox box);

  external Vector3 min;
  external Vector3 max;

  external BoundingBox set(Vector3 min, Vector3 max);

  external BoundingBox setFromArray(List<double> array);
	external BoundingBox setFromPoints(List<Vector3> points );
  external BoundingBox clone();
  BoundingBox setFrom(BoundingBox box){
    return copy(box);
  }
  external BoundingBox expandByVector(Vector3 vector);
  external BoundingBox expandByPoint(Vector3 point);
  BoundingBox empty(){
    return makeEmpty();
  }
  external BoundingBox makeEmpty();
  external bool isEmpty();
  external Vector3 getCenter(Vector3 target);

  external BoundingBox setFromBuffer(BufferAttribute source);
  external bool intersectsBox(BoundingBox box);
  
  external bool containsPoint(Vector point);
  external bool intersectsPlane(Plane plane);
  external bool intersectsSphere(BoundingSphere sphere);
  external Vector3 clampPoint(Vector3 point, Vector3 target);
  external bool intersectsTriangle(Triangle triangle);
  
  external bool satForAxes(List axes, Vector3 v0, Vector3 v1, Vector3 v2, Vector3 extents);
}
