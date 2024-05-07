import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';
import 'dart:math' as math;
import 'index.dart';

/// A class representing a 3x3
/// [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)).
class Matrix3 {
  String type = "Matrix3";

  late Float32List storage;

  /// Creates a 3x3 matrix with the given arguments in row-major order. If no arguments are provided, the constructor initializes
  /// the [Matrix3] to the 3x3 [identity matrix](https://en.wikipedia.org/wiki/Identity_matrix).
  Matrix3.identity() {
    storage = Float32List.fromList([1, 0, 0, 0, 1, 0, 0, 0, 1]);
  }

  Matrix3 setValues(double n11, double n12, double n13, double n21, double n22, double n23, double n31, double n32, double n33) {
    final te = storage;

    te[0] = n11;
    te[1] = n21;
    te[2] = n31;
    te[3] = n12;
    te[4] = n22;
    te[5] = n32;
    te[6] = n13;
    te[7] = n23;
    te[8] = n33;

    return this;
  }

  /// Set the current 3x3 matrix as an identity matrix.
  Matrix3 identity() {
    setValues(1, 0, 0, 0, 1, 0, 0, 0, 1);

    return this;
  }

  void applyMatrix3(Matrix3 arg) {
    final argStorage = arg.storage;
    final v0 = storage[0];
    final v1 = storage[1];
    final v2 = storage[2];
    storage[0] =
        argStorage[0] * v0 + argStorage[3] * v1 + argStorage[6] * v2;
    storage[1] =
        argStorage[1] * v0 + argStorage[4] * v1 + argStorage[7] * v2;
    storage[2] =
        argStorage[2] * v0 + argStorage[5] * v1 + argStorage[8] * v2;
  }

  /// Creates a new Matrix3 and with identical elements to this one.
  Matrix3 clone() {
    return Matrix3.identity().copyFromArray(storage);
  }

  /// Copies the elements of matrix [page:Matrix3 m] into this matrix.
  Matrix3 setFrom(Matrix3 m) {
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

    return this;
  }

  // Matrix3 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis) {
  //   xAxis.setFromMatrix3Column(this, 0);
  //   yAxis.setFromMatrix3Column(this, 1);
  //   zAxis.setFromMatrix3Column(this, 2);

  //   return this;
  // }

  /// Set this matrix to the upper 3x3 matrix of the Matrix4 [m].
  Matrix3 setFromMatrix4(Matrix4 m) {
    final me = m.storage;

    setValues(me[0], me[4], me[8], me[1], me[5], me[9], me[2], me[6], me[10]);

    return this;
  }

  /// Post-multiplies this matrix by [m].
  Matrix3 multiply(Matrix3 m) {
    return multiply2(this, m);
  }

  Matrix3 premultiply(Matrix3 m) {
    return multiply2(m, this);
  }

  /// Sets this matrix to [a] x [b].
  Matrix3 multiply2(Matrix3 a, Matrix3 b) {
    final ae = a.storage;
    final be = b.storage;
    final te = storage;

    final a11 = ae[0], a12 = ae[3], a13 = ae[6];
    final a21 = ae[1], a22 = ae[4], a23 = ae[7];
    final a31 = ae[2], a32 = ae[5], a33 = ae[8];

    final b11 = be[0], b12 = be[3], b13 = be[6];
    final b21 = be[1], b22 = be[4], b23 = be[7];
    final b31 = be[2], b32 = be[5], b33 = be[8];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31;
    te[3] = a11 * b12 + a12 * b22 + a13 * b32;
    te[6] = a11 * b13 + a12 * b23 + a13 * b33;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31;
    te[4] = a21 * b12 + a22 * b22 + a23 * b32;
    te[7] = a21 * b13 + a22 * b23 + a23 * b33;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31;
    te[5] = a31 * b12 + a32 * b22 + a33 * b32;
    te[8] = a31 * b13 + a32 * b23 + a33 * b33;

    return this;
  }

  /// Multiplies every component of the matrix by the scalar value [s].
  Matrix3 scale(double s) {
    final te = storage;

    te[0] *= s;
    te[3] *= s;
    te[6] *= s;
    te[1] *= s;
    te[4] *= s;
    te[7] *= s;
    te[2] *= s;
    te[5] *= s;
    te[8] *= s;

    return this;
  }
  Matrix3 scaleXY(double sx, double sy) {
    final te = storage;

    te[0] *= sx;
    te[3] *= sx;
    te[6] *= sx;
    te[1] *= sy;
    te[4] *= sy;
    te[7] *= sy;

    return this;
  }
  
  /// Computes and returns the [determinant](https://en.wikipedia.org/wiki/Determinant) of this matrix.
  double determinant() {
    final te = storage;

    final a = te[0],
        b = te[1],
        c = te[2],
        d = te[3],
        e = te[4],
        f = te[5],
        g = te[6],
        h = te[7],
        i = te[8];

    return a * e * i -
        a * f * h -
        b * d * i +
        b * f * g +
        c * d * h -
        c * e * g;
  }

  /// Inverts this matrix, using the
  /// [analytic method](https://en.wikipedia.org/wiki/Invertible_matrix#Analytic_solution). 
  /// You can not invert with a determinant of zero. If you
  /// attempt this, the method produces a zero matrix instead.
  Matrix3 invert() {
    final te = storage,
        n11 = te[0],
        n21 = te[1],
        n31 = te[2],
        n12 = te[3],
        n22 = te[4],
        n32 = te[5],
        n13 = te[6],
        n23 = te[7],
        n33 = te[8],
        t11 = n33 * n22 - n32 * n23,
        t12 = n32 * n13 - n33 * n12,
        t13 = n23 * n12 - n22 * n13,
        det = n11 * t11 + n21 * t12 + n31 * t13;

    if (det == 0) return setValues(0, 0, 0, 0, 0, 0, 0, 0, 0);

    final detInv = 1 / det;

    te[0] = t11 * detInv;
    te[1] = (n31 * n23 - n33 * n21) * detInv;
    te[2] = (n32 * n21 - n31 * n22) * detInv;

    te[3] = t12 * detInv;
    te[4] = (n33 * n11 - n31 * n13) * detInv;
    te[5] = (n31 * n12 - n32 * n11) * detInv;

    te[6] = t13 * detInv;
    te[7] = (n21 * n13 - n23 * n11) * detInv;
    te[8] = (n22 * n11 - n21 * n12) * detInv;

    return this;
  }

  /// [Transposes](https://en.wikipedia.org/wiki/Transpose) this matrix in
  /// place.
  Matrix3 transpose() {
    double tmp;
    final m = storage;

    tmp = m[1];
    m[1] = m[3];
    m[3] = tmp;
    tmp = m[2];
    m[2] = m[6];
    m[6] = tmp;
    tmp = m[5];
    m[5] = m[7];
    m[7] = tmp;

    return this;
  }

  /// [m] - [Matrix4]
  /// 
  /// Sets this matrix as the upper left 3x3 of the
  /// [normal matrix](https://en.wikipedia.org/wiki/Normal_matrix) of the
  /// passed [matrix4]. 
  /// The normal matrix is the
  /// [inverse](https://en.wikipedia.org/wiki/Invertible_matrix)
  /// [transpose](https://en.wikipedia.org/wiki/Transpose) of the matrix
  /// [m].
  Matrix3 getNormalMatrix(Matrix4 matrix4) {
    return setFromMatrix4(matrix4).invert().transpose();
  }

  /// [array] - array to store the resulting vector in.
  /// 
  /// [Transposes](https://en.wikipedia.org/wiki/Transpose) this matrix into
  /// the supplied array, and returns itself unchanged.
  Matrix3 transposeIntoArray(List<double> r) {
    final m = storage;

    r[0] = m[0];
    r[1] = m[3];
    r[2] = m[6];
    r[3] = m[1];
    r[4] = m[4];
    r[5] = m[7];
    r[6] = m[2];
    r[7] = m[5];
    r[8] = m[8];

    return this;
  }

  /// [tx] - offset x
  /// 
  /// [ty] - offset y
  /// 
  /// [sx] - repeat x
  /// 
  /// [sy] - repeat y
  /// 
  /// [rotation] - rotation, in radians. Positive values rotate
  /// counterclockwise
  /// 
  /// [cx] - center x of rotation
  /// 
  /// [cy] - center y of rotation
  /// 
  /// Sets the UV transform matrix from offset, repeat, rotation, and center.
  Matrix3 setUvTransform(double tx, double ty, double sx, double sy, double rotation, double cx, double cy) {
    final c = math.cos(rotation);
    final s = math.sin(rotation);

    setValues(sx * c, sx * s, -sx * (c * cx + s * cy) + cx + tx, -sy * s, sy * c,
        -sy * (-s * cx + c * cy) + cy + ty, 0, 0, 1);

    return this;
  }

  /// Rotates this matrix by the given [theta] (in radians).
  Matrix3 rotate(double theta) {
    final c = math.cos(theta);
    final s = math.sin(theta);

    final te = storage;

    final a11 = te[0], a12 = te[3], a13 = te[6];
    final a21 = te[1], a22 = te[4], a23 = te[7];

    te[0] = c * a11 + s * a21;
    te[3] = c * a12 + s * a22;
    te[6] = c * a13 + s * a23;

    te[1] = -s * a11 + c * a21;
    te[4] = -s * a12 + c * a22;
    te[7] = -s * a13 + c * a23;

    return this;
  }

  /// Translates this matrix by the given scalar values.
  Matrix3 translate(double tx, double ty) {
    final te = storage;

    te[0] += tx * te[2];
    te[3] += tx * te[5];
    te[6] += tx * te[8];
    te[1] += ty * te[2];
    te[4] += ty * te[5];
    te[7] += ty * te[8];

    return this;
  }

  /// Return true if this matrix and [page:Matrix3 m] are equal.
  bool equals(Matrix3 matrix) {
    final te = storage;
    final me = matrix.storage;

    for (int i = 0; i < 9; i++) {
      if (te[i] != me[i]) return false;
    }

    return true;
  }
  Matrix3 factory(NativeArray array, {int offset = 0}) {
    for (int i = 0; i < 9; i++) {
      storage[i] = array[i + offset].toDouble();
    }

    return this;
  }
  
  /// [array] - the array to read the elements from.
  /// 
  /// [offset] - (optional) index of first element in the array.
  /// Default is `0`.
  /// 
  /// Sets the elements of this matrix based on an array in
  /// [column-major](https://en.wikipedia.org/wiki/Row-_and_column-major_order#Column-major_order) format.
  Matrix3 copyFromArray(List<double> array, {int offset = 0}) {
    for (int i = 0; i < 9; i++) {
      storage[i] = array[i + offset];
    }

    return this;
  }

  /// [array] - (optional) array to store the resulting vector in. If
  /// not given a new array will be created.
  /// 
  /// [offset] - (optional) offset in the array at which to put the
  /// result.
  /// 
  /// Writes the elements of this matrix to an array in
  /// [column-major](https://en.wikipedia.org/wiki/Row-_and_column-major_order#Column-major_order) format.
  List<double> toArray(List<double> array, {int offset = 0}) {
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

    return array;
  }

  List<double> toList() {
    return storage.sublist(0);
  }

  Matrix3.fromJson(Map<String, dynamic> json) {
    storage = json['storage'];
  }

  Map<String, dynamic> toJson() {
    return {'storage': storage};
  }
}
