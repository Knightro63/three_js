// import 'package:vector_math/vector_math_64.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math';

var hashWidth = 1e-6;
var hashHalfWidth = hashWidth * 0.5;
var hashMultipler = pow(10, -(log(hashWidth)));
var hashAddition = hashHalfWidth * hashMultipler;

int hashNumber(double v) {
  return (v * hashMultipler + hashAddition).toInt();
}

String hashVertex2(Vector2 v) {
  return '${hashNumber(v.x)},${hashNumber(v.y)}';
}

String hashVertex3(Vector3 v) {
  return '${hashNumber(v.x)},${hashNumber(v.y)},${hashNumber(v.z)}';
}

String hashVertex4(Vector4 v) {
  return '${hashNumber(v.x)},${hashNumber(v.y)},${hashNumber(v.z)},${hashNumber(v.w)}';
}

String hashRay(Ray r) {
  return '${hashVertex3(r.origin)}-${hashVertex3(r.direction)}';
}

Ray toNormalizedRay(Vector3 v0, Vector3 v1, Ray target) {
  // get a normalized direction
  target.direction
    ..setFrom(v1)
    ..normalize();

  // project the origin onto the perpendicular plane that passes through 0,0,0
  double scalar = v0.dot(target.direction);

  //..addScaledVector(target.direction, -scalar)
  target.origin
    ..setFrom(v0)
    ..addScaled(target.direction, -scalar);

  return target;
}
