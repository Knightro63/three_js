import 'package:vector_math/vector_math.dart';
import '../buffer/buffer_attribute.dart';

extension Vec4 on Vector4{
  double manhattanLength() {
    return (x.abs() + y.abs() + z.abs() + w.abs());
  }

  Vector4 fromBuffer(BufferAttribute attribute, int index) {
    x = attribute.getX(index)!.toDouble();
    y = attribute.getY(index)!.toDouble();
    z = attribute.getZ(index)!.toDouble();
    w = (attribute.getW(index) ?? 0).toDouble();

    return this;
  }

  bool equals(Vector4 v) {
    return (v.x == x) && (v.y == y) && (v.z == z) && (v.w == w);
  }
}