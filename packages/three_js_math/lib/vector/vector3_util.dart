import '../native-array/native_array.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
import '../buffer/buffer_attribute.dart';

extension Vec3 on Vector3{
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

  Vector3 add2(Vector3 a, Vector3 b) {
    x = a.x + b.x;
    y = a.y + b.y;
    return this;
  }

  Vector3 sub2(Vector3 a, Vector3 b) {
    x = a.x - b.x;
    y = a.y - b.y;
    return this;
  }

  Vector3 cross2(Vector3 a, Vector3 b) {
    final ax = a.x, ay = a.y, az = a.z;
    final bx = b.x, by = b.y, bz = b.z;

    x = ay * bz - az * by;
    y = az * bx - ax * bz;
    z = ax * by - ay * bx;

    return this;
  }

  void fromNativeArray(NativeArray array, [int offset = 0]) {
    storage[2] = array[offset + 2].toDouble();
    storage[1] = array[offset + 1].toDouble();
    storage[0] = array[offset + 0].toDouble();
  }

  // Vector3 project(Camera camera) {
  //   applyMatrix4(camera.matrixWorldInverse);
  //   applyMatrix4(camera.projectionMatrix);
  //   return this;
  // }

  // Vector3 unproject(Camera camera) {
  //   applyMatrix4(camera.projectionMatrixInverse);
  //   applyMatrix4(camera.matrixWorld);
  //   return this;
  // }

  Vector3 applyNormalMatrix(Matrix3 m) {
    applyMatrix3(m);
    normalize();
    return this;
  }
  
  Vector3 transformDirection(Matrix4 m) {
    // input: THREE.Matrix4 affine matrix
    // vector interpreted as a direction

    final x = this.x, y = this.y, z = this.z;
    final e = m.storage;

    this.x = e[0] * x + e[4] * y + e[8] * z;
    this.y = e[1] * x + e[5] * y + e[9] * z;
    this.z = e[2] * x + e[6] * y + e[10] * z;
    normalize();
    return this;
  }

  Vector3 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();
    z = attribute.getZ(index)!.toDouble();

    return this;
  }

  Vector3 lerp(Vector3 v, double alpha) {
    x += (v.x - x) * alpha;
    y += (v.y - y) * alpha;
    z += (v.z - z) * alpha;

    return this;
  }

  bool equals(Vector3 v) {
    return (v.x == x) && (v.y == y) && (v.z == z);
  }

  Vector3 setFromMatrixColumn(Matrix4 m, int index) {
    copyFromArray(m.storage, index * 4);
    return this;
  }
  Vector3 setFromMatrixPosition(Matrix4 m) {
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
}