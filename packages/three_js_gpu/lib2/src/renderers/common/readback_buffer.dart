import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';

/**
 * A readback buffer is used to transfer data from the GPU to the CPU.
 * It is primarily used to read back compute shader results.
 *
 * @augments EventDispatcher
 */
class ReadbackBuffer with EventDispatcher {
  String name = '';
  ByteBuffer? buffer;
  int maxByteLength;

	ReadbackBuffer(this.maxByteLength ):super();

	/**
	 * Releases the mapped buffer data so the GPU buffer can be
	 * used by the GPU again.
	 *
	 * Note: Any `ArrayBuffer` data associated with this readback buffer
	 * are removed and no longer accessible after calling this method.
	 */
	void release() {
		this.dispatchEvent(Event(type: 'release' ));
	}

	/**
	 * Frees internal resources.
	 */
	void dispose() {
		this.dispatchEvent(Event(type: 'dispose' ));
	}
}
