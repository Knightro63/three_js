import './index.dart';
import '../vector/index.dart';
import 'dart:math' as math;

final _v0 = Vector3.zero();
final _v1 = Vector3.zero();
final _v2 = Vector3.zero();
final _v3 = Vector3.zero();

extension TriangleUtil on Triangle{
  static Vector3 getNormal(Vector3 a, Vector3 b, Vector3 c, Vector3 target) {
    target.sub2(c, b);
    _v0.sub2(a, b);
    target.cross(_v0);

    final targetLengthSq = target.length2;
    if (targetLengthSq > 0) {
      // print(" targer: ${target.toJson()} getNormal scale: ${1 / math.sqrt( targetLengthSq )} ");
      target.scale(1 / math.sqrt(targetLengthSq));
      return target;
    }
    target.setValues(0, 0, 0);
    return target;
  }
  static Vector3 getBarycoord(Vector3 point, Vector3 a, Vector3 b, Vector3 c, Vector3 target) {
    _v0.sub2(c, a);
    _v1.sub2(b, a);
    _v2.sub2(point, a);

    final dot00 = _v0.dot(_v0);
    final dot01 = _v0.dot(_v1);
    final dot02 = _v0.dot(_v2);
    final dot11 = _v1.dot(_v1);
    final dot12 = _v1.dot(_v2);

    final denom = (dot00 * dot11 - dot01 * dot01);

    // collinear or singular triangle
    if (denom == 0) {
      // arbitrary location outside of triangle?
      // not sure if this is the best idea, maybe should be returning null
      target.setValues(-2, -1, -1);
      return target;
    }

    final invDenom = 1 / denom;
    final u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    final v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    // barycentric coordinates must always sum to 1
    target.setValues(1 - u - v, v, u);
    return target;
  }
  static Vector2 getUV(Vector3 point, Vector3 p1, Vector3 p2, Vector3 p3, Vector2 uv1, Vector2 uv2, Vector2 uv3, Vector2 target) {
    getBarycoord(point, p1, p2, p3, _v3);

    target.setValues(0.0, 0.0);
    target.addScaled(uv1, _v3.x);
    target.addScaled(uv2, _v3.y);
    target.addScaled(uv3, _v3.z);

    return target;
  }
}