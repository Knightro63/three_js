import '../vector/index.dart';
import '../objects/plane.dart';
import '../buffer/buffer_attribute.dart';

/// Represents an axis-aligned bounding box (AABB) in 3D space.
/// 
/// ```
/// final box = BoundingBox();
///
/// final mesh = Mesh(
///   SphereGeometry(),
///   MeshBasicMaterial()
/// );
///
/// // ensure the bounding box is computed for its geometry
/// // this should be done only once (assuming static geometries)
/// mesh.geometry.computeBoundingBox();
///
/// // ...
///
/// // in the animation loop, compute the current bounding box with the world matrix
/// box.copy( mesh.geometry.boundingBox ).applyMatrix4( mesh.matrixWorld );
/// ```
class BoundingBox{

  /// [min] - (optional) [Vector3] representing the lower (x,
  /// y, z) boundary of the box. Default is ( + Infinity, + Infinity, + Infinity
  /// ).
  /// 
  /// [max] - (optional) [Vector3] representing the upper (x,
  /// y, z) boundary of the box. Default is ( - Infinity, - Infinity, - Infinity
  /// ).
  BoundingBox([Vector3? min, Vector3? max]) {
    this.min = min ?? Vector3(double.infinity, double.infinity, double.infinity);
    this.max = max ?? Vector3(-double.infinity, -double.infinity, -double.infinity);
  }

  /// [box] - [BoundingBox] to copy.
  /// 
  /// Copies the [min] and [max] from [box] to
  /// this box.
  BoundingBox.copy(BoundingBox box){
    min = Vector3.copy(box.min);
    max = Vector3.copy(box.max);
  }

  late Vector3 min;
  late Vector3 max;

  /// [min] - [Vector3] representing the lower (x, y, z)
  /// boundary of the box.
  /// 
  /// [max] - [Vector3] representing the upper (x, y, z)
  /// boundary of the box.
  /// 
  /// Sets the lower and upper (x, y, z) boundaries of this box.
  /// 
  /// Please note that this method only copies the values from the given
  /// objects.
  BoundingBox set(Vector3 min, Vector3 max) {
    this.min.setFrom(min);
    this.max.setFrom(max);

    return this;
  }

  /// [array] - An array attribute of position data that the resulting box will envelop.
  /// 
  /// Sets the upper and lower bounds of this box to include all of the data in
  /// `array`.
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

  /// Returns a new [BoundingBox] with the same [min] and [max] as this one.
  BoundingBox clone() {
    return BoundingBox().setFrom(this);
  }

  /// [box] - [BoundingBox] to copy.
  /// 
  /// Copies the [min] and [max] from [box] to
  /// this box.
  BoundingBox setFrom(BoundingBox box) {
    min.setFrom(box.min);
    max.setFrom(box.max);

    return this;
  }
  
  /// [vector] - [Vector3] to expand the box by.
  /// 
  /// Expands this box equilaterally by [vector]. The width of this
  /// box will be expanded by the x component of [vector] in both
  /// directions. The height of this box will be expanded by the y component of
  /// [vector] in both directions. The depth of this box will be
  /// expanded by the z component of `vector` in both directions.
  BoundingBox expandByVector(Vector3 vector) {
    min.sub(vector);
    max.add(vector);

    return this;
  }
  
  /// [point] - [Vector3] that should be included in the
  /// box.
  /// 
  /// Expands the boundaries of this box to include [point].
  BoundingBox expandByPoint(Vector3 point) {
    min.min(point);
    max.max(point);

    return this;
  }

  /// Makes this box empty.
  BoundingBox empty() {
    min.x = double.infinity;
    min.y = double.infinity;
    min.z = double.infinity;

    max.x = -double.infinity;
    max.y = -double.infinity;
    max.z = -double.infinity;

    return this;
  }

  /// Returns true if this box includes zero points within its bounds.
  /// 
  /// Note that a box with equal lower and upper bounds still includes one
  /// point, the one both bounds share.
  bool isEmpty() {
    // this is a more robust check for empty than ( volume <= 0 ) because volume can get positive with two negative axes
    return (max.x < min.x) || (max.y < min.y) || (max.z < min.z);
  }

  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns the center point of the box as a [Vector3].
  Vector3 getCenter(Vector3 target) {
    if (isEmpty()) {
      target.setValues(0, 0, 0);
    } 
    else {
      target.add2(min, max).scale(0.5);
    }

    return target;
  }

  /// [source] - A buffer attribute of position data that the resulting box will envelop.
  /// 
  /// Sets the upper and lower bounds of this box to include all of the data in
  /// [source].
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
  
  /// [box] - Box to check for intersection against.
  /// 
  /// Determines whether or not this box intersects [box].
  bool intersectsBox(BoundingBox box) {
    // using 6 splitting planes to rule out intersections.
    return box.max.x < min.x ||
            box.min.x > max.x ||
            box.max.y < min.y ||
            box.min.y > max.y ||
            box.max.z < min.z ||
            box.min.z > max.z?false:true;
  }
  
  /// [point] - [Vector3] to check for inclusion.
  /// 
  /// Returns true if the specified [point] lies within or on the
  /// boundaries of this box.
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
  
  /// [plane] - [page:Plane] to check for intersection against.
  /// 
  /// Determines whether or not this box intersects [plane].
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
