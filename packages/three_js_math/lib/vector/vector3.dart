import 'dart:typed_data';
import '../rotation/index.dart';
import '../matrix/index.dart';
import 'dart:math' as math;
import '../math/index.dart';
import '../buffer/index.dart';
import 'index.dart';
import 'package:flutter_gl/flutter_gl.dart';

final _vector3 = Vector3(0, 0, 0);

class Vector3 extends Vector{
  
  final _quaternion = Quaternion();
  double operator [](int i) => storage[i];
  void operator []=(int i, double v) {
    if(i == 0) x = v;
    if(i == 1) y = v;
    if(i == 2) z = v;
  }
  Vector3([double? x, double? y, double? z]) {
    storage = Float32List(3);
    this.x = x ?? 0;
    this.y = y ?? 0;
    this.z = z ?? 0;
  }
  Vector3.zero([double x = 0, double y = 0, double z = 0]){
    storage = Float32List(3);
    this.x = x;
    this.y = y;
    this.z = z;
  }
  Vector3.copy(Vector3 v){
    storage = Float32List(3);
    x = v.x;
    y = v.y;
    z = v.z;
  }

  Vector3.fromJson(List<double>? json) {
    storage = Float32List(3);
    if (json != null) {
      x = json[0];
      y = json[1];
      z = json[2];
    }
  }

  double get z => storage[2];
  set z(double value) => storage[2] = value;

  @override
  Vector3 setValues(double x, double y, [double? z]) {
    z ??= this.z; // sprite.scale.set(x,y)

    this.x = x.toDouble();
    this.y = y.toDouble();
    this.z = z.toDouble();

    return this;
  }

  void setP(String p, double v) {
    if (p == "x") {
      x = v;
    } else if (p == "y") {
      y = v;
    } else if (p == "z") {
      z = v;
    } else {
      throw (" Vector3.setP $p is not support ");
    }
  }
  @override
  Vector3 setScalar(scalar) {
    x = scalar;
    y = scalar;
    z = scalar;
    return this;
  }

  Vector3 setX(double x) {
    this.x = x;

    return this;
  }

  Vector3 setY(double y) {
    this.y = y;

    return this;
  }

  Vector3 setZ(double z) {
    this.z = z;

    return this;
  }

  Vector3 setComponent(int index, double value) {
    switch (index) {
      case 0:
        x = value;
        break;
      case 1:
        y = value;
        break;
      case 2:
        z = value;
        break;
      default:
        throw ('index is out of range: $index');
    }

    return this;
  }
  @override
  double getComponent(int index) {
    switch (index) {
      case 0:
        return x;
      case 1:
        return y;
      case 2:
        return z;
      default:
        throw ('index is out of range: $index');
    }
  }
  @override
  Vector3 clone() {
    return Vector3(x, y, z);
  }
  @override
  Vector3 setFrom(Vector v) {
    x = v.x;
    y = v.y;
    if (v is Vector3){ 
      z = v.z;
    }
    else if (v is Vector4){ 
      z = v.z;
    }

    return this;
  }
  @override
  Vector3 add(Vector a, [Vector? b]) {
    if (b != null) {
      print('THREE.Vector2: .add() now only accepts one argument. Use .add2( a, b ) instead.');
      return add2(a, b);
    }
    x += a.x;
    y += a.y;
    if(a is Vector4){
      z += a.z;
    }
    else if(a is Vector3){
      z += a.z;
    }

    return this;
  }
  Vector3 add2(Vector a, Vector b) {
    x = a.x + b.x;
    y = a.y + b.y;
    if((a is Vector3 && b is Vector3)){
      z = a.z + b.z;
    }
    else if((a is Vector4 && b is Vector4)){
      z = a.z + b.z;
    }
    else if((a is Vector3 && b is Vector4)){
      z = a.z + b.z;
    }
    else if((a is Vector4 && b is Vector3)){
      z = a.z + b.z;
    }

    return this;
  }
  @override
  Vector3 addScalar(num s) {
    x += s;
    y += s;
    z += s;

    return this;
  }
  @override
  Vector3 addScaled(Vector v, num s) {
    x += v.x * s;
    y += v.y * s;
    if(v is Vector3){
      z += v.z * s;
    }
    else if(v is Vector4){
      z += v.z * s;
    }

    return this;
  }

  @override
  Vector3 sub(Vector a, [Vector? b]) {
    if (b != null) {
      print('THREE.Vector3: .sub() now only accepts one argument. Use .sub2( a, b ) instead.');
      return sub2(a, b);
    }

    x -= a.x;
    y -= a.y;

    if (a is Vector3){ 
      z -= a.z;
    }
    else if(a is Vector4){
      z -= a.z;
    }

    return this;
  }
  @override
  Vector3 subScalar(num s) {
    x -= s;
    y -= s;
    z -= s;

    return this;
  }

  Vector3 sub2(Vector a, Vector b) {
    x = a.x - b.x;
    y = a.y - b.y;
    if((a is Vector3 && b is Vector3)){
      z = a.z - b.z;
    }
    else if((a is Vector4 && b is Vector4)){
      z = a.z - b.z;
    }
    else if((a is Vector3 && b is Vector4)){
      z = a.z - b.z;
    }
    else if((a is Vector4 && b is Vector3)){
      z = a.z - b.z;
    }
    return this;
  }

  Vector3 multiply(Vector3 v) {
    x *= v.x;
    y *= v.y;
    z *= v.z;

    return this;
  }
  @override
  Vector3 scale(num scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;

    return this;
  }

  Vector3 multiplyVectors(Vector3 a, Vector3 b) {
    x = a.x * b.x;
    y = a.y * b.y;
    z = a.z * b.z;

    return this;
  }

  Vector3 applyEuler(Euler euler) {
    return applyQuaternion(_quaternion.setFromEuler(euler, false));
  }

  Vector3 applyAxisAngle(axis, angle) {
    return applyQuaternion(_quaternion.setFromAxisAngle(axis, angle));
  }
  @override
  Vector3 applyMatrix3(Matrix3 m) {
    final x = this.x, y = this.y, z = this.z;
    final e = m.storage;

    this.x = e[0] * x + e[3] * y + e[6] * z;
    this.y = e[1] * x + e[4] * y + e[7] * z;
    this.z = e[2] * x + e[5] * y + e[8] * z;

    return this;
  }

  Vector3 applyNormalMatrix(Matrix3 m) {
    return applyMatrix3(m).normalize();
  }

  Vector3 applyMatrix4(Matrix4 m) {
    final e = m.storage;

    final x = this.x;
    final y = this.y;
    final z = this.z;

    final w = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);

    this.x = (e[0] * x + e[4] * y + e[8] * z + e[12]) * w;
    this.y = (e[1] * x + e[5] * y + e[9] * z + e[13]) * w;
    this.z = (e[2] * x + e[6] * y + e[10] * z + e[14]) * w;

    return this;
  }

  Vector3 applyQuaternion(Quaternion q) {
    final qx = q.x;
    final qy = q.y;
    final qz = q.z;
    final qw = q.w;

    // calculate quat * vector

    final ix = qw * x + qy * z - qz * y;
    final iy = qw * y + qz * x - qx * z;
    final iz = qw * z + qx * y - qy * x;
    final iw = -qx * x - qy * y - qz * z;

    // calculate result * inverse quat

    x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
    y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
    z = iz * qw + iw * -qz + ix * -qy - iy * -qx;

    return this;
  }

  Vector3 project(camera) {
    return applyMatrix4(camera.matrixWorldInverse)
        .applyMatrix4(camera.projectionMatrix);
  }

  Vector3 unproject(camera) {
    return applyMatrix4(camera.projectionMatrixInverse)
        .applyMatrix4(camera.matrixWorld);
  }

  Vector3 transformDirection(Matrix4 m) {
    // input: THREE.Matrix4 affine matrix
    // vector interpreted as a direction

    final x = this.x, y = this.y, z = this.z;
    final e = m.storage;

    this.x = e[0] * x + e[4] * y + e[8] * z;
    this.y = e[1] * x + e[5] * y + e[9] * z;
    this.z = e[2] * x + e[6] * y + e[10] * z;

    return normalize();
  }

  Vector3 divide(Vector3 v) {
    x /= v.x;
    y /= v.y;
    z /= v.z;

    return this;
  }
  @override
  Vector3 divideScalar(num scalar) {
    return scale(1 / scalar);
  }

  Vector3 min(Vector3 v) {
    x = math.min(x, v.x);
    y = math.min(y, v.y);
    z = math.min(z, v.z);

    return this;
  }

  Vector3 max(Vector3 v) {
    x = math.max(x, v.x);
    y = math.max(y, v.y);
    z = math.max(z, v.z);

    return this;
  }

  Vector3 clamp(Vector3 min, Vector3 max) {
    // assumes min < max, componentwise

    x = math.max(min.x, math.min(max.x, x));
    y = math.max(min.y, math.min(max.y, y));
    z = math.max(min.z, math.min(max.z, z));

    return this;
  }
  @override
  Vector3 clampScalar(minVal, maxVal) {
    x = math.max(minVal, math.min(maxVal, x));
    y = math.max(minVal, math.min(maxVal, y));
    z = math.max(minVal, math.min(maxVal, z));

    return this;
  }
  @override
  Vector3 clampLength<T extends num>(T min, T max) {
    final length = this.length;

    return divideScalar(length)
        .scale(math.max(min, math.min(max, length)));
  }
  @override
  Vector3 floor() {
    x = x.floorToDouble();
    y = y.floorToDouble();
    z = z.floorToDouble();

    return this;
  }
  @override
  Vector3 ceil() {
    x = x.ceilToDouble();
    y = y.ceilToDouble();
    z = z.ceilToDouble();

    return this;
  }
  @override
  Vector3 round() {
    x = x.roundToDouble();
    y = y.roundToDouble();
    z = z.roundToDouble();

    return this;
  }
  @override
  Vector3 roundToZero() {
    x = (x < 0) ? x.ceilToDouble() : x.floorToDouble();
    y = (y < 0) ? y.ceilToDouble() : y.floorToDouble();
    z = (z < 0) ? z.ceilToDouble() : z.floorToDouble();

    return this;
  }
  @override
  Vector3 negate() {
    x = -x;
    y = -y;
    z = -z;

    return this;
  }
  @override
  double dot(Vector v) {
    double temp = x * v.x + y * v.y;
    if(v is Vector3){
      temp += z * v.z;
    }
    if(v is Vector4){
      temp += z * v.z;
    }
    return temp;
  }

  @override
  double get length2 => x * x + y * y + z * z;
  
  @override
  double get length => math.sqrt(x * x + y * y + z * z);
  
  @override
  double manhattanLength() {
    return (x.abs() + y.abs() + z.abs()).toDouble();
  }
  @override
  Vector3 normalize() {
    return divideScalar(length);
  }
  @override
  Vector3 setLength(double length) {
    return normalize().scale(length);
  }

  Vector3 lerp(Vector3 v, num alpha) {
    x += (v.x - x) * alpha;
    y += (v.y - y) * alpha;
    z += (v.z - z) * alpha;

    return this;
  }

  Vector3 lerpVectors(Vector3 v1, Vector3 v2, num alpha) {
    x = v1.x + (v2.x - v1.x) * alpha;
    y = v1.y + (v2.y - v1.y) * alpha;
    z = v1.z + (v2.z - v1.z) * alpha;

    return this;
  }

  Vector3 cross(Vector3 v, {Vector3? w}) {
    if (w != null) {
      print('THREE.Vector3: .cross() now only accepts one argument. Use .cross2( a, b ) instead.');
      return cross2(v, w);
    }

    return cross2(this, v);
  }

  Vector3 cross2(Vector3 a, Vector3 b) {
    final ax = a.x, ay = a.y, az = a.z;
    final bx = b.x, by = b.y, bz = b.z;

    x = ay * bz - az * by;
    y = az * bx - ax * bz;
    z = ax * by - ay * bx;

    return this;
  }

  Vector3 projectOnVector(Vector3 v) {
    final denominator = v.length2;

    if (denominator == 0) return setValues(0, 0, 0);

    final scalar = v.dot(this) / denominator;

    return setFrom(v).scale(scalar);
  }

  Vector3 projectOnPlane(Vector3 planeNormal) {
    _vector3.setFrom(this).projectOnVector(planeNormal);

    return sub(_vector3);
  }

  Vector3 reflect(Vector3 normal) {
    // reflect incident vector off plane orthogonal to normal
    // normal is assumed to have unit length

    return sub(_vector3.setFrom(normal).scale(2 * dot(normal)));
  }

  double angleTo(v) {
    final denominator = math.sqrt(length2 * v.length2);

    if (denominator == 0) return math.pi / 2;

    final theta = dot(v) / denominator;

    // clamp, to handle doubleerical problems

    return math.acos(MathUtils.clamp(theta, -1, 1));
  }

  @override
  double distanceTo(Vector v) {
    return math.sqrt(distanceToSquared(v));
  }
  @override
  double distanceToSquared(Vector v) {
    final dx = x - v.x; 
    final dy = y - v.y;
    double dz = z;
    if(v is Vector3){
      dz-= v.z;
    }
    else if(v is Vector4){
      dz-= v.z;
    }
    final distance = dx * dx + dy * dy + dz * dz;
    return distance;
  }

  manhattanDistanceTo(Vector3 v) {
    return (x - v.x).abs() + (y - v.y).abs() + (z - v.z).abs();
  }

  Vector3 setFromSpherical(s) {
    return setFromSphericalCoords(s.radius, s.phi, s.theta);
  }

  Vector3 setFromSphericalCoords(num radius, num phi, num theta) {
    final sinPhiRadius = math.sin(phi) * radius;

    x = sinPhiRadius * math.sin(theta);
    y = math.cos(phi) * radius;
    z = sinPhiRadius * math.cos(theta);

    return this;
  }

  Vector3 setFromCylindrical(c) {
    return setFromCylindricalCoords(c.radius, c.theta, c.y);
  }

  Vector3 setFromCylindricalCoords(double radius, double theta, double y) {
    x = radius * math.sin(theta);
    this.y = y;
    z = radius * math.cos(theta);

    return this;
  }

  Vector3 setFromMatrixPosition(m) {
    final e = m.storage;

    x = e[12];
    y = e[13];
    z = e[14];

    return this;
  }

  Vector3 setFromMatrixScale(m) {
    final sx = setFromMatrixColumn(m, 0).length;
    final sy = setFromMatrixColumn(m, 1).length;
    final sz = setFromMatrixColumn(m, 2).length;

    x = sx;
    y = sy;
    z = sz;

    return this;
  }

  Vector3 setFromMatrixColumn(Matrix4 m, int index) {
    return copyFromArray(m.storage.toList(), index * 4);
  }

  Vector3 setFromMatrix3Column(Matrix3 m, int index) {
    return copyFromArray(m.storage.toList(), index * 3);
  }

  Vector3 setFromEuler(Euler e) {
    x = e.x;
    y = e.y;
    z = e.z;

    return this;
  }
  @override
  bool equals(v) {
    if(v is Vector3){
      return (v.x == x) && (v.y == y) && (v.z == z);
    }
    else if(v is Vector4){
      return (v.x == x) && (v.y == y) && (v.z == z);
    }

    return (v.x == x) && (v.y == y);
  }
  @override
  Vector3 fromNativeArray(NativeArray array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();
    z = array[offset + 2].toDouble();

    return this;
  }
  @override
  List<num> toNumArray(List<num> array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];

    return array;
  }
  @override
  Vector3 copyFromArray(List<double> array, [int offset = 0]) {
    x = array[offset];
    y = array[offset + 1];
    z = array[offset + 2];

    return this;
  }
  @override
  Vector3 copyFromUnknown(array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();
    z = array[offset + 2].toDouble();

    return this;
  }
  @override
  List<double> copyIntoArray([List<double>? array, int offset = 0]) {
    if (array == null) {
      array = List<double>.filled(offset + 3, 0);
    } else {
      while (array.length < offset + 3) {
        array.add(0.0);
      }
    }

    array[offset] = x;
    array[offset + 1] = y;
    array[offset + 2] = z;

    return array;
  }
  @override
  Vector3 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();
    z = attribute.getZ(index)!.toDouble();

    return this;
  }
  @override
  Vector3 random() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    z = math.Random().nextDouble();

    return this;
  }

  Vector3 randomDirection() {
    // Derived from https://mathworld.wolfram.com/SpherePointPicking.html

    final u = (math.Random().nextDouble() - 0.5) * 2;
    final t = math.Random().nextDouble() * math.pi * 2;
    final f = math.sqrt(1 - u * u);

    x = f * math.cos(t);
    y = f * math.sin(t);
    z = u;

    return this;
  }
  @override
  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }
  @override
  List<double> toList() {
    return [x, y];
  }
}
