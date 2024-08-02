import 'package:three_js_math/three_js_math.dart';

const double epsilon = 1e-14;
final _ab = Vector3.zero();
final _ac = Vector3.zero();
final _cb = Vector3.zero();

bool isTriDegenerate(Triangle tri, [double eps = epsilon]) {
  _ab
    ..setFrom(tri.b)
    ..sub(tri.a);
  _ac
    ..setFrom(tri.c)
    ..sub(tri.a);
  _cb
    ..setFrom(tri.c)
    ..sub(tri.b);

  double angle1 = _ab.angleTo(_ac); // AB v AC
  double angle2 = _ab.angleTo(_cb); // AB v BC
  double angle3 = 3.141592653589793 - angle1 - angle2; // 180deg - angle1 - angle2

  return angle1.abs() < eps ||
      angle2.abs() < eps ||
      angle3.abs() < eps ||
      tri.a.distanceToSquared(tri.b) < eps ||
      tri.a.distanceToSquared(tri.c) < eps ||
      tri.b.distanceToSquared(tri.c) < eps;
}
