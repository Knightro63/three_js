import 'package:vector_math/vector_math.dart' as vmath;
import '../vector/vector3_util.dart';
import 'dart:math';
import '../bounds/bounding_sphere.dart';
import '../bounds/bounding_box.dart';

final _vector = vmath.Vector3.zero();
final _segCenter = vmath.Vector3.zero();
final _segDir = vmath.Vector3.zero();
final _diff = vmath.Vector3.zero();

final _edge1 = vmath.Vector3.zero();
final _edge2 = vmath.Vector3.zero();
final _normal = vmath.Vector3.zero();

extension RayUtil on vmath.Ray{
  vmath.Ray set(vmath.Vector3 origin, vmath.Vector3 direction) {
    this.origin.setFrom(origin);
    this.direction.setFrom(direction);
    return this;
  }

  vmath.Ray applyMatrix4(vmath.Matrix4 matrix4) {
    origin.applyMatrix4(matrix4);
    direction.transformDirection(matrix4);
    return this;
  }

  double distanceSqToSegment(vmath.Vector3 v0, vmath.Vector3 v1,
      [vmath.Vector3? optionalPointOnRay, vmath.Vector3? optionalPointOnSegment]) {
    // from http://www.geometrictools.com/GTEngine/Include/Mathematics/GteDistRaySegment.h
    // It returns the min distance between the ray and the segment
    // defined by v0 and v1
    // It can also set two optional targets :
    // - The closest point on the ray
    // - The closest point on the segment

    _segCenter..setFrom(v0)..add(v1)..scale(0.5);
    _segDir..setFrom(v1)..sub(v0)..normalize();
    _diff..setFrom(origin)..sub(_segCenter);

    final segExtent = v0.distanceTo(v1) * 0.5;
    double a01 = -direction.dot(_segDir);
    final b0 = _diff.dot(direction);
    final b1 = -_diff.dot(_segDir);
    final c = _diff.length2;
    final det = (1 - a01 * a01).abs();
    double s0, s1, sqrDist, extDet;

    if (det > 0) {
      // The ray and segment are not parallel.

      s0 = a01 * b1 - b0;
      s1 = a01 * b0 - b1;
      extDet = segExtent * det;

      if (s0 >= 0) {
        if (s1 >= -extDet) {
          if (s1 <= extDet) {
            // region 0
            // Minimum at interior points of ray and segment.

            final invDet = 1 / det;
            s0 *= invDet;
            s1 *= invDet;
            sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) +
                s1 * (a01 * s0 + s1 + 2 * b1) +
                c;
          } else {
            // region 1

            s1 = segExtent;
            s0 = max(0, -(a01 * s1 + b0));
            sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
          }
        } else {
          // region 5

          s1 = -segExtent;
          s0 = max(0, -(a01 * s1 + b0));
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      } else {
        if (s1 <= -extDet) {
          // region 4

          s0 = max(0, -(-a01 * segExtent + b0));
          s1 = (s0 > 0)
              ? -segExtent
              : min(max(-segExtent, -b1), segExtent);
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        } else if (s1 <= extDet) {
          // region 3

          s0 = 0;
          s1 = min(max(-segExtent, -b1), segExtent);
          sqrDist = s1 * (s1 + 2 * b1) + c;
        } else {
          // region 2

          s0 = max(0, -(a01 * segExtent + b0));
          s1 = (s0 > 0)
              ? segExtent
              : min(max(-segExtent, -b1), segExtent);
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      }
    } else {
      // vmath.Ray and segment are parallel.

      s1 = (a01 > 0) ? -segExtent : segExtent;
      s0 = max(0, -(a01 * s1 + b0));
      sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
    }

    if (optionalPointOnRay != null) {
      optionalPointOnRay..setFrom(direction)..scale(s0)..add(origin);
    }

    if (optionalPointOnSegment != null) {
      optionalPointOnSegment..setFrom(_segDir)..scale(s1)..add(_segCenter);
    }

    return sqrDist;
  }
  vmath.Vector3? intersectBox(BoundingBox box, vmath.Vector3 target) {
    double tmin, tmax, tymin, tymax, tzmin, tzmax;

    final invdirx = 1 / direction.x,
        invdiry = 1 / direction.y,
        invdirz = 1 / direction.z;

    final origin = this.origin;

    if (invdirx >= 0) {
      tmin = (box.min.x - origin.x) * invdirx;
      tmax = (box.max.x - origin.x) * invdirx;
    } else {
      tmin = (box.max.x - origin.x) * invdirx;
      tmax = (box.min.x - origin.x) * invdirx;
    }

    if (invdiry >= 0) {
      tymin = (box.min.y - origin.y) * invdiry;
      tymax = (box.max.y - origin.y) * invdiry;
    } else {
      tymin = (box.max.y - origin.y) * invdiry;
      tymax = (box.min.y - origin.y) * invdiry;
    }

    if ((tmin > tymax) || (tymin > tmax)) return null;

    // These lines also handle the case where tmin or tmax is NaN
    // (result of 0 * Infinity). x !== x returns true if x is NaN

    if (tymin > tmin || tmin != tmin) tmin = tymin;

    if (tymax < tmax || tmax != tmax) tmax = tymax;

    if (invdirz >= 0) {
      tzmin = (box.min.z - origin.z) * invdirz;
      tzmax = (box.max.z - origin.z) * invdirz;
    } else {
      tzmin = (box.max.z - origin.z) * invdirz;
      tzmax = (box.min.z - origin.z) * invdirz;
    }

    if ((tmin > tzmax) || (tzmin > tmax)) return null;

    if (tzmin > tmin || tmin != tmin) tmin = tzmin;

    if (tzmax < tmax || tmax != tmax) tmax = tzmax;

    //return point closest to the ray (positive side)

    if (tmax < 0) return null;

    return at2(tmin >= 0 ? tmin : tmax, target);
  }

  bool intersectsBox(BoundingBox box) {
    return intersectBox(box, _vector) != null;
  }

  vmath.Vector3? intersectSphere(BoundingSphere sphere, vmath.Vector3 target) {
    _vector.sub2((sphere.center as vmath.Vector3), origin);
    final tca = _vector.dot(direction);
    final d2 = _vector.dot(_vector) - tca * tca;
    final radius2 = sphere.radius * sphere.radius;

    if (d2 > radius2) return null;

    final thc = sqrt(radius2 - d2);

    // t0 = first intersect point - entrance on front of sphere
    final t0 = tca - thc;

    // t1 = second intersect point - exit point on back of sphere
    final t1 = tca + thc;

    // test to see if both t0 and t1 are behind the ray - if so, return null
    if (t0 < 0 && t1 < 0) return null;

    // test to see if t0 is behind the ray:
    // if it is, the ray is inside the sphere, so return the second exit point scaled by t1,
    // in order to always return an intersect point that is in front of the ray.
    if (t0 < 0) return at2(t1, target);

    // else t0 is in front of the ray, so return the first collision point scaled by t0
    return at2(t0, target);
  }
  double distanceSqToPoint(vmath.Vector3 point) {
    final directionDistance = _vector.sub2(point, origin).dot(direction);
    if (directionDistance < 0) {
      return origin.distanceToSquared(point);
    }
    _vector..setFrom(direction)..scale(directionDistance)..add(origin);
    return _vector.distanceToSquared(point);
  }
  bool intersectsSphere(BoundingSphere sphere) {
    return distanceSqToPoint((sphere.center as vmath.Vector3)) <= (sphere.radius * sphere.radius);
  }
  vmath.Vector3 closestPointToPoint(vmath.Vector3 point, vmath.Vector3 target) {
    target.sub2(point, origin);
    final directionDistance = target.dot(direction);
    if (directionDistance < 0) {
      return target..setFrom(origin);
    }
    return target..setFrom(direction)..scale(directionDistance)..add(origin);
  }
  vmath.Vector3 at2(double t, vmath.Vector3 target) {
    return target..setFrom(direction)..scale(t)..add(origin);
  }

  vmath.Vector3? intersectTriangle(vmath.Vector3 a, vmath.Vector3 b, vmath.Vector3 c, bool backfaceCulling, vmath.Vector3 target) {
    _edge1.sub2(b, a);
    _edge2.sub2(c, a);
    _normal.cross2(_edge1, _edge2);

    double ddN = direction.dot(_normal);
    int sign;

    if (ddN > 0) {
      if (backfaceCulling) return null;
      sign = 1;
    } else if (ddN < 0) {
      sign = -1;
      ddN = -ddN;
    } else {
      return null;
    }

    _diff.sub2(origin, a);
    final ddQxE2 = sign * direction.dot(_edge2.cross2(_diff, _edge2));

    // b1 < 0, no intersection
    if (ddQxE2 < 0) {
      return null;
    }

    final ddE1xQ = sign * direction.dot(_edge1.cross(_diff));

    // b2 < 0, no intersection
    if (ddE1xQ < 0) {
      return null;
    }

    // b1+b2 > 1, no intersection
    if (ddQxE2 + ddE1xQ > ddN) {
      return null;
    }

    // Line intersects triangle, check if ray does.
    final qdN = -sign * _diff.dot(_normal);

    // t < 0, no intersection
    if (qdN < 0) {
      return null;
    }

    // vmath.Ray intersects triangle.
    return at2(qdN / ddN, target);
  }
}