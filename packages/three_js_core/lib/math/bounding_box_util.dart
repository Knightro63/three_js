import 'package:three_js_core/core/object_3d.dart';
import 'package:three_js_math/three_js_math.dart';

final _points = [
  Vector3(),
  Vector3(),
  Vector3(),
  Vector3(),
  Vector3(),
  Vector3(),
  Vector3(),
  Vector3()
];
final _vectorBox3 = Vector3.zero();
final _box3box = BoundingBox();

extension Box3 on BoundingBox{
  BoundingBox setFromObject(Object3D object, [bool precise = false]) {
    empty();

    return expandByObject(object, precise);
  }

  BoundingBox expandByObject(Object3D object, [bool precise = false]) {
    // Computes the world-axis-aligned bounding box of an object (including its children),
    // accounting for both the object's, and children's, world transforms

    object.updateWorldMatrix(false, false);

    final geometry = object.geometry;

    if (geometry != null) {
      if (precise &&
          geometry.attributes.isNotEmpty &&
          geometry.attributes['position'] != null) {
        final position = geometry.attributes['position'];
        for (int i = 0, l = position.count; i < l; i++) {
          _vectorBox3.fromBuffer(position, i).applyMatrix4(object.matrixWorld);
          expandByPoint(_vectorBox3);
        }
      } else {
        if (geometry.boundingBox == null) {
          geometry.computeBoundingBox();
        }

        _box3box.setFrom(geometry.boundingBox!);
        _box3box.applyMatrix4(object.matrixWorld);

        union(_box3box);
      }
    }

    final children = object.children;

    for (int i = 0, l = children.length; i < l; i++) {
      expandByObject(children[i], precise);
    }

    return this;
  }

  BoundingBox applyMatrix4(Matrix4 matrix) {
    // transform of empty box is an empty box.
    if (isEmpty()) return this;

    // NOTE: I am using a binary pattern to specify all 2^3 combinations below
    _points[0].setValues(min.x, min.y, min.z).applyMatrix4(matrix); // 000
    _points[1].setValues(min.x, min.y, max.z).applyMatrix4(matrix); // 001
    _points[2].setValues(min.x, max.y, min.z).applyMatrix4(matrix); // 010
    _points[3].setValues(min.x, max.y, max.z).applyMatrix4(matrix); // 011
    _points[4].setValues(max.x, min.y, min.z).applyMatrix4(matrix); // 100
    _points[5].setValues(max.x, min.y, max.z).applyMatrix4(matrix); // 101
    _points[6].setValues(max.x, max.y, min.z).applyMatrix4(matrix); // 110
    _points[7].setValues(max.x, max.y, max.z).applyMatrix4(matrix); // 111

    setFromPoints(_points);

    return this;
  }

  BoundingBox setFromPoints(List<Vector3> points) {
    empty();

    for (int i = 0, il = points.length; i < il; i++) {
      expandByPoint(points[i]);
    }

    return this;
  }

  BoundingBox union(BoundingBox box) {
    min.min(box.min);
    max.max(box.max);

    return this;
  }

  BoundingSphere getBoundingSphere(BoundingSphere target) {
    getCenter(target.center);

    target.radius = getSize(_vectorBox3).length * 0.5;

    return target;
  }
  Vector3 getSize(Vector3 target) {
    return isEmpty() ? target.setValues(0, 0, 0) : target.sub2(max, min);
  }
}