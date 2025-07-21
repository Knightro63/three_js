import "package:three_js_math/three_js_math.dart";

class StorageBufferAttribute extends BufferAttribute {
  StorageBufferAttribute(super.array, super.itemSize );

	factory StorageBufferAttribute.create(count, itemSize) {
		final array = ArrayBuffer.isView( count ) ? count : Float32Array( count * itemSize );
    return StorageBufferAttribute(array, itemSize);
	}
}