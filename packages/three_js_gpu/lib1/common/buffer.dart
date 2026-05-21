import 'dart:typed_data';
import './binding.dart';
import './buffer_utils.dart';

/**
 * Represents a buffer binding type.
 *
 * @private
 * @abstract
 * @augments Binding
 */
class Buffer extends Binding {
  int bytesPerElement = Float32List.bytesPerElement;
  Float32List? _buffer;
  Float32List? get buffer => _buffer;

	Buffer(super.name, [Float32List? buffer]) {
		_buffer = buffer;
	}

	int get byteLength => getFloatLength(_buffer?.lengthInBytes );

	bool update() {
		return true;
	}
}
