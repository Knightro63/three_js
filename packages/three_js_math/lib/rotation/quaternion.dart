import '../math/index.dart';
import '../vector/index.dart';
import '../buffer/index.dart';
import 'index.dart';
import 'dart:math' as math;

class Quaternion {
  

  String type = "Quaternion";
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  double _w = 0.0;

  Function onChangeCallback = () {};

  Quaternion.identity(){
    _x = 0.0;
    _y = 0.0;
    _z = 0.0;
    _w = 1.0;
  }

  Quaternion([double x = 0.0, double y = 0.0, double z = 0.0, double w = 1.0])
      : _x = x,
        _y = y,
        _z = z,
        _w = w;

  Quaternion.fromJson(List<double>? json) {
    if (json != null) {
      _x = json[0];
      _y = json[1];
      _z = json[2];
      _w = json[3];
    }
  }

  List<double> toJson() {
    return [_x, _y, _z, _w];
  }

  @Deprecated(' Static .slerp() has been deprecated. Use is now qm.slerpQuaternions( qa, qb, t ) instead.')
  static Quaternion staticSlerp(Quaternion qa, Quaternion qb, Quaternion qm, double t) {
    return qm.slerpQuaternions(qa, qb, t);
  }

  static void slerpFlat(dst, int dstOffset, src0, int srcOffset0, src1, int srcOffset1, double t) {
    // fuzz-free, array-based Quaternion SLERP operation

    double x0 = src0[srcOffset0 + 0].toDouble(),
        y0 = src0[srcOffset0 + 1].toDouble(),
        z0 = src0[srcOffset0 + 2].toDouble(),
        w0 = src0[srcOffset0 + 3].toDouble();

    double x1 = src1[srcOffset1 + 0].toDouble(),
        y1 = src1[srcOffset1 + 1].toDouble(),
        z1 = src1[srcOffset1 + 2].toDouble(),
        w1 = src1[srcOffset1 + 3].toDouble();

    if (t == 0) {
      dst[dstOffset] = x0;
      dst[dstOffset + 1] = y0;
      dst[dstOffset + 2] = z0;
      dst[dstOffset + 3] = w0;
      return;
    }

    if (t == 1) {
      dst[dstOffset] = x1;
      dst[dstOffset + 1] = y1;
      dst[dstOffset + 2] = z1;
      dst[dstOffset + 3] = w1;
      return;
    }

    if (w0 != w1 || x0 != x1 || y0 != y1 || z0 != z1) {
      double s = 1 - t;
      double cos = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
      final dir = (cos >= 0 ? 1 : -1), sqrSin = 1 - cos * cos;

      // Skip the Slerp for tiny steps to avoid numeric problems:
      if (sqrSin > MathUtils.epsilon) {
        final sin = math.sqrt(sqrSin), len = math.atan2(sin, cos * dir);

        s = math.sin(s * len) / sin;
        t = math.sin(t * len) / sin;
      }

      final tDir = t * dir;

      x0 = x0 * s + x1 * tDir;
      y0 = y0 * s + y1 * tDir;
      z0 = z0 * s + z1 * tDir;
      w0 = w0 * s + w1 * tDir;

      // Normalize in case we just did a lerp:
      if (s == 1 - t) {
        final f = 1 / math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

        x0 *= f;
        y0 *= f;
        z0 *= f;
        w0 *= f;
      }
    }

    dst[dstOffset] = x0;
    dst[dstOffset + 1] = y0;
    dst[dstOffset + 2] = z0;
    dst[dstOffset + 3] = w0;
  }

  static multiplyQuaternionsFlat(
      dst, int dstOffset, src0, int srcOffset0, src1, int srcOffset1) {
    final x0 = src0[srcOffset0];
    final y0 = src0[srcOffset0 + 1];
    final z0 = src0[srcOffset0 + 2];
    final w0 = src0[srcOffset0 + 3];

    final x1 = src1[srcOffset1];
    final y1 = src1[srcOffset1 + 1];
    final z1 = src1[srcOffset1 + 2];
    final w1 = src1[srcOffset1 + 3];

    dst[dstOffset] = x0 * w1 + w0 * x1 + y0 * z1 - z0 * y1;
    dst[dstOffset + 1] = y0 * w1 + w0 * y1 + z0 * x1 - x0 * z1;
    dst[dstOffset + 2] = z0 * w1 + w0 * z1 + x0 * y1 - y0 * x1;
    dst[dstOffset + 3] = w0 * w1 - x0 * x1 - y0 * y1 - z0 * z1;

    return dst;
  }

  double get x => _x;
  set x(double value) {
    _x = value;
    onChangeCallback();
  }

  double get y => _y;
  set y(double value) {
    _y = value;
    onChangeCallback();
  }

  double get z => _z;
  set z(double value) {
    _z = value;
    onChangeCallback();
  }

  double get w => _w;
  set w(double value) {
    _w = value;
    onChangeCallback();
  }

  Quaternion set(double x, double y, double z, double w) {
    _x = x;
    _y = y;
    _z = z;
    _w = w;

    onChangeCallback();

    return this;
  }

  Quaternion clone() {
    return Quaternion(_x, _y, _z, _w);
  }

  Quaternion setFrom(Quaternion quaternion) {
    _x = quaternion.x;
    _y = quaternion.y;
    _z = quaternion.z;
    _w = quaternion.w;

    onChangeCallback();

    return this;
  }

  Quaternion setFromEuler(Euler euler, [bool update = false]) {
    final x = euler.x;
    final y = euler.y;
    final z = euler.z;
    final order = euler.order;

    // http://www.mathworks.com/matlabcentral/fileexchange/
    // 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
    //	content/SpinCalc.m

    final c1 = math.cos(x / 2);
    final c2 = math.cos(y / 2);
    final c3 = math.cos(z / 2);

    final s1 = math.sin(x / 2);
    final s2 = math.sin(y / 2);
    final s3 = math.sin(z / 2);

    switch (order) {
      case RotationOrders.xyz:
        _x = s1 * c2 * c3 + c1 * s2 * s3;
        _y = c1 * s2 * c3 - s1 * c2 * s3;
        _z = c1 * c2 * s3 + s1 * s2 * c3;
        _w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.yxz:
        _x = s1 * c2 * c3 + c1 * s2 * s3;
        _y = c1 * s2 * c3 - s1 * c2 * s3;
        _z = c1 * c2 * s3 - s1 * s2 * c3;
        _w = c1 * c2 * c3 + s1 * s2 * s3;
        break;

      case RotationOrders.zxy:
        _x = s1 * c2 * c3 - c1 * s2 * s3;
        _y = c1 * s2 * c3 + s1 * c2 * s3;
        _z = c1 * c2 * s3 + s1 * s2 * c3;
        _w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.zyx:
        _x = s1 * c2 * c3 - c1 * s2 * s3;
        _y = c1 * s2 * c3 + s1 * c2 * s3;
        _z = c1 * c2 * s3 - s1 * s2 * c3;
        _w = c1 * c2 * c3 + s1 * s2 * s3;
        break;

      case RotationOrders.yzx:
         _x = s1 * c2 * c3 + c1 * s2 * s3;
        _y = c1 * s2 * c3 + s1 * c2 * s3;
        _z = c1 * c2 * s3 - s1 * s2 * c3;
        _w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.xzy:
        _x = s1 * c2 * c3 - c1 * s2 * s3;
        _y = c1 * s2 * c3 - s1 * c2 * s3;
        _z = c1 * c2 * s3 + s1 * s2 * c3;
        _w = c1 * c2 * c3 + s1 * s2 * s3;
        break;
      default:
        throw('THREE.Quaternion: .setFromEuler() encountered an unknown order: $order');
    }

    if (update) onChangeCallback();

    return this;
  }

  Quaternion setFromAxisAngle(Vector3 axis, double angle) {
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm

    // assumes axis is normalized

    final halfAngle = angle / 2, s = math.sin(halfAngle);

    _x = axis.x * s;
    _y = axis.y * s;
    _z = axis.z * s;
    _w = math.cos(halfAngle);

    onChangeCallback();

    return this;
  }

  Quaternion setFromRotationMatrix(m) {
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm

    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

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
    double trace = m11 + m22 + m33;

    if (trace > 0) {
      final s = 0.5 / math.sqrt(trace + 1.0);

      _w = 0.25 / s;
      _x = (m32 - m23) * s;
      _y = (m13 - m31) * s;
      _z = (m21 - m12) * s;
    } else if (m11 > m22 && m11 > m33) {
      final s = 2.0 * math.sqrt(1.0 + m11 - m22 - m33);

      _w = (m32 - m23) / s;
      _x = 0.25 * s;
      _y = (m12 + m21) / s;
      _z = (m13 + m31) / s;
    } else if (m22 > m33) {
      final s = 2.0 * math.sqrt(1.0 + m22 - m11 - m33);

      _w = (m13 - m31) / s;
      _x = (m12 + m21) / s;
      _y = 0.25 * s;
      _z = (m23 + m32) / s;
    } else {
      final s = 2.0 * math.sqrt(1.0 + m33 - m11 - m22);

      _w = (m21 - m12) / s;
      _x = (m13 + m31) / s;
      _y = (m23 + m32) / s;
      _z = 0.25 * s;
    }

    onChangeCallback();

    return this;
  }

  Quaternion setFromUnitVectors(Vector3 vFrom, Vector3 vTo) {
    // assumes direction vectors vFrom and vTo are normalized

    double r = vFrom.dot(vTo) + 1;

    if (r < MathUtils.epsilon) {
      r = 0;

      if (vFrom.x.abs() > vFrom.z.abs()) {
        _x = -vFrom.y;
        _y = vFrom.x;
        _z = 0;
        _w = r;
      } else {
        _x = 0;
        _y = -vFrom.z;
        _z = vFrom.y;
        _w = r;
      }
    } else {
      // cross2( vFrom, vTo ); // inlined to avoid cyclic dependency on Vector3

      _x = vFrom.y * vTo.z - vFrom.z * vTo.y;
      _y = vFrom.z * vTo.x - vFrom.x * vTo.z;
      _z = vFrom.x * vTo.y - vFrom.y * vTo.x;
      _w = r;
    }

    return normalize();
  }

  double angleTo(Quaternion q) {
    return 2 * math.acos(MathUtils.clamp(dot(q), -1, 1).abs());
  }

  Quaternion rotateTowards(Quaternion q, double step) {
    final angle = angleTo(q);

    if (angle == 0) return this;

    final t = math.min<double>(1, step / angle);

    slerp(q, t);

    return this;
  }

  Quaternion identity() {
    return set(0, 0, 0, 1);
  }

  Quaternion invert() {
    // quaternion is assumed to have unit length

    return conjugate();
  }

  Quaternion conjugate() {
    _x *= -1;
    _y *= -1;
    _z *= -1;

    onChangeCallback();

    return this;
  }

  double dot(Quaternion v) {
    return _x * v._x + _y * v._y + _z * v._z + _w * v._w;
  }

  double get length2 => _x * _x + _y * _y + _z * _z + _w * _w;
  

  double get length => math.sqrt(_x * _x + _y * _y + _z * _z + _w * _w);

  Quaternion normalize() {
    double l = length;

    if (l == 0) {
      _x = 0;
      _y = 0;
      _z = 0;
      _w = 1;
    } else {
      l = 1 / l;

      _x = _x * l;
      _y = _y * l;
      _z = _z * l;
      _w = _w * l;
    }

    onChangeCallback();

    return this;
  }

  Quaternion multiply(Quaternion q) {
    return multiplyQuaternions(this, q);
  }

  Quaternion premultiply(Quaternion q) {
    return multiplyQuaternions(q, this);
  }

  Quaternion multiplyQuaternions(Quaternion a, Quaternion b) {
    // from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

    final qax = a._x, qay = a._y, qaz = a._z, qaw = a._w;
    final qbx = b._x, qby = b._y, qbz = b._z, qbw = b._w;

    _x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
    _y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
    _z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
    _w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

    onChangeCallback();

    return this;
  }

  Quaternion slerp(Quaternion qb, double t) {
    if (t == 0) return this;
    if (t == 1) return setFrom(qb);

    final x = _x, y = _y, z = _z, w = _w;

    // http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/

    double cosHalfTheta = w * qb._w + x * qb._x + y * qb._y + z * qb._z;

    if (cosHalfTheta < 0) {
      _w = -qb._w;
      _x = -qb._x;
      _y = -qb._y;
      _z = -qb._z;

      cosHalfTheta = -cosHalfTheta;
    } else {
      setFrom(qb);
    }

    if (cosHalfTheta >= 1.0) {
      _w = w;
      _x = x;
      _y = y;
      _z = z;

      return this;
    }

    final sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;

    if (sqrSinHalfTheta <= MathUtils.epsilon) {
      final s = 1 - t;
      _w = s * w + t * _w;
      _x = s * x + t * _x;
      _y = s * y + t * _y;
      _z = s * z + t * _z;

      normalize();
      onChangeCallback();

      return this;
    }

    final sinHalfTheta = math.sqrt(sqrSinHalfTheta);
    final halfTheta = math.atan2(sinHalfTheta, cosHalfTheta);
    final ratioA = math.sin((1 - t) * halfTheta) / sinHalfTheta,
        ratioB = math.sin(t * halfTheta) / sinHalfTheta;

    _w = (w * ratioA + _w * ratioB);
    _x = (x * ratioA + _x * ratioB);
    _y = (y * ratioA + _y * ratioB);
    _z = (z * ratioA + _z * ratioB);

    onChangeCallback();

    return this;
  }

  Quaternion slerpQuaternions(Quaternion qa, Quaternion qb, double t) {
    return setFrom(qa).slerp(qb, t);
  }


  bool equals(Quaternion quaternion) {
    return (quaternion._x == _x) &&
        (quaternion._y == _y) &&
        (quaternion._z == _z) &&
        (quaternion._w == _w);
  }

  Quaternion fromArray(List<double> array, [int offset = 0]) {
    _x = array[offset];
    _y = array[offset + 1];
    _z = array[offset + 2];
    _w = array[offset + 3];

    onChangeCallback();

    return this;
  }

  Quaternion fromNumArray(List<num> array, [int offset = 0]) {
    _x = array[offset].toDouble();
    _y = array[offset + 1].toDouble();
    _z = array[offset + 2].toDouble();
    _w = array[offset + 3].toDouble();

    onChangeCallback();

    return this;
  }

  List<num> toNumArray(List<num> array, [int offset = 0]) {
    array[offset] = _x;
    array[offset + 1] = _y;
    array[offset + 2] = _z;
    array[offset + 3] = _w;

    return array;
  }

  List<double> toArray(List<double> array, [int offset = 0]) {
    array[offset] = _x;
    array[offset + 1] = _y;
    array[offset + 2] = _z;
    array[offset + 3] = _w;

    return array;
  }

  Quaternion copyFromUnknown(array, [int offset = 0]) {
    x = array[offset].toDouble();
    y = array[offset + 1].toDouble();
    z = array[offset + 2].toDouble();
    w = array[offset + 3].toDouble();

    return this;
  }
  Quaternion fromBuffer(BufferAttribute attribute, int index) {
    _x = attribute.getX(index)!.toDouble();
    _y = attribute.getY(index)!.toDouble();
    _z = attribute.getZ(index)!.toDouble();
    _w = attribute.getW(index)!.toDouble();

    return this;
  }

  void onChange(Function callback) {
    onChangeCallback = callback;
  }
}
