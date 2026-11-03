import 'dart:typed_data';

class TypedArrayHelper {
  TypedArrayHelper._();

  static String getArrayType(TypedDataList data) {
    if (data is Uint8List) return 'Uint8List';
    if (data is Uint16List) return 'Uint16List';
    if (data is Uint32List) return 'Uint32List';
    if (data is Float32List) return 'Float32List';

    throw UnsupportedError('Unsupported typed array');
  }
}
