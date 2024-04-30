//import './index.dart';
import 'dart:math';
import '../vector/vector3_util.dart';
import 'package:vector_math/vector_math.dart';

final _matrix4v1 = Vector3.zero();
final _matrix4x = Vector3.zero();
final _matrix4y = Vector3.zero();
final _matrix4z = Vector3.zero();

final _matrix4zero = Vector3(0, 0, 0);
final _matrix4one = Vector3(1, 1, 1);

extension Mat4 on Matrix4{
  Matrix4 makeTranslation(double x, double y, double z) {
    setValues(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1);
    return this;
  }

  Matrix4 fromNativeArray(array, [int offset = 0]) {
    for (int i = 0; i < 16; i++) {
      storage[i] = array[i + offset].toDouble();
    }

    return this;
  }

  Matrix4 copyPosition(Matrix4 m) {
    final te = storage, me = m.storage;

    te[12] = me[12];
    te[13] = me[13];
    te[14] = me[14];

    return this;
  }

  Matrix4 multiply2(Matrix4 a, Matrix4 b) {
    final ae = a.storage;
    final be = b.storage;
    final te = storage;

    final a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    final a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    final a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    final a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    final b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    final b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    final b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    final b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

    return this;
  }
  Matrix4 makeOrthographic(
    double left, 
    double right, 
    double top, 
    double bottom, 
    double near, 
    double far
  ) {
    final te = storage;
    final w = 1.0 / (right - left);
    final h = 1.0 / (top - bottom);
    final p = 1.0 / (far - near);

    final x = (right + left) * w;
    final y = (top + bottom) * h;
    final z = (far + near) * p;

    te[0] = 2 * w;
    te[4] = 0;
    te[8] = 0;
    te[12] = -x;
    te[1] = 0;
    te[5] = 2 * h;
    te[9] = 0;
    te[13] = -y;
    te[2] = 0;
    te[6] = 0;
    te[10] = -2 * p;
    te[14] = -z;
    te[3] = 0;
    te[7] = 0;
    te[11] = 0;
    te[15] = 1;

    return this;
  }

  Matrix4 makePerspective(
    double left, 
    double right, 
    double top, 
    double bottom, 
    double near, 
    double far
  ) {
    
    final te = storage;
    final x = 2 * near / (right - left);
    final y = 2 * near / (top - bottom);

    final a = (right + left) / (right - left);
    final b = (top + bottom) / (top - bottom);
    final c = -(far + near) / (far - near);
    final d = -2 * far * near / (far - near);

    te[0] = x;
    te[4] = 0;
    te[8] = a;
    te[12] = 0;
    te[1] = 0;
    te[5] = y;
    te[9] = b;
    te[13] = 0;
    te[2] = 0;
    te[6] = 0;
    te[10] = c;
    te[14] = d;
    te[3] = 0;
    te[7] = 0;
    te[11] = -1;
    te[15] = 0;

    return this;
  }

  Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    _matrix4z.sub2(eye, target);

    if (_matrix4z.length2 == 0) {
      _matrix4z.z = 1;
    }

    _matrix4z.normalize();
    _matrix4x.cross2(up, _matrix4z);

    if (_matrix4x.length2 == 0) {
      if (up.z.abs() == 1) {
        _matrix4z.x += 0.0001;
      } else {
        _matrix4z.z += 0.0001;
      }

      _matrix4z.normalize();
      _matrix4x.cross2(up, _matrix4z);
    }

    _matrix4x.normalize();
    _matrix4y.cross2(_matrix4z, _matrix4x);

    storage[0] = _matrix4x.x;
    storage[4] = _matrix4y.x;
    storage[8] = _matrix4z.x;
    storage[1] = _matrix4x.y;
    storage[5] = _matrix4y.y;
    storage[9] = _matrix4z.y;
    storage[2] = _matrix4x.z;
    storage[6] = _matrix4y.z;
    storage[10] = _matrix4z.z;

    return this;
  }
  Matrix4 compose(Vector3 position, Quaternion quaternion, Vector3 scale) {
    final te = storage;

    final x = quaternion.x;
    final y = quaternion.y;
    final z = quaternion.z;
    final w = quaternion.w;
    final x2 = x + x, y2 = y + y, z2 = z + z;
    final xx = x * x2, xy = x * y2, xz = x * z2;
    final yy = y * y2, yz = y * z2, zz = z * z2;
    final wx = w * x2, wy = w * y2, wz = w * z2;

    final sx = scale.x, sy = scale.y, sz = scale.z;

    te[0] = (1 - (yy + zz)) * sx;
    te[1] = (xy + wz) * sx;
    te[2] = (xz - wy) * sx;
    te[3] = 0;

    te[4] = (xy - wz) * sy;
    te[5] = (1.0 - (xx + zz)) * sy;
    te[6] = (yz + wx) * sy;
    te[7] = 0;

    te[8] = (xz + wy) * sz;
    te[9] = (yz - wx) * sz;
    te[10] = (1 - (xx + yy)) * sz;
    te[11] = 0;

    te[12] = position.x;
    te[13] = position.y;
    te[14] = position.z;
    te[15] = 1;

    return this;
  }
  Matrix4 makeRotationFromQuaternion(Quaternion q) {
    return compose(_matrix4zero, q, _matrix4one);
  }
  Matrix4 makeRotationX(double theta) {
    final c = cos(theta);
    final s = sin(theta);
    setValues(1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1);
    return this;
  }

  Matrix4 makeRotationY(double theta) {
    final c = cos(theta), s = sin(theta);
    setValues(c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1);
    return this;
  }

  Matrix4 makeRotationZ(double theta) {
    final c = cos(theta).toDouble(), s = sin(theta).toDouble();
    setValues(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    return this;
  }

  Matrix4 makeScale(double x, double y, double z) {
    setValues(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);
    return this;
  }

  Matrix4 extractRotation(Matrix4 m) {
    // this method does not support reflection matrices

    final te = storage;
    final me = m.storage;

    final scaleX = 1 / _matrix4v1.setFromMatrixColumn(m, 0).length;
    final scaleY = 1 / _matrix4v1.setFromMatrixColumn(m, 1).length;
    final scaleZ = 1 / _matrix4v1.setFromMatrixColumn(m, 2).length;

    te[0] = me[0] * scaleX;
    te[1] = me[1] * scaleX;
    te[2] = me[2] * scaleX;
    te[3] = 0;

    te[4] = me[4] * scaleY;
    te[5] = me[5] * scaleY;
    te[6] = me[6] * scaleY;
    te[7] = 0;

    te[8] = me[8] * scaleZ;
    te[9] = me[9] * scaleZ;
    te[10] = me[10] * scaleZ;
    te[11] = 0;

    te[12] = 0;
    te[13] = 0;
    te[14] = 0;
    te[15] = 1;

    return this;
  }
}