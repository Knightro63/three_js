import "package:three_js_gpu/common/buffer.dart";

///
/// Represents a uniform buffer binding type.
///
class UniformBuffer extends Buffer {
	UniformBuffer(String name, [super.buffer]){
    this.name = name;
  }
}
