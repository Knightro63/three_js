import 'package:flutter_gl/flutter_gl.dart';
import 'package:vector_math/vector_math.dart';
import '../buffer/buffer_attribute.dart';

extension Vec2 on Vector2{
  Vector2 applyMatrix3(Matrix3 m) {
    final x = this.x;
    final y = this.y;
    final e = m.storage;

    this.x = e[0] * x + e[3] * y + e[6];
    this.y = e[1] * x + e[4] * y + e[7];

    return this;
  }
  Vector2 sub2(Vector2 a, Vector2 b) {
    x = a.x - b.x;
    y = a.y - b.y;

    return this;
  }
  Vector2 addScalar(num s) {
    x += s;
    y += s;

    return this;
  }
  Vector2 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();

    return this;
  }

  void fromNativeArray(NativeArray array, [int offset = 0]) {
    storage[1] = array[offset + 1].toDouble();
    storage[0] = array[offset + 0].toDouble();
  }
}