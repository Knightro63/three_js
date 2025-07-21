import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';

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
  Float32Array? _buffer;
  Float32Array? get buffer => _buffer;

	Buffer(super.name,[Float32Array? buffer]) {
		_buffer = buffer;
	}

	int get byteLength => getFloatLength(_buffer?.byteLength );

	bool update() {
		return true;
	}
}
