import 'dart:typed_data';
import './binding.dart';
import './buffer_utils.dart';

/// Represents a buffer binding type.
abstract class Buffer extends Binding {
  /// This flag can be used for type testing.
  final bool isBuffer = true;

  /// The bytes per element. Defaults to Float32List.elementSizeInBytes (4 bytes).
  int bytesPerElement = Float32List.bytesPerElement;

  /// A reference to the internal buffer memory tracking list.
  Float32List? _buffer;
  Float32List? get buffer => _buffer;
  set buffer(Float32List? buffer){
    _buffer = buffer;
  }

  /// An array list of update ranges.
  final List<Map<String, int>> _updateRanges = [];

  /// Constructs a new buffer mapping layout module.
  /// 
  /// [name] - The buffer's name.
  /// [buffer] - The internal typed array list payload.
  Buffer(super.name, [this._buffer = null]);

  /// The array list of update ranges.
  List<Map<String, int>> get updateRanges => this._updateRanges;

  /// Adds an update range.
  /// 
  /// [start] - The start element index position.
  /// [count] - The number of elements to flag as dirty.
  void addUpdateRange(int start, int count) {
    this._updateRanges.add({
      'start': start,
      'count': count
    });
  }

  /// Clears all update ranges.
  void clearUpdateRanges() {
    // Replaces JavaScript array length reset trick (updateRanges.length = 0)
    this._updateRanges.clear();
  }

  /// The buffer's byte length.
  int get byteLength {
    if (this._buffer == null) return 0;
    
    // Extracted directly using the shared hardware buffer utility functions
    final int rawByteLength = (this._buffer is TypedData) 
        ? (this._buffer as TypedData).lengthInBytes 
        : 0;
        
    return getFloatLength(rawByteLength);
  }
  
  /// Updates the binding state metrics.
  /// 
  /// Returns `true` if the buffer has been modified and must be uploaded to the GPU.
  bool update() {
    return true;
  }

  /// Releases the backing CPU memory buffers.
  void release() {
    this._buffer = null;
  }
}
