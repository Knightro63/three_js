import 'dart:typed_data';
// import 'package:three_js_math/buffer/buffer_attribute.dart';
import 'utils/geometry_utils.dart';
import 'dart:html';

int ceilToFourByteStride(int byteLength) {
  byteLength = byteLength.toInt();
  return byteLength + 4 - byteLength % 4;
}

// Make a new array wrapper class that more easily affords expansion when reaching it's max capacity
class TypeBackedArray {
  // late double expansionFactor;
  // late Type type;
  // late int initialSize = 0;
  // late int length;
  // late var array;

  // TypeBackedArray(this.type, {initialSize = 500}) {
  //   expansionFactor = 1.5;
  //   type = type;
  //   length = 0;
  //   array = <dynamic>[null];

  //   setSize(initialSize);
  // }

  double expansionFactor;
  Type type;
  int length;
  var array;

  TypeBackedArray(this.type, [int initialSize = 500])
      : expansionFactor = 1.5,
        length = 0,
        array = null {
    setSize(initialSize);
  }

  void setType(type) {
    if (length != 0) {
      throw Exception('TypeBackedArray: Cannot change the type while there is used data in the buffer.');
    }

    var buffer = array.buffer;

    if (type == Float32List) {
      array = Float32List.view(buffer);
    } else if (type == Int32List) {
      array = Int32List.view(buffer);
    } else {
      throw Exception('Unsupported type');
    }

    this.type = type;
  }

  void setSize(int size) {
    if (array == true && size == array.length) {
      return;
    }

    // ceil to the nearest 4 bytes so we can replace the array with any type using the same buffer
    var type = this.type;
    var bufferType = areSharedArrayBuffersSupported() ? SharedArrayBuffer : ArrayBuffer;
    var newArray;

    if (type == Float32List) {
      newArray = bufferType(Float32List(ceilToFourByteStride(size * Float32List.bytesPerElement)));
    } else if (type == Int32List) {
      newArray = bufferType(Int32List(ceilToFourByteStride(size * Int32List.bytesPerElement)));
    } else {
      throw Exception('Unsupported type');
    }

    if (array == true) {
      newArray.setRange(array, 0);
    }

    array = newArray;
  }

  void expand() {
    setSize((array.length * expansionFactor).toInt());
  }

  void push(List<num> args) {
    array = array;
    length = length;

    if (length + args.length > array.length) {
      expand();
      array = array;
    }

    for (var i = 0; i < args.length; i++) {
      if (array is Float32List) {
        (array as Float32List)[length + i] = args[i] as double;
      } else if (array is Int32List) {
        (array as Int32List)[length + i] = args[i] as int;
      }
    }

    length += args.length;
  }

  clear() {
    length = 0;
  }
}
