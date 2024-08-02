import 'dart:html';
import "dart:typed_data";
// import "package:three_js_core/three_js_core.dart";
// import "package:three_js_math/buffer/buffer_attribute.dart";
// import "package:three_js_math/three_js_math.dart";

bool areSharedArrayBuffersSupported() {
  // return SharedArrayBuffer != null;
  return false;
  // Dart does not natively support SharedArrayBuffer. the statement above
  // will always return False
}

TypedData convertToSharedArrayBuffer(TypedData array) {
  if (array.buffer is SharedArrayBuffer) {
    return array;
  }

  //final cons = array.runtimeType;
  final buffer = array.buffer;
  final sharedBuffer = SharedArrayBuffer(buffer.lengthInBytes);

  final uintArray = Uint8List.view(buffer);
  final sharedUintArray = Uint8List.view(sharedBuffer as ByteBuffer);
  sharedUintArray.setAll(0, uintArray);

  //return cons(sharedBuffer);
  if (array is Uint8List) {
    return Uint8List.view(sharedBuffer as ByteBuffer);
  } else if (array is Uint16List) {
    return Uint16List.view(sharedBuffer as ByteBuffer);
  } else if (array is Uint32List) {
    return Uint32List.view(sharedBuffer as ByteBuffer);
  } else {
    throw UnsupportedError('TypedData type not supported');
  }
}

getIndexArray(int vertexCount, [Type BufferConstructor = ArrayBuffer]) {
  if (vertexCount > 65535) {
    return Uint32List(vertexCount);
  } else {
    return Uint16List(vertexCount);
  }
}

void ensureIndex(dynamic geo, {bool useSharedArrayBuffer = false}) {
  if (geo.index == null) {
    final vertexCount = geo.attributes['position'].count;
    final BufferConstructor = useSharedArrayBuffer ? SharedArrayBuffer : ArrayBuffer;
    final index = getIndexArray(vertexCount, BufferConstructor);
    geo.setIndex(index);

    // if (vertexCount > 65535) {
    //   Uint32List myIndex = Uint32List(vertexCount);
    //   for (int i = 0; i < vertexCount; i++) {
    //     myIndex[i] = i;
    //   }
    // }

    for (int i = 0; i < vertexCount; i++) {
      index[i] = i;
    }
  }
}

int getVertexCount(dynamic geo) {
  return geo.index != null ? geo.index.length : geo.attributes['position'].count;
}

int getTriCount(dynamic geo) {
  return getVertexCount(geo) ~/ 3;
}
