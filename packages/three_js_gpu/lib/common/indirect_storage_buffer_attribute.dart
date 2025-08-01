import "./storage_buffer_attribute.dart";

class IndirectStorageBufferAttribute extends StorageBufferAttribute {
	IndirectStorageBufferAttribute(super.array, super.itemSize );
  factory IndirectStorageBufferAttribute.create( count, itemSize, type ){
    return StorageBufferAttribute.create();
  }
}