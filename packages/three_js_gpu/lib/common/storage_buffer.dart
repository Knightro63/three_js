import "package:three_js_math/three_js_math.dart" hide Buffer;
import "./buffer.dart";

class StorageBuffer extends Buffer {
	StorageBuffer(String name, BufferAttribute? attribute ):super( name, attribute != null? attribute.array as Float32Array : null );
}