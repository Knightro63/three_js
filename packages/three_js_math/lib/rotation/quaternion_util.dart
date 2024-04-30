import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
import './euler.dart';

Function onChangeCallback = () {};

extension Quat on Quaternion {
  void onChange(Function callback) {
    onChangeCallback = callback;
  }

  Quaternion setFromAxisAngle(Vector3 axis, double angle) {
    final halfAngle = angle / 2, s = math.sin(halfAngle);

    x = axis.x * s;
    y = axis.y * s;
    z = axis.z * s;
    w = math.cos(halfAngle);

    onChangeCallback();

    return this;
  }

  Quaternion multiply(Quaternion q) {
    return multiply2(this, q);
  }


  Quaternion multiply2(Quaternion a, Quaternion b) {
    // from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

    final qax = a.x, qay = a.y, qaz = a.z, qaw = a.w;
    final qbx = b.x, qby = b.y, qbz = b.z, qbw = b.w;

    x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
    y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
    z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
    w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

    return this;
  }

  Quaternion setFromEuler(Euler euler, [bool update = false]) {
    final x_ = euler.x;
    final y_ = euler.y;
    final z_ = euler.z;
    final order = euler.order;

    // http://www.mathworks.com/matlabcentral/fileexchange/
    // 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
    //	content/SpinCalc.m

    final c1 = math.cos(x_ / 2);
    final c2 = math.cos(y_ / 2);
    final c3 = math.cos(z_ / 2);

    final s1 = math.sin(x_ / 2);
    final s2 = math.sin(y_ / 2);
    final s3 = math.sin(z_ / 2);

    switch (order) {
      case RotationOrders.xyz:
        x = s1 * c2 * c3 + c1 * s2 * s3;
        y = c1 * s2 * c3 - s1 * c2 * s3;
        z = c1 * c2 * s3 + s1 * s2 * c3;
        w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.yxz:
        x = s1 * c2 * c3 + c1 * s2 * s3;
        y = c1 * s2 * c3 - s1 * c2 * s3;
        z = c1 * c2 * s3 - s1 * s2 * c3;
        w = c1 * c2 * c3 + s1 * s2 * s3;
        break;

      case RotationOrders.zxy:
        x = s1 * c2 * c3 - c1 * s2 * s3;
        y = c1 * s2 * c3 + s1 * c2 * s3;
        z = c1 * c2 * s3 + s1 * s2 * c3;
        w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.zyx:
        x = s1 * c2 * c3 - c1 * s2 * s3;
        y = c1 * s2 * c3 + s1 * c2 * s3;
        z = c1 * c2 * s3 - s1 * s2 * c3;
        w = c1 * c2 * c3 + s1 * s2 * s3;
        break;

      case RotationOrders.yzx:
        x = s1 * c2 * c3 + c1 * s2 * s3;
        y = c1 * s2 * c3 + s1 * c2 * s3;
        z = c1 * c2 * s3 - s1 * s2 * c3;
        w = c1 * c2 * c3 - s1 * s2 * s3;
        break;

      case RotationOrders.xzy:
        x = s1 * c2 * c3 - c1 * s2 * s3;
        y = c1 * s2 * c3 - s1 * c2 * s3;
        z = c1 * c2 * s3 + s1 * s2 * c3;
        w = c1 * c2 * c3 + s1 * s2 * s3;
        break;
      default:
        throw('THREE.Quaternion: .setFromEuler() encountered an unknown order: $order');
    }
    if (update) onChangeCallback();
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

      w = 0.25 / s;
      x = (m32 - m23) * s;
      y = (m13 - m31) * s;
      z = (m21 - m12) * s;
    } else if (m11 > m22 && m11 > m33) {
      final s = 2.0 * math.sqrt(1.0 + m11 - m22 - m33);

      w = (m32 - m23) / s;
      x = 0.25 * s;
      y = (m12 + m21) / s;
      z = (m13 + m31) / s;
    } else if (m22 > m33) {
      final s = 2.0 * math.sqrt(1.0 + m22 - m11 - m33);

      w = (m13 - m31) / s;
      x = (m12 + m21) / s;
      y = 0.25 * s;
      z = (m23 + m32) / s;
    } else {
      final s = 2.0 * math.sqrt(1.0 + m33 - m11 - m22);

      w = (m21 - m12) / s;
      x = (m13 + m31) / s;
      y = (m23 + m32) / s;
      z = 0.25 * s;
    }

    onChangeCallback();
    
    return this;
  }
}