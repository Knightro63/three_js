import 'package:three_js_math/three_js_math.dart';
import '../core/object_3d.dart';

final _sphere = BoundingSphere();
final _vectorFrustum = Vector3.zero();

class Frustum {
  late List<Plane> planes;

  Frustum([Plane? p0, Plane? p1, Plane? p2, Plane? p3, Plane? p4, Plane? p5]) {
    planes = [
      (p0 != null) ? p0 : Plane(),
      (p1 != null) ? p1 : Plane(),
      (p2 != null) ? p2 : Plane(),
      (p3 != null) ? p3 : Plane(),
      (p4 != null) ? p4 : Plane(),
      (p5 != null) ? p5 : Plane()
    ];
  }

  List<List<num>> toList() {
    return planes.map((e) => e.toList()).toList();
  }

  Frustum set(Plane p0, Plane p1, Plane p2, Plane p3, Plane p4, Plane p5) {
    final planes = this.planes;

    planes[0].copyFrom(p0);
    planes[1].copyFrom(p1);
    planes[2].copyFrom(p2);
    planes[3].copyFrom(p3);
    planes[4].copyFrom(p4);
    planes[5].copyFrom(p5);

    return this;
  }

  Frustum clone() {
    return Frustum().copy(this);
  }

  Frustum copy(Frustum frustum) {
    final planes = this.planes;

    for (int i = 0; i < 6; i++) {
      planes[i].copyFrom(frustum.planes[i]);
    }

    return this;
  }

  Frustum setFromMatrix(Matrix4 m) {
    final planes = this.planes;
    final me = m.storage;
    final me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3];
    final me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7];
    final me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11];
    final me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];

    planes[0]
        .setComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12)
        .normalize();
    planes[1]
        .setComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12)
        .normalize();
    planes[2]
        .setComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13)
        .normalize();
    planes[3]
        .setComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13)
        .normalize();
    planes[4]
        .setComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14)
        .normalize();
    planes[5]
        .setComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14)
        .normalize();

    return this;
  }

  bool intersectsObject(Object3D object) {
    final geometry = object.geometry;
    if (geometry == null) return false;

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _sphere.setFrom(geometry.boundingSphere!);

    _sphere.applyMatrix4(object.matrixWorld);

    return intersectsSphere(_sphere);
  }

  bool intersectsSprite(Object3D sprite) {
    _sphere.center.setValues(0, 0, 0);
    _sphere.radius = 0.7071067811865476;
    _sphere.applyMatrix4(sprite.matrixWorld);

    return intersectsSphere(_sphere);
  }

  bool intersectsSphere(BoundingSphere sphere) {
    final planes = this.planes;
    final center = sphere.center;
    final negRadius = -sphere.radius;

    for (int i = 0; i < 6; i++) {
      final distance = planes[i].distanceToPoint(center);
      if (distance < negRadius) {
        return false;
      }
    }

    return true;
  }

  bool intersectsBox(BoundingBox box) {
    final planes = this.planes;

    for (int i = 0; i < 6; i++) {
      final plane = planes[i];

      // corner at max distance

      _vectorFrustum.x = plane.normal.x > 0 ? box.max.x : box.min.x;
      _vectorFrustum.y = plane.normal.y > 0 ? box.max.y : box.min.y;
      _vectorFrustum.z = plane.normal.z > 0 ? box.max.z : box.min.z;

      if (plane.distanceToPoint(_vectorFrustum) < 0) {
        return false;
      }
    }

    return true;
  }

  bool containsPoint(Vector3 point) {
    final planes = this.planes;

    for (int i = 0; i < 6; i++) {
      if (planes[i].distanceToPoint(point) < 0) {
        return false;
      }
    }

    return true;
  }
}
