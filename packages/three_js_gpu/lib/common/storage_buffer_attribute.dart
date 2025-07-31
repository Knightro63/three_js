import "package:three_js_math/three_js_math.dart";

class StorageBufferAttribute extends BufferAttribute {
  StorageBufferAttribute(super.array, super.itemSize );

	factory StorageBufferAttribute.create(int count, int itemSize, [Type typeClass = Float32Array]) {
    late final NativeArray data;

    if (typeClass == Int8Array) {
      data = Int8Array(count*itemSize);
    } 
    else if (typeClass == Uint8Array) {
      data = Uint8Array(count*itemSize);
    } 
    else if (typeClass == Int16Array) {
      data = Int16Array(count*itemSize);
    } 
    else if (typeClass == Uint16Array) {
      data = Uint16Array(count*itemSize);
    } 
    else if (typeClass == Int32Array) {
      data = Int32Array(count*itemSize);
    } 
    else if (typeClass == Uint32Array) {
      data = Uint32Array(count*itemSize);
    } 
    else if (typeClass == Float32Array) {
      data = Float32Array(count*itemSize);
    } 

    return StorageBufferAttribute(data, itemSize);
	}
}