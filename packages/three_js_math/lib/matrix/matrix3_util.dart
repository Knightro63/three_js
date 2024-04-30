import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

extension Mat3 on Matrix3{
  Matrix3 setFromMatrix4(Matrix4 m) {
    final me = m.storage;
    setValues(me[0], me[4], me[8], me[1], me[5], me[9], me[2], me[6], me[10]);
    return this;
  }

  Matrix3 getNormalMatrix(Matrix4 matrix4) {
    setFromMatrix4(matrix4);
    invert();
    transpose();
    return this;
  }

  Matrix3 setUvTransform(num tx, num ty, num sx, num sy, num rotation, num cx, num cy) {
    final c = math.cos(rotation);
    final s = math.sin(rotation);

    setValues(sx * c, sx * s, -sx * (c * cx + s * cy) + cx + tx, -sy * s, sy * c,
        -sy * (-s * cx + c * cy) + cy + ty, 0, 0, 1);

    return this;
  }
}