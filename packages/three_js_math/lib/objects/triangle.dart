import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';

class Triangle {
  static final _v0 = Vector3.zero();
  static final _v1 = Vector3.zero();
  static final _v3 = Vector3.zero();

  static final _vab = Vector3.zero();
  static final _vac = Vector3.zero();
  static final _vbc = Vector3.zero();
  static final _vap = Vector3.zero();
  static final _vbp = Vector3.zero();
  static final _vcp = Vector3.zero();

  String type = "Triangle";

  late Vector3 a;
  late Vector3 b;
  late Vector3 c;

  Triangle([Vector3? a, Vector3? b, Vector3? c]) {
    this.a = (a != null) ? a : Vector3.zero();
    this.b = (b != null) ? b : Vector3.zero();
    this.c = (c != null) ? c : Vector3.zero();
  }

  Triangle.init({Vector3? a, Vector3? b, Vector3? c}) {
    this.a = (a != null) ? a : Vector3.zero();
    this.b = (b != null) ? b : Vector3.zero();
    this.c = (c != null) ? c : Vector3.zero();
  }

  Vector3 operator [](Object? key) {
    return getValue(key);
  }

  Vector3 getValue(Object? key) {
    if (key == "a") {
      return a;
    } else if (key == "b") {
      return b;
    } else if (key == "c") {
      return c;
    } else {
      throw ("Triangle getValue key: $key not support .....");
    }
  }

  static Vector3 staticGetNormal(Vector3 a, Vector3 b, Vector3 c, Vector3 target) {
    target.sub2(c, b);
    _v0.sub2(a, b);
    target.cross(_v0);

    final targetLengthSq = target.length2;
    if (targetLengthSq > 0) {
      // print(" targer: ${target.toJson()} getNormal scale: ${1 / math.sqrt( targetLengthSq )} ");

      return target.scale(1 / math.sqrt(targetLengthSq));
    }

    return target.setValues(0, 0, 0);
  }

  static bool staticContainsPoint(Vector3 point, Vector3 a, Vector3 b, Vector3 c) {
    TriangleUtil.getBarycoord(point, a, b, c, _v3);
    return (_v3.x >= 0) && (_v3.y >= 0) && ((_v3.x + _v3.y) <= 1);
  }

  static staticGetUV(Vector3 point, Vector3 p1, Vector3 p2, Vector3 p3, Vector2 uv1, Vector2 uv2, Vector2 uv3, Vector target) {
    TriangleUtil.getBarycoord(point, p1, p2, p3, _v3);

    target.setValues(0.0, 0.0);
    target.addScaled(uv1, _v3.x);
    target.addScaled(uv2, _v3.y);
    target.addScaled(uv3, _v3.z);

    return target;
  }

  static bool staticIsFrontFacing(Vector3 a, Vector3 b, Vector3 c, Vector3 direction) {
    _v0.sub2(c, b);
    _v1.sub2(a, b);

    // strictly front facing
    return (_v0.cross(_v1).dot(direction) < 0) ? true : false;
  }


	///  Computes the value barycentrically interpolated for the given point on the
	///  triangle. Returns `null` if the triangle is degenerate.
	///
	///  Vector3 [point] - Position of interpolated point.
	///  Vector3 [p1] - The first corner of the triangle.
	///  Vector3 [p2] - The second corner of the triangle.
	///  Vector3 [p3] - The third corner of the triangle.
	///  Vector3 [v1] - Value to interpolate of first vertex.
	///  Vector3 [v2] - Value to interpolate of second vertex.
	///  Vector3 [v3] - Value to interpolate of third vertex.
	///  Vector3 [target] - The target vector that is used to store the method's result.
	///  return Vector3? The interpolated value.
	static Vector staticGetInterpolation(Vector3 point, Vector3 p1, Vector3 p2, Vector3 p3, Vector v1, Vector v2, Vector v3, Vector target ) {
		// if (staticGetBarycoord( point, p1, p2, p3, _v3 ) == null ) {
		// 	target.x = 0;
		// 	target.y = 0;
		// 	if ( 'z' in target ) target.z = 0;
		// 	if ( 'w' in target ) target.w = 0;
		// 	return null;
		// }

		target.setScalar( 0 );
		target.addScaled( v1, _v3.x );
		target.addScaled( v2, _v3.y );
		target.addScaled( v3, _v3.z );

		return target;
	}

  Triangle set(Vector3 a, Vector3 b, Vector3 c) {
    this.a.setFrom(a);
    this.b.setFrom(b);
    this.c.setFrom(c);

    return this;
  }

  Triangle setFromPointsAndIndices(List<Vector3> points, int i0, int i1, int i2) {
    a.setFrom(points[i0]);
    b.setFrom(points[i1]);
    c.setFrom(points[i2]);

    return this;
  }

  Triangle clone() {
    return Triangle.init()..copy(this);
  }

  Triangle copy(Triangle triangle) {
    a.setFrom(triangle.a);
    b.setFrom(triangle.b);
    c.setFrom(triangle.c);

    return this;
  }

  double getArea() {
    _v0.sub2(c, b);
    _v1.sub2(a, b);

    return _v0.cross(_v1).length * 0.5;
  }

  Vector3 getMidpoint(Vector3 target) {
    return target.add2(a, b).add(c).scale(1 / 3);
  }

  Vector3 getNormal(Vector3 target) {
    return Triangle.staticGetNormal(a, b, c, target);
  }

  Plane getPlane(Plane target) {
    return target.setFromCoplanarPoints(a, b, c);
  }

  Vector3 getBarycoord(Vector3 point, Vector3 target) {
    return TriangleUtil.getBarycoord(point, a, b, c, target);
  }

  dynamic getUV(Vector3 point, Vector2 uv1, Vector2 uv2, Vector2 uv3, Vector target) {
    return Triangle.staticGetUV(point, a, b, c, uv1, uv2, uv3, target);
  }

  bool containsPoint(Vector3 point) {
    return Triangle.staticContainsPoint(point, a, b, c);
  }

  bool isFrontFacing(Vector3 direction) {
    return Triangle.staticIsFrontFacing(a, b, c, direction);
  }

  // bool intersectsBox(Box3 box) {
  //   return box.intersectsTriangle(this);
  // }

	Vector getInterpolation(Vector3 point, Vector v1, Vector v2, Vector v3, Vector target ) {
		return Triangle.staticGetInterpolation( point, this.a, this.b, this.c, v1, v2, v3, target );
	}

  Vector3 closestPointToPoint(Vector3 p, Vector3 target) {
    final a = this.a, b = this.b, c = this.c;
    double v, w;

    // algorithm thanks to Real-Time Collision Detection by Christer Ericson,
    // published by Morgan Kaufmann Publishers, (c) 2005 Elsevier Inc.,
    // under the accompanying license; see chapter 5.1.5 for detailed explanation.
    // basically, we're distinguishing which of the voronoi regions of the triangle
    // the point lies in with the minimum amount of redundant computation.

    _vab.sub2(b, a);
    _vac.sub2(c, a);
    _vap.sub2(p, a);
    final d1 = _vab.dot(_vap);
    final d2 = _vac.dot(_vap);
    if (d1 <= 0 && d2 <= 0) {
      // vertex region of A; barycentric coords (1, 0, 0)
      return target.setFrom(a);
    }

    _vbp.sub2(p, b);
    final d3 = _vab.dot(_vbp);
    final d4 = _vac.dot(_vbp);
    if (d3 >= 0 && d4 <= d3) {
      // vertex region of B; barycentric coords (0, 1, 0)
      return target.setFrom(b);
    }

    final vc = d1 * d4 - d3 * d2;
    if (vc <= 0 && d1 >= 0 && d3 <= 0) {
      v = d1 / (d1 - d3);
      // edge region of AB; barycentric coords (1-v, v, 0)
      return target.setFrom(a).addScaled(_vab, v);
    }

    _vcp.sub2(p, c);
    final d5 = _vab.dot(_vcp);
    final d6 = _vac.dot(_vcp);
    if (d6 >= 0 && d5 <= d6) {
      // vertex region of C; barycentric coords (0, 0, 1)
      return target.setFrom(c);
    }

    final vb = d5 * d2 - d1 * d6;
    if (vb <= 0 && d2 >= 0 && d6 <= 0) {
      w = d2 / (d2 - d6);
      // edge region of AC; barycentric coords (1-w, 0, w)
      return target.setFrom(a).addScaled(_vac, w);
    }

    final va = d3 * d6 - d5 * d4;
    if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
      _vbc.sub2(c, b);
      w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
      // edge region of BC; barycentric coords (0, 1-w, w)
      return target.setFrom(b).addScaled(_vbc, w); // edge region of BC

    }

    // face region
    final denom = 1 / (va + vb + vc);
    // u = va * denom
    v = vb * denom;
    w = vc * denom;

    return target.setFrom(a).addScaled(_vab, v).addScaled(_vac, w);
  }

  bool equals(Triangle triangle) {
    return triangle.a.equals(a) && triangle.b.equals(b) && triangle.c.equals(c);
  }
}
