import "package:three_js_math/three_js_math.dart";
import 'dart:typed_data';

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {
  StorageInstancedBufferAttribute(super.array, super.itemSize);
	factory StorageInstancedBufferAttribute.create( int count, int itemSize) {
    return StorageInstancedBufferAttribute(Float32List( count * itemSize ),itemSize);
	}
}