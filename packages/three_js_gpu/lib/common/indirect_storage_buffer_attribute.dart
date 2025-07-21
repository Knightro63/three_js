import "./storage_buffer_attribute.dart";
import 'package:three_js_math/three_js_math.dart';

class IndirectStorageBufferAttribute extends StorageBufferAttribute {
	IndirectStorageBufferAttribute(super.array, super.itemSize );
  factory IndirectStorageBufferAttribute.create( count, itemSize, type ){
    return StorageBufferAttribute.create();
  }
}