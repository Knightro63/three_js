import 'dart:typed_data';
import '../buffer/index.dart';
import 'dart:math' as math;
import '../matrix/index.dart';
import '../rotation/index.dart';
import 'index.dart';
import 'package:flutter_angle/flutter_angle.dart';

class Vector4 extends Vector{
  String type = "Vector4";
  
  double operator [](int i) => storage[i];
  void operator []=(int i, double v) {
    if(i == 0) x = v;
    if(i == 1) y = v;
    if(i == 2) z = v;
    if(i == 3) w = v;
  }

  Vector4([double? x, double? y, double? z, double? w]) {
    storage = Float32List(4);
    this.x = x ?? 0;
    this.y = y ?? 0;
    this.z = z ?? 0;
    this.w = w ?? 0;
  }
  Vector4.zero([double x = 0, double y = 0, double z = 0, double w = 1]){
    storage = Float32List(4);
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }
  Vector4.identity({double x = 0, double y = 0, double z = 0, double w = 1}){
    storage = Float32List(4);
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }

  Vector4.fromJson([Map<String,num>? json]) {
    storage = Float32List(4);
    if (json != null) {
      List<num> data = json.values.toList();
      x = data[0].toDouble();
      y = data[1].toDouble();
      z = data[2].toDouble();
      w = data[3].toDouble();
    }
  }
  double get z => storage[2];
  set z(double value) => storage[2] = value;

  double get w => storage[3];
  set w(double value) => storage[3] = value;

  @override
  List<double> toList() {
    return [x, y, z, w];
  }

  get width => z;
  set width(value) => z = value;

  get height => w;
  set height(value) => w = value;

  @override
  Vector4 setValues(double x, double y, [double? z, double? w]) {
    z ??= this.z;
    w ??= this.w;

    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;

    return this;
  }

  @override
  Vector4 setScalar(double scalar) {
    x = scalar;
    y = scalar;
    z = scalar;
    w = scalar;

    return this;
  }

  Vector4 setX(double x) {
    this.x = x;

    return this;
  }

  Vector4 setY(double y) {
    this.y = y;

    return this;
  }

  Vector4 setZ(double z) {
    this.z = z;

    return this;
  }

  Vector4 setW(double w) {
    this.w = w;

    return this;
  }

  Vector4 setComponent(int index, double value) {
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
      case 3:
        w = value;
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
      case 3:
        return w;
      default:
        throw ('index is out of range: $index');
    }
  }

  @override
  Vector4 clone() {
    return Vector4(x, y, z, w);
  }
  @override
  Vector4 setFrom(Vector v) {
    x = v.x;
    y = v.y;
    if(v is Vector4){
      z = v.z;
      w = v.w;
    }
    else if (v is Vector3){
      z = v.z;
    }

    return this;
  }
  @override
  Vector4 add(Vector a) {
    x += a.x;
    y += a.y;
    if(a is Vector4){
      z += a.z;
      w += a.w;
    }
    else if(a is Vector3){
      z += a.z;
    }

    return this;
  }
  @override
  Vector4 addScalar(num s) {
    x += s;
    y += s;
    z += s;
    w += s;

    return this;
  }

  Vector4 add2(Vector a, Vector b) {
    x = a.x + b.x;
    y = a.y + b.y;
    if(a is Vector4 && b is Vector4){
      z = a.z + b.z;
      w = a.w + b.w;
    }
    else if(a is Vector3 && b is Vector3){
      z = a.z + b.z;
    }
    else if(a is Vector4 && b is Vector3){
      z = a.z + b.z;
    }
    else if(a is Vector3 && b is Vector4){
      z = a.z + b.z;
    }
    return this;
  }
  @override
  Vector4 addScaled(Vector v, double s) {
    x += v.x * s;
    y += v.y * s;
    if(v is Vector3){
      z += v.z * s;
    }
    else if(v is Vector4){
      z += v.z * s;
      w += v.w * s;
    }

    return this;
  }
  @override
  Vector4 sub(Vector a) {
    x -= a.x;
    y -= a.y;
    if(a is Vector4){
      z -= a.z;
      w -= a.w;
    }
    else if(a is Vector3){
      z -= a.z;
    }

    return this;
  }
  @override
  Vector4 subScalar(num s) {
    x -= s;
    y -= s;
    z -= s;
    w -= s;

    return this;
  }

  Vector4 sub2(Vector a, Vector b) {
    x = a.x - b.x;
    y = a.y - b.y;
    if(a is Vector4 && b is Vector4){
      z = a.z - b.z;
      w = a.w - b.w;
    }
    else if(a is Vector3 && b is Vector3){
      z = a.z - b.z;
    }
    else if(a is Vector4 && b is Vector3){
      z = a.z - b.z;
    }
    else if(a is Vector3 && b is Vector4){
      z = a.z - b.z;
    }

    return this;
  }

  // multiply( v, w ) {

  Vector4 multiply(Vector4 v) {
    x *= v.x;
    y *= v.y;
    z *= v.z;
    w *= v.w;

    return this;
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
  @override
  Vector4 scale(num scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
    w *= scalar;

    return this;
  }

  Vector4 applyMatrix4(Matrix4 m) {
    final x = this.x, y = this.y, z = this.z, w = this.w;
    final e = m.storage;

    this.x = e[0] * x + e[4] * y + e[8] * z + e[12] * w;
    this.y = e[1] * x + e[5] * y + e[9] * z + e[13] * w;
    this.z = e[2] * x + e[6] * y + e[10] * z + e[14] * w;
    this.w = e[3] * x + e[7] * y + e[11] * z + e[15] * w;

    return this;
  }
  @override
  Vector4 divideScalar(double scalar) {
    return scale(1 / scalar);
  }

  Vector4 setAxisAngleFromQuaternion(Quaternion q) {
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle/index.htm

    // q is assumed to be normalized

    w = 2 * math.acos(q.w);

    final s = math.sqrt(1 - q.w * q.w);

    if (s < 0.0001) {
      x = 1;
      y = 0;
      z = 0;
    } else {
      x = q.x / s;
      y = q.y / s;
      z = q.z / s;
    }

    return this;
  }
  @override
  Vector4 applyMatrix3(Matrix3 m) {
    final x = this.x, y = this.y, z = this.z;
    final e = m.storage;

    this.x = e[0] * x + e[3] * y + e[6] * z;
    this.y = e[1] * x + e[4] * y + e[7] * z;
    this.z = e[2] * x + e[5] * y + e[8] * z;

    return this;
  }
  Vector4 setAxisAngleFromRotationMatrix(Matrix3 m) {
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm

    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

    double angle, x, y, z; // variables for result
    double epsilon = 0.01, // margin to allow for rounding errors
        epsilon2 = 0.1; // margin to distinguish between 0 and 180 degrees

    final te = m.storage;
    double m11 = te[0];
    double m12 = te[4];
    double m13 = te[8];
    double m21 = te[1];
    double m22 = te[5];
    double m23 = te[9];
    double m31 = te[2];
    double m32 = te[6];
    double m33 = te[10];

    if (((m12 - m21).abs() < epsilon) &&
        ((m13 - m31).abs() < epsilon) &&
        ((m23 - m32).abs() < epsilon)) {
      // singularity found
      // first check for identity matrix which must have +1 for all terms
      // in leading diagonal and zero in other terms

      if (((m12 + m21).abs() < epsilon2) &&
          ((m13 + m31).abs() < epsilon2) &&
          ((m23 + m32).abs() < epsilon2) &&
          ((m11 + m22 + m33 - 3).abs() < epsilon2)) {
        // this singularity is identity matrix so angle = 0

        setValues(1, 0, 0, 0);

        return this; // zero angle, arbitrary axis

      }

      // otherwise this singularity is angle = 180

      angle = math.pi;

      final xx = (m11 + 1) / 2;
      final yy = (m22 + 1) / 2;
      final zz = (m33 + 1) / 2;
      final xy = (m12 + m21) / 4;
      final xz = (m13 + m31) / 4;
      final yz = (m23 + m32) / 4;

      if ((xx > yy) && (xx > zz)) {
        // m11 is the largest diagonal term

        if (xx < epsilon) {
          x = 0;
          y = 0.707106781;
          z = 0.707106781;
        } else {
          x = math.sqrt(xx);
          y = xy / x;
          z = xz / x;
        }
      } else if (yy > zz) {
        // m22 is the largest diagonal term

        if (yy < epsilon) {
          x = 0.707106781;
          y = 0;
          z = 0.707106781;
        } else {
          y = math.sqrt(yy);
          x = xy / y;
          z = yz / y;
        }
      } else {
        // m33 is the largest diagonal term so base result on this

        if (zz < epsilon) {
          x = 0.707106781;
          y = 0.707106781;
          z = 0;
        } else {
          z = math.sqrt(zz);
          x = xz / z;
          y = yz / z;
        }
      }

      setValues(x, y, z, angle);

      return this; // return 180 deg rotation

    }

    // as we have reached here there are no singularities so we can handle normally

    double s = math.sqrt((m32 - m23) * (m32 - m23) +
        (m13 - m31) * (m13 - m31) +
        (m21 - m12) * (m21 - m12)); // used to normalize

    if (s.abs() < 0.001) s = 1;

    // prevent divide by zero, should not happen if matrix is orthogonal and should be
    // caught by singularity test above, but I've left it in just in case

    this.x = (m32 - m23) / s;
    this.y = (m13 - m31) / s;
    this.z = (m21 - m12) / s;
    w = math.acos((m11 + m22 + m33 - 1) / 2);

    return this;
  }

	Vector4 setFromMatrixPosition(Matrix4 m ) {
		final e = m.storage;

		this.x = e[ 12 ];
		this.y = e[ 13 ];
		this.z = e[ 14 ];
		this.w = e[ 15 ];

		return this;
	}

  Vector4 min(Vector4 v) {
    x = math.min(x, v.x);
    y = math.min(y, v.y);
    z = math.min(z, v.z);
    w = math.min(w, v.w);

    return this;
  }

  Vector4 max(Vector4 v) {
    x = math.max(x, v.x);
    y = math.max(y, v.y);
    z = math.max(z, v.z);
    w = math.max(w, v.w);

    return this;
  }

  Vector4 clamp(Vector4 min, Vector4 max) {
    // assumes min < max, componentwise

    x = math.max(min.x, math.min(max.x, x));
    y = math.max(min.y, math.min(max.y, y));
    z = math.max(min.z, math.min(max.z, z));
    w = math.max(min.w, math.min(max.w, w));

    return this;
  }
  @override
  Vector4 clampScalar(double minVal, double maxVal) {
    x = math.max(minVal, math.min(maxVal, x));
    y = math.max(minVal, math.min(maxVal, y));
    z = math.max(minVal, math.min(maxVal, z));
    w = math.max(minVal, math.min(maxVal, w));

    return this;
  }
  @override
  Vector4 clampLength<T extends num>(T min, T max) {
    final length = this.length;

    return divideScalar(length)
        .scale(math.max(min, math.min(max, length)));
  }
  @override
  Vector4 floor() {
    x = x.floorToDouble();
    y = y.floorToDouble();
    z = z.floorToDouble();
    w = w.floorToDouble();

    return this;
  }
  @override
  Vector4 ceil() {
    x = x.ceilToDouble();
    y = y.ceilToDouble();
    z = z.ceilToDouble();
    w = w.ceilToDouble();

    return this;
  }
  @override
  Vector4 round() {
    x = (x).roundToDouble();
    y = (y).roundToDouble();
    z = (z).roundToDouble();
    w = (w).roundToDouble();

    return this;
  }
  @override
  Vector4 roundToZero() {
    x = (x < 0) ? (x).ceilToDouble() : (x).floorToDouble();
    y = (y < 0) ? (y).ceilToDouble() : (y).floorToDouble();
    z = (z < 0) ? (z).ceilToDouble() : (z).floorToDouble();
    w = (w < 0) ? (w).ceilToDouble() : (w).floorToDouble();

    return this;
  }
  @override
  Vector4 negate() {
    x = -x;
    y = -y;
    z = -z;
    w = -w;

    return this;
  }
  @override
  double dot(Vector v) {
    double temp = x * v.x + y * v.y;
    if(v is Vector3){
      temp += z * v.z;
    }
    else if(v is Vector4){
      temp += z * v.z+ w * v.w;
    }
    return temp;
  }
  @override
  double get length2 => x * x + y * y + z * z + w * w;
  
  @override
  double get length => math.sqrt(x * x + y * y + z * z + w * w);
  
  @override
  double manhattanLength() {
    return (x.abs()+y.abs()+z.abs()+w.abs()).toDouble();
  }
  @override
  Vector4 normalize() {
    return divideScalar(length);
  }
  @override
  Vector4 setLength(double length) {
    return normalize().scale(length);
  }

  Vector4 lerp(Vector4 v, double alpha) {
    x += (v.x - x) * alpha;
    y += (v.y - y) * alpha;
    z += (v.z - z) * alpha;
    w += (v.w - w) * alpha;

    return this;
  }

  Vector4 lerpVectors(Vector4 v1, Vector4 v2, double alpha) {
    x = v1.x + (v2.x - v1.x) * alpha;
    y = v1.y + (v2.y - v1.y) * alpha;
    z = v1.z + (v2.z - v1.z) * alpha;
    w = v1.w + (v2.w - v1.w) * alpha;

    return this;
  }
  @override
  bool equals(Vector v) {
    if(v is Vector3){
      return (v.x == x) && (v.y == y) && (v.z == z);
    }
    else if(v is Vector4){
      return (v.x == x) && (v.y == y) && (v.z == z) && (v.w == w);
    }
    
    return (v.x == x) && (v.y == y);
  }
  @override
  List<num> toNumArray(List<num> array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];
    array[offset + 3] = storage[3];

    return array;
  }
  @override
  NativeArray copyIntoNativeArray(NativeArray array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];
    array[offset + 3] = storage[3];

    return array;
  }
  @override
  Vector4 fromNativeArray(NativeArray array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();
    z = array[offset + 2].toDouble();
    w = array[offset + 3].toDouble();

    return this;
  }
  @override
  Vector4 copyFromArray(List<double> array, [int offset = 0]) {
    x = array[offset];
    y = array[offset + 1];
    z = array[offset + 2];
    w = array[offset + 3];

    return this;
  }
  @override
  Vector4 copyFromUnknown(array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();
    z = array[offset + 2].toDouble();
    w = array[offset + 3].toDouble();

    return this;
  }
  @override
  List<double> copyIntoArray([List<double>? array, int offset = 0]) {
    if (array == null) {
      array = List<double>.filled(offset + 4, 0);
    } else {
      while (array.length < offset + 4) {
        array.add(0.0);
      }
    }

    array[offset] = x;
    array[offset + 1] = y;
    array[offset + 2] = z;
    array[offset + 3] = w;
    return array;
  }
  @override
  Vector4 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();
    z = attribute.getZ(index)?.toDouble() ?? 0.0;
    w = (attribute.getW(index) ?? 0).toDouble();

    return this;
  }
  @override
  Vector4 random() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    z = math.Random().nextDouble();
    w = math.Random().nextDouble();

    return this;
  }

  // Vector4.fromJson(Map<String, dynamic> json) {
  //   x = json['x'];
  //   y = json['y'];
  //   z = json['z'];
  //   w = json['w'];
  // }
  @override
  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z, 'w': w};
  }
  @override
  String toString(){
    return toJson().toString();
  }

  Vector4 operator*(Vector4 v) => multiply(v);
}
