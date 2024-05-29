import 'dart:typed_data';
import 'dart:math' as math;

abstract class NativeArray<T extends num>{
  TypedData get data;
  ByteBuffer get buffer => data.buffer;
  int get bytesLength => length * oneByteSize;

  NativeArray(int size) : _size = size;
  NativeArray.fromList(List<T> listData) : _size = listData.length;

  List<T> toDartList();

  void dispose() {}

  T operator [](int index) {
    return toDartList()[index];
  }

  void operator []=(int index, T value) {
    toDartList()[index] = value;
  }

  late int _size;
  late int oneByteSize;
  int get length => _size;
  int get lengthInBytes => length * oneByteSize;

  int get byteLength => lengthInBytes;
  int get len => length;
  int get butesPerElement => oneByteSize;
  
  bool disposed = false;

  List<T> toJson() => toDartList();

  List<T> sublist(int start, [int? end]) => toDartList().sublist(start, end);
  
  NativeArray set(List<T> newList, [int index = 0]) {
    toDartList().setAll(index, newList.sublist(0, math.min(newList.length, length)));
    return this;
  }

  NativeArray clone();

  void copy(NativeArray source) {
    set(source.toDartList() as List<T>);
  }
}

class Float32Array extends NativeArray<double> {
  late Float32List _list;

  @override
  Float32List get data => _list;

  Float32Array(int size) : super(size) {
    _list = Float32List(size);
    oneByteSize = Float32List.bytesPerElement;
  }

  Float32Array.fromList(List<double> listData) : super.fromList(listData) {
    _list = Float32List.fromList(listData);
    oneByteSize = Float32List.bytesPerElement;
  }

  @override
  Float32Array clone() {
    return Float32Array.fromList(_list);
  }

  @override
  List<double> toDartList() => _list;

  // setAt(newList, int index) {
  //   this
  //       .toDartList()
  //       .setAll(index, List<double>.from(newList.map((e) => e.toDouble())));
  //   return this;
  // }
}

class Uint16Array extends NativeArray<int> {
  late Uint16List _list;

  @override
  Uint16List get data => _list;

  Uint16Array(int size) : super(size) {
    _list = Uint16List(size);
    oneByteSize = Uint16List.bytesPerElement;
  }
  Uint16Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Uint16List.fromList(listData);
    oneByteSize = Uint16List.bytesPerElement;
  }

  @override
  Uint16Array clone() {
    return Uint16Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Uint32Array extends NativeArray<int> {
  late Uint32List _list;

  @override
  Uint32List get data => _list;

  Uint32Array(int size) : super(size) {
    _list = Uint32List(size);
    oneByteSize = Uint32List.bytesPerElement;
  }
  Uint32Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Uint32List.fromList(listData);
    oneByteSize = Uint32List.bytesPerElement;
  }

  @override
  Uint32Array clone() {
    return Uint32Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Int8Array extends NativeArray<int> {
  late Int8List _list;

  @override
  Int8List get data => _list;

 Int8Array(int size) : super(size) {
    _list = Int8List(size);
    oneByteSize = Int8List.bytesPerElement;
  }

 Int8Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Int8List.fromList(listData);
    oneByteSize = Int8List.bytesPerElement;
  }

  @override
 Int8Array clone() {
    return Int8Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Int16Array extends NativeArray<int> {
  late Int16List _list;

  @override
  Int16List get data => _list;

 Int16Array(int size) : super(size) {
    _list = Int16List(size);
    oneByteSize = Int16List.bytesPerElement;
  }

 Int16Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Int16List.fromList(listData);
    oneByteSize = Int16List.bytesPerElement;
  }

  @override
 Int16Array clone() {
    return Int16Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Int32Array extends NativeArray<int> {
  late Int32List _list;

  @override
  Int32List get data => _list;

 Int32Array(int size) : super(size) {
    _list = Int32List(size);
    oneByteSize = Int32List.bytesPerElement;
  }

 Int32Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Int32List.fromList(listData);
    oneByteSize = Int32List.bytesPerElement;
  }

  @override
 Int32Array clone() {
    return Int32Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Uint8Array extends NativeArray<int> {
  late Uint8List _list;

  @override
  Uint8List get data => _list;

  Uint8Array(int size) : super(size) {
    _list = Uint8List(size);
    oneByteSize = Uint8List.bytesPerElement;
  }

  Uint8Array.fromList(List<int> listData) : super.fromList(listData) {
    _list = Uint8List.fromList(listData);
    oneByteSize = Uint8List.bytesPerElement;
  }

  @override
  Uint8Array clone() {
    return Uint8Array.fromList(_list);
  }

  @override
  List<int> toDartList() => _list;
}

class Float64Array extends NativeArray<double> {
  late Float64List _list;

  @override
  Float64List get data => _list;

  Float64Array(int size) : super(size) {
    _list = Float64List(size);
    oneByteSize = Float64List.bytesPerElement;
  }

  Float64Array.fromList(List<double> listData) : super.fromList(listData) {
    _list = Float64List.fromList(listData);
    oneByteSize = Float64List.bytesPerElement;
  }

  @override
  Float64Array clone() {
    return Float64Array.fromList(_list);
  }

  @override
  List<double> toDartList() => _list;
}
