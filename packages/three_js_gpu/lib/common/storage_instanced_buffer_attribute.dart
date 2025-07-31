import "package:three_js_math/three_js_math.dart";

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {
  StorageInstancedBufferAttribute(super.array, super.itemSize);
	factory StorageInstancedBufferAttribute.create( int count, int itemSize) {
    return StorageInstancedBufferAttribute(Float32Array( count * itemSize ),itemSize);
	}
}