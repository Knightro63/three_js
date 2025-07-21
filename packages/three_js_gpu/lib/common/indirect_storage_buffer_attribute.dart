import "./storage_buffer_attribute.dart";

class IndirectStorageBufferAttribute extends StorageBufferAttribute {
	IndirectStorageBufferAttribute( count, itemSize ):super( count, itemSize, Uint32Array );
}