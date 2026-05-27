import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart' as core;
import './storage_buffer_attribute.dart'; // Holds your StorageBufferAttribute class definition

/// This special type of buffer attribute is intended for compute shaders.
/// It can be used to encode draw parameters for indirect draw calls.
///
/// Note: This type of buffer attribute can only be used with `WebGPURenderer`
/// and a WebGPU backend.
class IndirectStorageBufferAttribute extends StorageBufferAttribute {
  /// This flag can be used for type testing.
  final bool isIndirectStorageBufferAttribute = true;

  /// Constructs a new indirect storage buffer attribute container layout.
  /// 
  /// [count] - The item count or an explicit backing [Uint32List] buffer.
  /// [itemSize] - The dimensional structural size per element item.
  IndirectStorageBufferAttribute(dynamic count, int itemSize) 
      : super(count, itemSize, Uint32List);
}
