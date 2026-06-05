import "dart:typed_data";
import 'package:three_js_math/three_js_math.dart';

class StorageBufferAttribute extends BufferAttribute {
  StorageBufferAttribute(super.array, super.itemSize );

	factory StorageBufferAttribute.create(int count, int itemSize, [Type typeClass = Float32List]) {
    late final TypedDataList data;

    if (typeClass == Int8List) {
      data = Int8List(count*itemSize);
    } 
    else if (typeClass == Uint8List) {
      data = Uint8List(count*itemSize);
    } 
    else if (typeClass == Int16List) {
      data = Int16List(count*itemSize);
    } 
    else if (typeClass == Uint16List) {
      data = Uint16List(count*itemSize);
    } 
    else if (typeClass == Int32List) {
      data = Int32List(count*itemSize);
    } 
    else if (typeClass == Uint32List) {
      data = Uint32List(count*itemSize);
    } 
    else if (typeClass == Float32List) {
      data = Float32List(count*itemSize);
    } 

    return StorageBufferAttribute(data, itemSize);
	}
}