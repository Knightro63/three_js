import '../bounds/index.dart';
import 'dart:math' as math;
import '../vector/index.dart';
import '../matrix/index.dart';
import 'index.dart';

class Ray {
  final _vector = Vector3.zero();
  final _segCenter = Vector3.zero();
  final _segDir = Vector3.zero();
  final _diff = Vector3.zero();

  final _edge1 = Vector3.zero();
  final _edge2 = Vector3.zero();
  final _normal = Vector3.zero();

  late Vector3 origin;
  late Vector3 direction;

  Ray() {
    origin = Vector3.zero();
    direction = Vector3(0, 0, -1);
  }
  Ray.originDirection(this.origin, this.direction);

  Ray set(Vector3 origin, Vector3 direction) {
    this.origin.setFrom(origin);
    this.direction.setFrom(direction);

    return this;
  }

  Ray clone() {
    return Ray()..copyFrom(this);
  }

  Ray copyFrom(Ray ray) {
    origin.setFrom(ray.origin);
    direction.setFrom(ray.direction);

    return this;
  }

  // for three_dart_jsm/lib/three_dart_jsm/lines/LineSegments2.dart
  // raycast(Raycaster raycaster, intersects) {}
  // have a call ray.at(1, ssOrigin);
  // ssOrigin is Vector4
  // for three.js allow Vector4 copy from Vector3 ...
  // so the args target can be Vector4 | Vector3
  T at<T extends Vector>(double t, T target) {
    return target.setFrom(direction).scale(t).add(origin) as T;
  }

  Ray lookAt(Vector3 v) {
    direction.setFrom(v).sub(origin).normalize();
    return this;
  }

  Ray recast(double t) {
    origin.setFrom(at(t, _vector));
    return this;
  }

  Vector3 closestPointToPoint(Vector3 point, Vector3 target) {
    target.sub2(point, origin);
    final directionDistance = target.dot(direction);
    if (directionDistance < 0) {
      return target.setFrom(origin);
    }
    return target.setFrom(direction).scale(directionDistance).add(origin);
  }

  double distanceToPoint(Vector3 point) {
    return math.sqrt(distanceSqToPoint(point));
  }

  num distanceSqToPoint(Vector3 point) {
    final directionDistance = _vector.sub2(point, origin).dot(direction);
    if (directionDistance < 0) {
      return origin.distanceToSquared(point);
    }
    _vector.setFrom(direction).scale(directionDistance).add(origin);
    return _vector.distanceToSquared(point);
  }

  num distanceSqToSegment(Vector3 v0, Vector3 v1,
      [Vector3? optionalPointOnRay, Vector3? optionalPointOnSegment]) {
    // from http://www.geometrictools.com/GTEngine/Include/Mathematics/GteDistRaySegment.h
    // It returns the min distance between the ray and the segment
    // defined by v0 and v1
    // It can also set two optional targets :
    // - The closest point on the ray
    // - The closest point on the segment

    _segCenter.setFrom(v0).add(v1).scale(0.5);
    _segDir.setFrom(v1).sub(v0).normalize();
    _diff.setFrom(origin).sub(_segCenter);

    final segExtent = v0.distanceTo(v1) * 0.5;
    num a01 = -direction.dot(_segDir);
    final b0 = _diff.dot(direction);
    final b1 = -_diff.dot(_segDir);
    final c = _diff.length2;
    final det = (1 - a01 * a01).abs();
    num s0, s1, sqrDist, extDet;

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
            s0 = math.max(0, -(a01 * s1 + b0));
            sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
          }
        } else {
          // region 5

          s1 = -segExtent;
          s0 = math.max(0, -(a01 * s1 + b0));
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      } else {
        if (s1 <= -extDet) {
          // region 4

          s0 = math.max(0, -(-a01 * segExtent + b0));
          s1 = (s0 > 0)
              ? -segExtent
              : math.min(math.max(-segExtent, -b1), segExtent);
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        } else if (s1 <= extDet) {
          // region 3

          s0 = 0;
          s1 = math.min(math.max(-segExtent, -b1), segExtent);
          sqrDist = s1 * (s1 + 2 * b1) + c;
        } else {
          // region 2

          s0 = math.max(0, -(a01 * segExtent + b0));
          s1 = (s0 > 0)
              ? segExtent
              : math.min(math.max(-segExtent, -b1), segExtent);
          sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      }
    } else {
      // Ray and segment are parallel.

      s1 = (a01 > 0) ? -segExtent : segExtent;
      s0 = math.max(0, -(a01 * s1 + b0));
      sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
    }

    if (optionalPointOnRay != null) {
      optionalPointOnRay.setFrom(direction).scale(s0).add(origin);
    }

    if (optionalPointOnSegment != null) {
      optionalPointOnSegment.setFrom(_segDir).scale(s1).add(_segCenter);
    }

    return sqrDist;
  }

  Vector3? intersectSphere(BoundingSphere sphere, Vector3 target) {
    _vector.sub2(sphere.center, origin);
    final tca = _vector.dot(direction);
    final d2 = _vector.dot(_vector) - tca * tca;
    final radius2 = sphere.radius * sphere.radius;

    if (d2 > radius2) return null;

    final thc = math.sqrt(radius2 - d2);

    // t0 = first intersect point - entrance on front of sphere
    final t0 = tca - thc;

    // t1 = second intersect point - exit point on back of sphere
    final t1 = tca + thc;

    // test to see if both t0 and t1 are behind the ray - if so, return null
    if (t0 < 0 && t1 < 0) return null;

    // test to see if t0 is behind the ray:
    // if it is, the ray is inside the sphere, so return the second exit point scaled by t1,
    // in order to always return an intersect point that is in front of the ray.
    if (t0 < 0) return at(t1, target);

    // else t0 is in front of the ray, so return the first collision point scaled by t0
    return at(t0, target);
  }

  bool intersectsSphere(BoundingSphere sphere) {
    return distanceSqToPoint(sphere.center) <= (sphere.radius * sphere.radius);
  }

  double? distanceToPlane(Plane plane) {
    final denominator = plane.normal.dot(direction);

    if (denominator == 0) {
      // line is coplanar, return origin
      if (plane.distanceToPoint(origin) == 0) {
        return 0;
      }

      // Null is preferable to undefined since undefined means.... it is undefined

      return null;
    }

    final t = -(origin.dot(plane.normal) + plane.constant) / denominator;

    // Return if the ray never intersects the plane

    return t >= 0 ? t : null;
  }

  T? intersectPlane<T extends Vector>(Plane plane, T target) {
    double? t = distanceToPlane(plane);

    return t == null ? null : at(t, target);
  }

  bool intersectsPlane(Plane plane) {
    // check if the ray lies on the plane first

    final distToPoint = plane.distanceToPoint(origin);

    if (distToPoint == 0) {
      return true;
    }

    final denominator = plane.normal.dot(direction);

    if (denominator * distToPoint < 0) {
      return true;
    }

    // ray origin is behind the plane (and is pointing behind it)

    return false;
  }

  Vector3? intersectBox(BoundingBox box, Vector3 target) {
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

    return at(tmin >= 0 ? tmin : tmax, target);
  }

  bool intersectsBox(BoundingBox box) {
    return intersectBox(box, _vector) != null;
  }

  Vector3? intersectTriangle(Vector3 a, Vector3 b, Vector3 c, bool backfaceCulling, Vector3 target) {
    // Compute the offset origin, edges, and normal.

    // from http://www.geometrictools.com/GTEngine/Include/Mathematics/GteIntrRay3Triangle3.h

    _edge1.sub2(b, a);
    _edge2.sub2(c, a);
    _normal.cross2(_edge1, _edge2);

    // Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
    // E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
    //   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
    //   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
    //   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
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

    // Ray intersects triangle.
    return at(qdN / ddN, target);
  }

  Ray applyMatrix4(Matrix4 matrix4) {
    origin.applyMatrix4(matrix4);
    direction.transformDirection(matrix4);

    return this;
  }

  bool equals(Ray ray) {
    return ray.origin.equals(origin) && ray.direction.equals(direction);
  }
}
