import '../buffer/index.dart';
import 'dart:math' as math;
import '../matrix/matrix3.dart';
import 'vector.dart';
import 'package:flutter_gl/flutter_gl.dart';

class Vector2 extends Vector{
  
  double operator [](int i) => storage[i];
  void operator []=(int i, double v) {
    if(i == 0) x = v;
    if(i == 1) y = v;
  }

  Vector2([double? x, double? y]) {
    this.x = x ?? 0;
    this.y = y ?? 0;
  }

  Vector2.fromJson(List<double>? json) {
    if (json != null) {
      x = json[0];
      y = json[1];
    }
  }
  Vector2.zero([double x = 0, double y = 0]){
    this.x = x;
    this.y = y;
  }
  Vector2.copy(Vector v) {
    x = v.x;
    y = v.y;
  }

  double get width => storage[0];
  set width(double value) => storage[0] = value;

  double get height => storage[1];
  set height(double value) => storage[1] = value;

  @override
  Vector2 setValues(double x, double y) {
    this.x = x.toDouble();
    this.y = y.toDouble();

    return this;
  }
  @override
  Vector2 setScalar(double scalar) {
    x = scalar;
    y = scalar;

    return this;
  }

  Vector2 setX(double x) {
    this.x = x;

    return this;
  }

  Vector2 setY(double y) {
    this.y = y;

    return this;
  }

  Vector2 setComponent(int index, double value) {
    switch (index) {
      case 0:
        x = value;
        break;
      case 1:
        y = value;
        break;
      default:
        throw "index is out of range: $index";
    }

    return this;
  }
  @override
  num getComponent(int index) {
    switch (index) {
      case 0:
        return x;
      case 1:
        return y;
      default:
        throw "index is out of range: $index";
    }
  }
  @override
  Vector2 clone() {
    return Vector2(x, y);
  }
  @override
  Vector2 setFrom(Vector v) {
    x = v.x;
    y = v.y;
    return this;
  }
  @override
  Vector2 add(Vector a) {
    x += a.x;
    y += a.y;

    return this;
  }
  @override
  Vector2 addScalar(num s) {
    x += s;
    y += s;

    return this;
  }

  Vector2 add2(Vector a, Vector b) {
    x = a.x + b.x;
    y = a.y + b.y;

    return this;
  }

  @override
  Vector2 addScaled(Vector v, double s) {
    x += v.x * s;
    y += v.y * s;

    return this;
  }
  @override
  Vector2 sub(Vector a) {
    x -= a.x;
    y -= a.y;

    return this;
  }
  @override
  Vector2 subScalar(num s) {
    x -= s;
    y -= s;

    return this;
  }

  Vector2 sub2(Vector a, Vector b) {
    x = a.x - b.x;
    y = a.y - b.y;

    return this;
  }

  Vector2 multiply(Vector2 v) {
    x *= v.x;
    y *= v.y;

    return this;
  }
  @override
  Vector2 scale(num scalar) {
    x *= scalar;
    y *= scalar;

    return this;
  }

  Vector2 divide(Vector2 v) {
    x /= v.x;
    y /= v.y;

    return this;
  }
  @override
  Vector2 divideScalar(double scalar) {
    return scale(1 / scalar);
  }
  @override
  Vector2 applyMatrix3(Matrix3 m) {
    final x = this.x;
    final y = this.y;
    final e = m.storage;

    this.x = e[0] * x + e[3] * y + e[6];
    this.y = e[1] * x + e[4] * y + e[7];

    return this;
  }

  Vector2 min(Vector2 v) {
    x = math.min(x, v.x).toDouble();
    y = math.min(y, v.y).toDouble();

    return this;
  }

  Vector2 max(Vector2 v) {
    x = math.max(x, v.x);
    y = math.max(y, v.y);

    return this;
  }

  Vector2 clamp(Vector2 min, Vector2 max) {
    // assumes min < max, componentwise

    x = math.max(min.x, math.min(max.x, x));
    y = math.max(min.y, math.min(max.y, y));

    return this;
  }
  @override
  Vector2 clampScalar(double minVal, double maxVal) {
    x = math.max(minVal, math.min(maxVal, x));
    y = math.max(minVal, math.min(maxVal, y));

    return this;
  }
  @override
  Vector2 clampLength<T extends num>(T min, T max) {
    final length = this.length;

    return divideScalar(length)
        .scale(math.max(min, math.min(max, length)));
  }
  @override
  Vector2 floor() {
    x = x.floorToDouble();
    y = y.floorToDouble();

    return this;
  }
  @override
  Vector2 ceil() {
    x = x.ceilToDouble();
    y = y.ceilToDouble();

    return this;
  }
  @override
  Vector2 round() {
    x = x.roundToDouble();
    y = y.roundToDouble();

    return this;
  }
  @override
  Vector2 roundToZero() {
    x = (x < 0) ? x.ceilToDouble() : x.floorToDouble();
    y = (y < 0) ? y.ceilToDouble() : y.floorToDouble();

    return this;
  }
  @override
  Vector2 negate() {
    x = -x;
    y = -y;

    return this;
  }
  @override
  double dot(Vector v) {
    return x * v.x + y * v.y;
  }

  double cross(Vector2 v) {
    return x * v.y - y * v.x;
  }
  @override
  double get length2 => x * x + y * y;
  
  @override
  double get length => math.sqrt(x * x + y * y);
  
  @override
  double manhattanLength() {
    return (x.abs() + y.abs()).toDouble();
  }
  @override
  Vector2 normalize() {
    return divideScalar(length);
  }

  double angle() {
    // computes the angle in radians with respect to the positive x-axis
    final angle = math.atan2(-y, -x) + math.pi;
    return angle;
  }

  @override
  double distanceTo(Vector v) {
    return math.sqrt(distanceToSquared(v));
  }
  @override
  double distanceToSquared(Vector v) {
    final dx = x - v.x, dy = y - v.y;
    return dx * dx + dy * dy;
  }

  num manhattanDistanceTo(Vector2 v) {
    return ((x - v.x).abs() + (y - v.y).abs()).toDouble();
  }
  @override
  Vector2 setLength(double length) {
    return normalize().scale(length);
  }

  Vector2 lerp(Vector2 v, double alpha) {
    x += (v.x - x) * alpha;
    y += (v.y - y) * alpha;

    return this;
  }

  Vector2 lerpVectors(Vector2 v1, Vector2 v2, double alpha) {
    x = v1.x + (v2.x - v1.x) * alpha;
    y = v1.y + (v2.y - v1.y) * alpha;

    return this;
  }
  @override
  bool equals(Vector v) {
    return ((v.x == x) && (v.y == y));
  }
  @override
  List<num> toNumArray(List<num> array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];

    return array;
  }
  @override
  Vector2 copyFromArray(List<double> array, [int offset = 0]) {
    x = array[offset];
    y = array[offset + 1];

    return this;
  }
  @override
  Vector2 copyFromUnknown(array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();

    return this;
  }
  @override
  Vector2 fromNativeArray(NativeArray array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();

    return this;
  }
  @override
  List<double> copyIntoArray([List<double>? array, int offset = 0]) {
    array ??= List<double>.filled(2, 0.0);

    array[offset] = x;
    array[offset + 1] = y;
    return array;
  }
  @override
  List<double> toList() {
    return [x, y];
  }
  @override
  Vector2 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();

    return this;
  }

  Vector2 rotateAround(Vector2 center, double angle) {
    double c = math.cos(angle), s = math.sin(angle);

    double x = this.x - center.x;
    double y = this.y - center.y;

    this.x = x * c - y * s + center.x;
    this.y = x * s + y * c + center.y;

    return this;
  }
  @override
  Vector2 random() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();

    return this;
  }

  // Vector2.fromJson(Map<String, dynamic> json) {
  //   x = json['x']!;
  //   y = json['y']!;
  // }

  @override
  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }
}
