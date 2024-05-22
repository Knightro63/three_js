import "dart:typed_data";

import "package:flutter_gl/flutter_gl.dart";
import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/buffer/buffer_attribute.dart";
import "package:three_js_math/three_js_math.dart";

 areSharedArrayBuffersSupported() {
	return SharedArrayBuffer != null;
}

 convertToSharedArrayBuffer(TypedData array ) {
	if ( array.buffer is SharedArrayBuffer ) {
		return array;
	}

	final cons = array.constructor;
	final buffer = array.buffer;
	final sharedBuffer = SharedArrayBuffer( buffer.byteLength );

	final uintArray = Uint8Array( buffer );
	final sharedUintArray = Uint8Array( sharedBuffer );
	sharedUintArray.copy(uintArray);

	return cons( sharedBuffer );
}

NativeArray getIndexArray(int vertexCount, {NativeArray? bufferConstructor}) {
	if ( vertexCount > 65535 ) {
    bufferConstructor!( 4 * vertexCount )!;
		return Uint32Array.from();
	} else {
		return Uint16Array( bufferConstructor( 2 * vertexCount ) );
	}
}

void ensureIndex(BufferGeometry geo, options ) {
	if (geo.index != null) {
		final vertexCount = geo.attributes['position'].count;
		final bufferConstructor = options.useSharedArrayBuffer ? SharedArrayBuffer : ArrayBuffer;
		final index = getIndexArray( vertexCount, bufferConstructor: bufferConstructor);
		geo.setIndex( Uint16BufferAttribute( (index as Uint16Array), 1 ) );

		for (int i = 0; i < vertexCount; i ++ ) {
			index[ i ] = i;
		}
	}
}

int getVertexCount(BufferGeometry geo ) {
	return geo.index != null ? geo.index!.count : geo.attributes['position'].count;
}

int getTriCount(BufferGeometry geo ) {
	return getVertexCount( geo ) ~/ 3;
}