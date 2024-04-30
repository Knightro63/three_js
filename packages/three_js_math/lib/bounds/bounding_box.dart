import '../vector/index.dart';
import '../objects/plane.dart';
import '../buffer/buffer_attribute.dart';

class BoundingBox{
  BoundingBox([Vector3? min, Vector3? max]) {
    this.min = min ?? Vector3(double.infinity, double.infinity, double.infinity);
    this.max = max ?? Vector3(-double.infinity, -double.infinity, -double.infinity);
  }

  BoundingBox.copy(BoundingBox box){
    min = Vector3.copy(box.min);
    max = Vector3.copy(box.max);
  }

  late Vector3 min;
  late Vector3 max;

  BoundingBox set(Vector3 min, Vector3 max) {
    this.min.setFrom(min);
    this.max.setFrom(max);

    return this;
  }

  BoundingBox setFromArray(List<double> array) {
    double minX = double.infinity;
    double minY = double.infinity;
    double minZ = double.infinity;

    double maxX = -double.infinity;
    double maxY = -double.infinity;
    double maxZ = -double.infinity;

    for (int i = 0, l = array.length; i < l; i += 3) {
      final x = array[i];
      final y = array[i + 1];
      final z = array[i + 2];

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;

      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }

    min.setValues(minX, minY, minZ);
    max.setValues(maxX, maxY, maxZ);

    return this;
  }

  BoundingBox clone() {
    return BoundingBox().setFrom(this);
  }

  BoundingBox setFrom(BoundingBox box) {
    min.setFrom(box.min);
    max.setFrom(box.max);

    return this;
  }
  BoundingBox expandByVector(Vector3 vector) {
    min.sub(vector);
    max.add(vector);

    return this;
  }
  BoundingBox expandByPoint(Vector3 point) {
    min.min(point);
    max.max(point);

    return this;
  }

  BoundingBox empty() {
    min.x = double.infinity;
    min.y = double.infinity;
    min.z = double.infinity;

    max.x = -double.infinity;
    max.y = -double.infinity;
    max.z = -double.infinity;

    return this;
  }

  bool isEmpty() {
    // this is a more robust check for empty than ( volume <= 0 ) because volume can get positive with two negative axes
    return (max.x < min.x) || (max.y < min.y) || (max.z < min.z);
  }

  Vector3 getCenter(Vector3 target) {
    if (isEmpty()) {
      target.setValues(0, 0, 0);
    } 
    else {
      target.add2(min, max).scale(0.5);
    }

    return target;
  }

  BoundingBox setFromBuffer(BufferAttribute source) {
    double minX = double.infinity;
    double minY = double.infinity;
    double minZ = double.infinity;

    double maxX = -double.infinity;
    double maxY = -double.infinity;
    double maxZ = -double.infinity;

    for (int i = 0, l = source.count; i < l; i++) {
      double x = source.getX(i)!.toDouble();
      double y = source.getY(i)!.toDouble();
      double z = source.getZ(i)!.toDouble();

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;

      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }

    min.setValues(minX, minY, minZ);
    max.setValues(maxX, maxY, maxZ);

    return this;
  }
  bool intersectsBox(BoundingBox box) {
    // using 6 splitting planes to rule out intersections.
    return box.max.x < min.x ||
            box.min.x > max.x ||
            box.max.y < min.y ||
            box.min.y > max.y ||
            box.max.z < min.z ||
            box.min.z > max.z?false:true;
  }
  bool containsPoint(Vector3 point) {
    return point.x < min.x ||
            point.x > max.x ||
            point.y < min.y ||
            point.y > max.y ||
            point.z < min.z ||
            point.z > max.z
        ? false
        : true;
  }
  bool intersectsPlane(Plane plane) {
    // We compute the minimum and maximum dot product values. If those values
    // are on the same side (back or front) of the plane, then there is no intersection.

    double min, max;

    if (plane.normal.x > 0) {
      min = plane.normal.x * this.min.x;
      max = plane.normal.x * this.max.x;
    } else {
      min = plane.normal.x * this.max.x;
      max = plane.normal.x * this.min.x;
    }

    if (plane.normal.y > 0) {
      min += plane.normal.y * this.min.y;
      max += plane.normal.y * this.max.y;
    } else {
      min += plane.normal.y * this.max.y;
      max += plane.normal.y * this.min.y;
    }

    if (plane.normal.z > 0) {
      min += plane.normal.z * this.min.z;
      max += plane.normal.z * this.max.z;
    } else {
      min += plane.normal.z * this.max.z;
      max += plane.normal.z * this.min.z;
    }

    return (min <= -plane.constant && max >= -plane.constant);
  }
}
