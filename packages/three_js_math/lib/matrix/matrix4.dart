import 'dart:typed_data';
import 'index.dart';
import '../vector/index.dart';
import '../rotation/index.dart';
import 'dart:math' as math;

final _matrix4v1 = Vector3.zero();
final _matrix4m1 = Matrix4.identity();
final _matrix4zero = Vector3(0, 0, 0);
final _matrix4one = Vector3(1, 1, 1);
final _matrix4x = Vector3.zero();
final _matrix4y = Vector3.zero();
final _matrix4z = Vector3.zero();

class Matrix4 {
  String type = "Matrix4";
  late Float32List storage;

 Matrix4() {
    storage = Float32List.fromList([
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0
    ]);
  }
  Matrix4.identity() {
    storage = Float32List.fromList([
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0
    ]);
  }
  Matrix4.zero() {
    storage = Float32List.fromList([
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    ]);
  }
  
  Matrix4 copyMatrixToVector3(Matrix4 m, [int row = 3]) {
    final te = storage, me = m.storage;

    te[row*4] = me[row*4];
    te[row*4+1] = me[row*4+1];
    te[row*4+2] = me[row*4+2];

    return this;
  }
  
  Matrix4 setValues(
      double n11,
      double n12,
      double n13,
      double n14,
      double n21,
      double n22,
      double n23,
      double n24,
      double n31,
      double n32,
      double n33,
      double n34,
      double n41,
      double n42,
      double n43,
      double n44) {
    final te = storage;

    te[0] = n11.toDouble();
    te[4] = n12.toDouble();
    te[8] = n13.toDouble();
    te[12] = n14.toDouble();
    te[1] = n21.toDouble();
    te[5] = n22.toDouble();
    te[9] = n23.toDouble();
    te[13] = n24.toDouble();
    te[2] = n31.toDouble();
    te[6] = n32.toDouble();
    te[10] = n33.toDouble();
    te[14] = n34.toDouble();
    te[3] = n41.toDouble();
    te[7] = n42.toDouble();
    te[11] = n43.toDouble();
    te[15] = n44.toDouble();

    return this;
  }

  Matrix4 identity() {
    setValues(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 1.0);

    return this;
  }

  Matrix4 clone() {
    return Matrix4.identity().copyFromArray(storage);
  }

  Matrix4 setFrom(Matrix4 m) {
    final te = storage;
    final me = m.storage;

    te[0] = me[0];
    te[1] = me[1];
    te[2] = me[2];
    te[3] = me[3];
    te[4] = me[4];
    te[5] = me[5];
    te[6] = me[6];
    te[7] = me[7];
    te[8] = me[8];
    te[9] = me[9];
    te[10] = me[10];
    te[11] = me[11];
    te[12] = me[12];
    te[13] = me[13];
    te[14] = me[14];
    te[15] = me[15];

    return this;
  }

  Matrix4 copyPosition(Matrix4 m) {
    final te = storage, me = m.storage;

    te[12] = me[12];
    te[13] = me[13];
    te[14] = me[14];

    return this;
  }

  Matrix4 setFromMatrix3(Matrix3 m) {
    final me = m.storage;
    setValues(me[0], me[3], me[6], 0, me[1], me[4], me[7], 0, me[2], me[5], me[8], 0,0, 0, 0, 1);
    return this;
  }

  Matrix4 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis) {
    xAxis.setFromMatrixColumn(this, 0);
    yAxis.setFromMatrixColumn(this, 1);
    zAxis.setFromMatrixColumn(this, 2);

    return this;
  }

  Matrix4 makeBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis) {
    setValues(xAxis.x, yAxis.x, zAxis.x, 0, xAxis.y, yAxis.y, zAxis.y, 0, xAxis.z,
        yAxis.z, zAxis.z, 0, 0, 0, 0, 1);

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

  Matrix4 makeRotationFromEuler(Euler euler) {
    final te = storage;

    final x = euler.x, y = euler.y, z = euler.z;
    final a = math.cos(x).toDouble(), b = math.sin(x).toDouble();
    final c = math.cos(y).toDouble(), d = math.sin(y).toDouble();
    final e = math.cos(z).toDouble(), f = math.sin(z).toDouble();

    if (euler.order == RotationOrders.xyz) {
      final ae = a * e, af = a * f, be = b * e, bf = b * f;

      te[0] = c * e;
      te[4] = -c * f;
      te[8] = d;

      te[1] = af + be * d;
      te[5] = ae - bf * d;
      te[9] = -b * c;

      te[2] = bf - ae * d;
      te[6] = be + af * d;
      te[10] = a * c;
    } else if (euler.order == RotationOrders.yxz) {
      final ce = c * e, cf = c * f, de = d * e, df = d * f;

      te[0] = ce + df * b;
      te[4] = de * b - cf;
      te[8] = a * d;

      te[1] = a * f;
      te[5] = a * e;
      te[9] = -b;

      te[2] = cf * b - de;
      te[6] = df + ce * b;
      te[10] = a * c;
    } else if (euler.order == RotationOrders.zxy) {
      final ce = c * e, cf = c * f, de = d * e, df = d * f;

      te[0] = ce - df * b;
      te[4] = -a * f;
      te[8] = de + cf * b;

      te[1] = cf + de * b;
      te[5] = a * e;
      te[9] = df - ce * b;

      te[2] = -a * d;
      te[6] = b;
      te[10] = a * c;
    } else if (euler.order == RotationOrders.zyx) {
      final ae = a * e, af = a * f, be = b * e, bf = b * f;

      te[0] = c * e;
      te[4] = be * d - af;
      te[8] = ae * d + bf;

      te[1] = c * f;
      te[5] = bf * d + ae;
      te[9] = af * d - be;

      te[2] = -d;
      te[6] = b * c;
      te[10] = a * c;
    } else if (euler.order == RotationOrders.yzx) {
      final ac = a * c, ad = a * d, bc = b * c, bd = b * d;

      te[0] = c * e;
      te[4] = bd - ac * f;
      te[8] = bc * f + ad;

      te[1] = f;
      te[5] = a * e;
      te[9] = -b * e;

      te[2] = -d * e;
      te[6] = ad * f + bc;
      te[10] = ac - bd * f;
    } else if (euler.order == RotationOrders.xzy) {
      final ac = a * c, ad = a * d, bc = b * c, bd = b * d;

      te[0] = c * e;
      te[4] = -f;
      te[8] = d * e;

      te[1] = ac * f + bd;
      te[5] = a * e;
      te[9] = ad * f - bc;

      te[2] = bc * f - ad;
      te[6] = b * e;
      te[10] = bd * f + ac;
    }

    // bottom row
    te[3] = 0;
    te[7] = 0;
    te[11] = 0;

    // last column
    te[12] = 0;
    te[13] = 0;
    te[14] = 0;
    te[15] = 1;

    return this;
  }

  Matrix4 makeRotationFromQuaternion(Quaternion q) {
    return compose(_matrix4zero, q, _matrix4one);
  }

  Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    final te = storage;

    _matrix4z.sub2(eye, target);

    if (_matrix4z.length2 == 0) {
      // eye and target are in the same position

      _matrix4z.z = 1;
    }

    _matrix4z.normalize();
    _matrix4x.cross2(up, _matrix4z);

    if (_matrix4x.length2 == 0) {
      // up and z are parallel

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

    te[0] = _matrix4x.x.toDouble();
    te[4] = _matrix4y.x.toDouble();
    te[8] = _matrix4z.x.toDouble();
    te[1] = _matrix4x.y.toDouble();
    te[5] = _matrix4y.y.toDouble();
    te[9] = _matrix4z.y.toDouble();
    te[2] = _matrix4x.z.toDouble();
    te[6] = _matrix4y.z.toDouble();
    te[10] = _matrix4z.z.toDouble();

    return this;
  }

  Matrix4 multiply(Matrix4 m) {
    return multiply2(this, m);
  }

  Matrix4 premultiply(Matrix4 m) {
    return multiply2(m, this);
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

  Matrix4 scale(double s) {
    final te = storage;

    te[0] *= s;
    te[4] *= s;
    te[8] *= s;
    te[12] *= s;
    te[1] *= s;
    te[5] *= s;
    te[9] *= s;
    te[13] *= s;
    te[2] *= s;
    te[6] *= s;
    te[10] *= s;
    te[14] *= s;
    te[3] *= s;
    te[7] *= s;
    te[11] *= s;
    te[15] *= s;

    return this;
  }
  Matrix4 scaleByVector(Vector v) {
    final te = storage;
    final x = v.x; 
    final y = v.y;
    double z = 1;

    if(v is Vector3){
      z = v.z;
    }
    else if(v is Vector4){
      z = v.z;
    }

    te[0] *= x;
    te[4] *= y;
    te[8] *= z;
    te[1] *= x;
    te[5] *= y;
    te[9] *= z;
    te[2] *= x;
    te[6] *= y;
    te[10] *= z;
    te[3] *= x;
    te[7] *= y;
    te[11] *= z;

    return this;
  }
  double determinant() {
    final te = storage;

    double n11 = te[0], n12 = te[4], n13 = te[8], n14 = te[12];
    double n21 = te[1], n22 = te[5], n23 = te[9], n24 = te[13];
    double n31 = te[2], n32 = te[6], n33 = te[10], n34 = te[14];
    double n41 = te[3], n42 = te[7], n43 = te[11], n44 = te[15];

    double v1 = n41 *
        (n14 * n23 * n32 -
            n13 * n24 * n32 -
            n14 * n22 * n33 +
            n12 * n24 * n33 +
            n13 * n22 * n34 -
            n12 * n23 * n34);

    double v2 = n42 *
        (n11 * n23 * n34 -
            n11 * n24 * n33 +
            n14 * n21 * n33 -
            n13 * n21 * n34 +
            n13 * n24 * n31 -
            n14 * n23 * n31);

    double v3 = n43 *
        (n11 * n24 * n32 -
            n11 * n22 * n34 -
            n14 * n21 * n32 +
            n12 * n21 * n34 +
            n14 * n22 * n31 -
            n12 * n24 * n31);

    double v4 = n44 *
        (-n13 * n22 * n31 -
            n11 * n23 * n32 +
            n11 * n22 * n33 +
            n13 * n21 * n32 -
            n12 * n21 * n33 +
            n12 * n23 * n31);

    final result = (v1 + v2 + v3 + v4);

    // print(" v1: ${v1} v2: ${v2} v3: ${v3} v4: ${v4}  result: ${result} ");

    return result;
  }

  Matrix4 transpose() {
    final te = storage;
    double tmp = te[1];
    te[1] = te[4];
    te[4] = tmp;
    tmp = te[2];
    te[2] = te[8];
    te[8] = tmp;
    tmp = te[6];
    te[6] = te[9];
    te[9] = tmp;

    tmp = te[3];
    te[3] = te[12];
    te[12] = tmp;
    tmp = te[7];
    te[7] = te[13];
    te[13] = tmp;
    tmp = te[11];
    te[11] = te[14];
    te[14] = tmp;

    return this;
  }

  // x is Vector3 | num
  Matrix4 setPosition(double x, double y, double z) {
    final te = storage;

    // if (x is Vector3) {
    //   print("warn use setPositionFromVector3 ........... ");
    //   return setPositionFromVector3(x);
    // } else {
      te[12] = x.toDouble();
      te[13] = y.toDouble();
      te[14] = z.toDouble();
    //}

    return this;
  }

  Matrix4 setPositionFromVector3(Vector3 x) {
    final te = storage;

    te[12] = x.x.toDouble();
    te[13] = x.y.toDouble();
    te[14] = x.z.toDouble();

    return this;
  }

  Matrix4 invert() {
    // based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
    final te = storage;
    final double n11 = te[0],
        n21 = te[1],
        n31 = te[2],
        n41 = te[3],
        n12 = te[4],
        n22 = te[5],
        n32 = te[6],
        n42 = te[7],
        n13 = te[8],
        n23 = te[9],
        n33 = te[10],
        n43 = te[11],
        n14 = te[12],
        n24 = te[13],
        n34 = te[14],
        n44 = te[15],
        t11 = n23 * n34 * n42 -
            n24 * n33 * n42 +
            n24 * n32 * n43 -
            n22 * n34 * n43 -
            n23 * n32 * n44 +
            n22 * n33 * n44,
        t12 = n14 * n33 * n42 -
            n13 * n34 * n42 -
            n14 * n32 * n43 +
            n12 * n34 * n43 +
            n13 * n32 * n44 -
            n12 * n33 * n44,
        t13 = n13 * n24 * n42 -
            n14 * n23 * n42 +
            n14 * n22 * n43 -
            n12 * n24 * n43 -
            n13 * n22 * n44 +
            n12 * n23 * n44,
        t14 = n14 * n23 * n32 -
            n13 * n24 * n32 -
            n14 * n22 * n33 +
            n12 * n24 * n33 +
            n13 * n22 * n34 -
            n12 * n23 * n34;

    final det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

    if (det == 0) return setValues(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    final detInv = 1 / det;

    te[0] = t11 * detInv;
    te[1] = (n24 * n33 * n41 -
            n23 * n34 * n41 -
            n24 * n31 * n43 +
            n21 * n34 * n43 +
            n23 * n31 * n44 -
            n21 * n33 * n44) *
        detInv;
    te[2] = (n22 * n34 * n41 -
            n24 * n32 * n41 +
            n24 * n31 * n42 -
            n21 * n34 * n42 -
            n22 * n31 * n44 +
            n21 * n32 * n44) *
        detInv;
    te[3] = (n23 * n32 * n41 -
            n22 * n33 * n41 -
            n23 * n31 * n42 +
            n21 * n33 * n42 +
            n22 * n31 * n43 -
            n21 * n32 * n43) *
        detInv;

    te[4] = t12 * detInv;
    te[5] = (n13 * n34 * n41 -
            n14 * n33 * n41 +
            n14 * n31 * n43 -
            n11 * n34 * n43 -
            n13 * n31 * n44 +
            n11 * n33 * n44) *
        detInv;
    te[6] = (n14 * n32 * n41 -
            n12 * n34 * n41 -
            n14 * n31 * n42 +
            n11 * n34 * n42 +
            n12 * n31 * n44 -
            n11 * n32 * n44) *
        detInv;
    te[7] = (n12 * n33 * n41 -
            n13 * n32 * n41 +
            n13 * n31 * n42 -
            n11 * n33 * n42 -
            n12 * n31 * n43 +
            n11 * n32 * n43) *
        detInv;

    te[8] = t13 * detInv;
    te[9] = (n14 * n23 * n41 -
            n13 * n24 * n41 -
            n14 * n21 * n43 +
            n11 * n24 * n43 +
            n13 * n21 * n44 -
            n11 * n23 * n44) *
        detInv;
    te[10] = (n12 * n24 * n41 -
            n14 * n22 * n41 +
            n14 * n21 * n42 -
            n11 * n24 * n42 -
            n12 * n21 * n44 +
            n11 * n22 * n44) *
        detInv;
    te[11] = (n13 * n22 * n41 -
            n12 * n23 * n41 -
            n13 * n21 * n42 +
            n11 * n23 * n42 +
            n12 * n21 * n43 -
            n11 * n22 * n43) *
        detInv;

    te[12] = t14 * detInv;
    te[13] = (n13 * n24 * n31 -
            n14 * n23 * n31 +
            n14 * n21 * n33 -
            n11 * n24 * n33 -
            n13 * n21 * n34 +
            n11 * n23 * n34) *
        detInv;
    te[14] = (n14 * n22 * n31 -
            n12 * n24 * n31 -
            n14 * n21 * n32 +
            n11 * n24 * n32 +
            n12 * n21 * n34 -
            n11 * n22 * n34) *
        detInv;
    te[15] = (n12 * n23 * n31 -
            n13 * n22 * n31 +
            n13 * n21 * n32 -
            n11 * n23 * n32 -
            n12 * n21 * n33 +
            n11 * n22 * n33) *
        detInv;

    return this;
  }

  double getMaxScaleOnAxis() {
    final te = storage;

    double scaleXSq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2];
    double scaleYSq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6];
    double scaleZSq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10];

    return math.sqrt(math.max(math.max(scaleXSq, scaleYSq), scaleZSq));
  }

  Matrix4 makeTranslation(double x, double y, double z) {
    setValues(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationX(double theta) {
    final c = math.cos(theta).toDouble(), s = math.sin(theta).toDouble();

    setValues(1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationY(double theta) {
    final c = math.cos(theta).toDouble(), s = math.sin(theta).toDouble();

    setValues(c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationZ(double theta) {
    final c = math.cos(theta).toDouble(), s = math.sin(theta).toDouble();

    setValues(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeRotationAxis(Vector3 axis, double angle) {
    // Based on http://www.gamedev.net/reference/articles/article1199.asp

    final c = math.cos(angle).toDouble();
    final s = math.sin(angle).toDouble();
    final t = 1 - c;
    final x = axis.x, y = axis.y, z = axis.z;
    final tx = t * x, ty = t * y;

    setValues(
        tx * x + c,
        tx * y - s * z,
        tx * z + s * y,
        0,
        tx * y + s * z,
        ty * y + c,
        ty * z - s * x,
        0,
        tx * z - s * y,
        ty * z + s * x,
        t * z * z + c,
        0,
        0,
        0,
        0,
        1);

    return this;
  }

  Matrix4 makeScale(double x, double y, double z) {
    setValues(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 makeShear(double xy, double xz, double yx, double yz, double zx, double zy) {
    setValues(1, yx, zx, 0, xy, 1, zy, 0, xz, yz, 1, 0, 0, 0, 0, 1);

    return this;
  }

  Matrix4 compose(Vector3 position, Quaternion quaternion, Vector3 scale) {
    final te = storage;

    final x = quaternion.x.toDouble();
    final y = quaternion.y.toDouble();
    final z = quaternion.z.toDouble();
    final w = quaternion.w.toDouble();
    final x2 = x + x, y2 = y + y, z2 = z + z;
    final xx = x * x2, xy = x * y2, xz = x * z2;
    final yy = y * y2, yz = y * z2, zz = z * z2;
    final wx = w * x2, wy = w * y2, wz = w * z2;

    final sx = scale.x, sy = scale.y, sz = scale.z;

    te[0] = (1 - (yy + zz)) * sx.toDouble();
    te[1] = (xy + wz) * sx;
    te[2] = (xz - wy) * sx;
    te[3] = 0;

    te[4] = (xy - wz) * sy;
    te[5] = (1.0 - (xx + zz)) * sy;
    te[6] = (yz + wx) * sy;
    te[7] = 0;

    te[8] = (xz + wy) * sz;
    te[9] = (yz - wx) * sz;
    te[10] = (1 - (xx + yy)) * sz.toDouble();
    te[11] = 0;

    te[12] = position.x.toDouble();
    te[13] = position.y.toDouble();
    te[14] = position.z.toDouble();
    te[15] = 1;

    return this;
  }

  Matrix4 decompose(Vector3 position, Quaternion quaternion, Vector3 scale) {
    final te = storage;

    double sx = (_matrix4v1.setValues(te[0], te[1], te[2])).length;
    final sy = (_matrix4v1.setValues(te[4], te[5], te[6])).length;
    final sz = (_matrix4v1.setValues(te[8], te[9], te[10])).length;

    // if determine is negative, we need to invert one scale
    final det = determinant();
    if (det < 0) sx = -sx;

    position.x = te[12];
    position.y = te[13];
    position.z = te[14];

    // scale the rotation part
    _matrix4m1.setFrom(this);

    final invSX = 1 / sx;
    final invSY = 1 / sy;
    final invSZ = 1 / sz;

    _matrix4m1.storage[0] *= invSX;
    _matrix4m1.storage[1] *= invSX;
    _matrix4m1.storage[2] *= invSX;

    _matrix4m1.storage[4] *= invSY;
    _matrix4m1.storage[5] *= invSY;
    _matrix4m1.storage[6] *= invSY;

    _matrix4m1.storage[8] *= invSZ;
    _matrix4m1.storage[9] *= invSZ;
    _matrix4m1.storage[10] *= invSZ;

    quaternion.setFromRotationMatrix(_matrix4m1);

    scale.x = sx;
    scale.y = sy;
    scale.z = sz;

    return this;
  }

  Matrix4 makePerspective(double left, double right, double top, double bottom, double near, double far) {
    
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

  Matrix4 makeOrthographic(double left, double right, double top, double bottom, double near, double far) {
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

  bool equals(Matrix4 matrix) {
    final te = storage;
    final me = matrix.storage;

    for (int i = 0; i < 16; i++) {
      if (te[i] != me[i]) return false;
    }

    return true;
  }

  Matrix4 fromNativeArray( array, [int offset = 0]) {
    for (int i = 0; i < 16; i++) {
      storage[i] = array[i + offset].toDouble();
    }

    return this;
  }
  Matrix4 copyFromArray(List<double> array, [int offset = 0]) {
    for (int i = 0; i < 16; i++) {
      storage[i] = array[i + offset];
    }

    return this;
  }
  Matrix4 copyFromUnknown(array, [int offset = 0]) {
    for (int i = 0; i < 16; i++) {
      storage[i] = array[i + offset].toDouble();
    }

    return this;
  }
  List<num> copyIntoArray(List<num> array, [int offset = 0]) {
    final te = storage;

    array[offset] = te[0];
    array[offset + 1] = te[1];
    array[offset + 2] = te[2];
    array[offset + 3] = te[3];

    array[offset + 4] = te[4];
    array[offset + 5] = te[5];
    array[offset + 6] = te[6];
    array[offset + 7] = te[7];

    array[offset + 8] = te[8];
    array[offset + 9] = te[9];
    array[offset + 10] = te[10];
    array[offset + 11] = te[11];

    array[offset + 12] = te[12];
    array[offset + 13] = te[13];
    array[offset + 14] = te[14];
    array[offset + 15] = te[15];

    return array;
  }

  List<double> toList() {
    return storage.sublist(0);
  }
  @Deprecated('Use matrixInv.copy( matrix ).invert()')
  Matrix4 getInverse(Matrix4 matrix) {
    return setFrom(matrix).invert();
  }
}
