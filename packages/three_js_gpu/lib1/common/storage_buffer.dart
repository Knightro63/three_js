import "dart:typed_data";

import "package:three_js_math/three_js_math.dart";
import "./buffer.dart";

class StorageBuffer extends Buffer {
	StorageBuffer(String name, BufferAttribute? attribute ):super( name, attribute != null? attribute.array as Float32List : null );
}