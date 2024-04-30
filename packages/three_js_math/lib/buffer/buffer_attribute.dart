import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';

abstract class BufferAttribute<TData extends NativeArray> extends BaseBufferAttribute<TData> {
  final _vector = Vector3.zero();
  final _vector2 = Vector2.zero();

  bool isBufferAttribute = true;

  BufferAttribute(TData arrayList, int itemSize, [bool normalized = false]) {
    type = "BufferAttribute";
    array = arrayList;
    this.itemSize = itemSize;
    count = arrayList.length ~/ itemSize;
    this.normalized = normalized == true;

    usage = StaticDrawUsage;
    updateRange = {"offset": 0, "count": -1};

    version = 0;
  }

  int get length => count;

  set needsUpdate(bool value) {
    if (value == true) version++;
  }

  BufferAttribute setUsage(int value) {
    usage = value;

    return this;
  }

  BufferAttribute copy(BufferAttribute source) {
    name = source.name;
    itemSize = source.itemSize;
    count = source.count;
    normalized = source.normalized;
    type = source.type;
    usage = source.usage;
    array.copy(source.array);
    return this;
  }

  BufferAttribute copyAt(int index1, BufferAttribute attribute, int index2) {
    index1 *= itemSize;
    index2 *= attribute.itemSize;

    for (int i = 0, l = itemSize; i < l; i++) {
      array[index1 + i] = attribute.array[index2 + i];
    }

    return this;
  }

  BufferAttribute copyArray(TData array) {
    this.array = array;
    return this;
  }

  BufferAttribute copyColorsArray(List<Color> colors) {
    final array = this.array;
    int offset = 0;

    for (int i = 0, l = colors.length; i < l; i++) {
      final color = colors[i];
      array[offset++] = color.red;
      array[offset++] = color.green;
      array[offset++] = color.blue;
    }

    return this;
  }

  BufferAttribute copyVector2sArray(List<Vector2> vectors) {
    final array = this.array;
    int offset = 0;

    for (int i = 0, l = vectors.length; i < l; i++) {
      final vector = vectors[i];
      array[offset++] = vector.x;
      array[offset++] = vector.y;
    }

    return this;
  }

  BufferAttribute copyVector3sArray(List<Vector3> vectors) {
    final array = this.array;
    int offset = 0;

    for (int i = 0, l = vectors.length; i < l; i++) {
      final vector = vectors[i];
      array[offset++] = vector.x;
      array[offset++] = vector.y;
      array[offset++] = vector.z;
    }

    return this;
  }

  BufferAttribute copyVector4sArray(List<Vector4> vectors) {
    final array = this.array;
    int offset = 0;

    for (int i = 0, l = vectors.length; i < l; i++) {
      final vector = vectors[i];
      array[offset++] = vector.x;
      array[offset++] = vector.y;
      array[offset++] = vector.z;
      array[offset++] = vector.w;
    }

    return this;
  }

  BufferAttribute applyMatrix3(Matrix3 m) {
    if (itemSize == 2) {
      for (int i = 0, l = count; i < l; i++) {
        _vector2.fromBuffer(this, i);
        _vector2.applyMatrix3(m);

        setXY(i, _vector2.x, _vector2.y);
      }
    } else if (itemSize == 3) {
      for (int i = 0, l = count; i < l; i++) {
        _vector.fromBuffer(this, i);
        _vector.applyMatrix3(m);

        setXYZ(i, _vector.x, _vector.y, _vector.z);
      }
    }

    return this;
  }

  void applyMatrix4(Matrix4 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );

      _vector.applyMatrix4(m);

      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }

  BufferAttribute applyNormalMatrix(Matrix3 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );

      _vector.applyNormalMatrix(m);

      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  BufferAttribute transformDirection(Matrix4 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.x = getX(i)!;
      _vector.y = getY(i)!;
      _vector.z = getZ(i)!;

      _vector.transformDirection(m);

      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  BufferAttribute set(value, {int offset = 0}) {
    array[offset] = value;

    return this;
  }

  double? getX(int index) {
    return getAt(index * itemSize);
  }

  BufferAttribute setX(int index, int x) {
    array[index * itemSize] = x;

    return this;
  }

  double? getY(int index) {
    return getAt(index * itemSize + 1);
  }

  BufferAttribute setY(int index, int y) {
    array[index * itemSize + 1] = y;

    return this;
  }

  double? getZ(int index) {
    return getAt(index * itemSize + 2);
  }

  BufferAttribute setZ(int index, int z) {
    array[index * itemSize + 2] = z;

    return this;
  }

  double? getW(int index) {
    return getAt(index * itemSize + 3);
  }

  double? getAt(int index) {
    if (index < array.length) {
      return array[index].toDouble();
    } else {
      return null;
    }
  }

  BufferAttribute setW(int index, double w) {
    array[index * itemSize + 3] = w;

    return this;
  }

  BufferAttribute setXY(int index, double x, double y) {
    index *= itemSize;

    array[index + 0] = x;
    array[index + 1] = y;

    return this;
  }

  void setXYZ(int index, double x, double y, double z) {
    int idx = index * itemSize;

    array[idx + 0] = x.toDouble();
    array[idx + 1] = y.toDouble();
    array[idx + 2] = z.toDouble();
  }

  BufferAttribute setXYZW(int index, num x, num y, num z, num w) {
    index *= itemSize;

    array[index + 0] = x;
    array[index + 1] = y;
    array[index + 2] = z;
    array[index + 3] = w;

    return this;
  }

  BufferAttribute onUpload(void Function()? callback) {
    onUploadCallback = callback;

    return this;
  }

  BufferAttribute clone() {
    // if (type == "BufferAttribute") {
    //   return BufferAttribute(array, itemSize, false).copy(this);
    // } else
    if (type == "Float32BufferAttribute") {
      final typed = array as Float32Array;
      return Float32BufferAttribute(Float32Array(typed.length), itemSize, false).copy(this);
    } else if (type == "Uint8BufferAttribute") {
      final typed = array as Uint8Array;
      return Uint8BufferAttribute(Uint8Array(typed.length), itemSize, false).copy(this);
    } else if (type == "Uint16BufferAttribute") {
      final typed = array as Uint16Array;
      return Uint16BufferAttribute(Uint16Array(typed.length), itemSize, false).copy(this);
    } else {
      throw ("BufferAttribute type: $type clone need support ....  ");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      "itemSize": itemSize,
      "type": array.runtimeType.toString(), //.replaceAll('List', 'Array'),
      "array": array.sublist(0),
      "normalized": normalized
    };

    if (name != null) result["name"] = name;
    if (usage != StaticDrawUsage) result["usage"] = usage;
    if (updateRange?["offset"] != 0 || updateRange?["count"] != -1) {
      result["updateRange"] = updateRange;
    }

    return result;
  }
}

class Int8BufferAttribute extends BufferAttribute<Int8Array> {
  Int8BufferAttribute(super.array, super.itemSize, [super.normalized = false]){
    type = "Int8BufferAttribute";
  }
  factory Int8BufferAttribute.fromTypedData(Int8List list, int itemSize,[bool normalized = false]){
    return Int8BufferAttribute(Int8Array.fromList(list),itemSize,normalized);
  }
}

class Uint8BufferAttribute extends BufferAttribute<Uint8Array> {
  Uint8BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Uint8BufferAttribute";
  }
  factory Uint8BufferAttribute.fromTypedData(Uint8List list, int itemSize,[bool normalized = false]){
    return Uint8BufferAttribute(Uint8Array.fromList(list),itemSize,normalized);
  }
}

class Uint8ClampedBufferAttribute extends BufferAttribute<Uint8Array> {
  Uint8ClampedBufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Uint8ClampedBufferAttribute";
  }
}

class Int16BufferAttribute extends BufferAttribute<Int16Array> {
  Int16BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Int16BufferAttribute";
  }
  factory Int16BufferAttribute.fromTypedData(Int16List list, int itemSize,[bool normalized = false]){
    return Int16BufferAttribute(Int16Array.fromList(list),itemSize,normalized);
  }
}

// Int16BufferAttribute.prototype = Object.create( BufferAttribute.prototype );
// Int16BufferAttribute.prototype.constructor = Int16BufferAttribute;

class Uint16BufferAttribute extends BufferAttribute<Uint16Array> {
  Uint16BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Uint16BufferAttribute";
  }
  factory Uint16BufferAttribute.fromTypedData(Uint16List list, int itemSize,[bool normalized = false]){
    return Uint16BufferAttribute(Uint16Array.fromList(list),itemSize,normalized);
  }
}

class Int32BufferAttribute extends BufferAttribute<Int32Array> {
  Int32BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Int32BufferAttribute";
  }
  factory Int32BufferAttribute.fromTypedData(Int32List list, int itemSize,[bool normalized = false]){
    return Int32BufferAttribute(Int32Array.fromList(list),itemSize,normalized);
  }
}

class Uint32BufferAttribute extends BufferAttribute<Uint32Array> {
  Uint32BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Uint32BufferAttribute";
  }
  factory Uint32BufferAttribute.fromTypedData(Uint32List list, int itemSize,[bool normalized = false]){
    return Uint32BufferAttribute(Uint32Array.fromList(list),itemSize,normalized);
  }
}

class Float16BufferAttribute extends BufferAttribute {
  Float16BufferAttribute(super.array, super.itemSize, [super.normalized = false]){
    type = "Float16BufferAttribute";
  }
  factory Float16BufferAttribute.fromTypedData(Float32List list, int itemSize,[bool normalized = false]){
    return Float16BufferAttribute(Float32Array.fromList(list),itemSize,normalized);
  }
}

class Float32BufferAttribute extends BufferAttribute<Float32Array> {
  Float32BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Float32BufferAttribute";
  }
  factory Float32BufferAttribute.fromTypedData(Float32List list, int itemSize,[bool normalized = false]){
    return Float32BufferAttribute(Float32Array.fromList(list),itemSize,normalized);
  }
}

class Float64BufferAttribute extends BufferAttribute<Float64Array> {
  Float64BufferAttribute(super.array, super.itemSize,[super.normalized = false]){
    type = "Float64BufferAttribute";
  }
  factory Float64BufferAttribute.fromTypedData(Float32List list, int itemSize,[bool normalized = false]){
    return Float64BufferAttribute(Float64Array.fromList(list),itemSize,normalized);
  }
}
