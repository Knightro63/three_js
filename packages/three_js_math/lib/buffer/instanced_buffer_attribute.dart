import 'buffer_attribute.dart';

/// An instanced version of [BufferAttribute].
class InstancedBufferAttribute extends BufferAttribute {
  late int meshPerAttribute;

  /// [InstancedBufferAttribute] ([array], [itemSize], [normalized], [meshPerAttribute] )
  InstancedBufferAttribute(super.array, super.itemSize, [super.normalized = false, this.meshPerAttribute = 1]){
    type = "InstancedBufferAttribute";
  }

  @override
  BufferAttribute copy(BufferAttribute source) {
    super.copy(source);
    if (source is InstancedBufferAttribute) {
      meshPerAttribute = source.meshPerAttribute;
    }
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    final result = super.toJson();
    result['meshPerAttribute'] = meshPerAttribute;
    result['isInstancedBufferAttribute'] = true;
    return result;
  }
}
