import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';

/// This class stores data for an attribute (such as vertex positions, face
/// indices, normals, colors, UVs, and any custom attributes ) associated with
/// a [BufferGeometry], which allows for more efficient passing of data
/// to the GPU. See that page for details and a usage example. When working
/// with vector-like data, the <i>.fromBufferAttribute( attribute, index )</i>
/// helper methods on [Vector2],
/// [Vector3],
/// [Vector4], and
/// [Color] classes may be helpful.
abstract class BufferAttribute<TData extends NativeArray> extends BaseBufferAttribute<TData> {
  final _vector = Vector3.zero();
  final _vector2 = Vector2.zero();

  bool isBufferAttribute = true;

  /// [array] -- Must be a
  /// [TypedArray](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/TypedArray). Used to instantiate the buffer.
  /// 
  /// This array should have
  /// ```
  /// itemSize * numVertices
  /// ```
  /// elements, where numVertices is the number of vertices in the associated
  /// [BufferGeometry].
  /// 
  /// [itemSize] -- the number of values of the array that should
  /// be associated with a particular vertex. For instance, if this attribute is
  /// storing a 3-component vector (such as a position, normal, or color), then
  /// itemSize should be 3.
  ///
  /// [normalized] -- (optional) Applies to integer data only.
  /// Indicates how the underlying data in the buffer maps to the values in the
  /// GLSL code. For instance, if [array] is an instance of
  /// UInt16Array, and [normalized] is true, the values `0 -
  /// +65535` in the array data will be mapped to 0.0f - +1.0f in the GLSL
  /// attribute. An Int16Array (signed) would map from -32768 - +32767 to -1.0f
  /// - +1.0f. If [normalized] is false, the values will be
  /// converted to floats unmodified, i.e. 32767 becomes 32767.0f.
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

  /// Copies another BufferAttribute to this BufferAttribute.
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

  /// Copy a vector from bufferAttribute[index2] to array[index1].
  BufferAttribute copyAt(int index1, BufferAttribute attribute, int index2) {
    index1 *= itemSize;
    index2 *= attribute.itemSize;

    for (int i = 0, l = itemSize; i < l; i++) {
      array[index1 + i] = attribute.array[index2 + i];
    }

    return this;
  }
  
  /// Copy the array given here (which can be a normal array or TypedArray) into
  /// [array].
  /// 
  /// See
  /// [TypedArray.set](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/set) for notes on requirements if copying a TypedArray.
  BufferAttribute copyArray(TData array) {
    this.array = array;
    return this;
  }

  /// Copy the [Color] array given here into [array].
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

  /// Copy the [Vector2] array given here into [array].
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

  /// Copy the [Vector3] array given here into [array].
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

  /// Copy the [Vector4] array given here into [array].
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

  /// Applies matrix [m] to every Vector3 element of this
  /// BufferAttribute.
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

  /// Applies matrix [m] to every Vector3 element of this
  /// BufferAttribute.
  void applyMatrix4(Matrix4 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );

      _vector.applyMatrix4(m);

      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }

  /// Applies normal matrix [m] to every Vector3 element of this
  /// BufferAttribute.
  BufferAttribute applyNormalMatrix(Matrix3 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );

      _vector.applyNormalMatrix(m);

      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  /// Applies matrix [m] to every Vector3 element of this
  /// BufferAttribute, interpreting the elements as a direction vectors.
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

  /// [value] - an [List] or [TypedData from which to copy values.
  ///
  /// [offset] - (optional) index of the [array] at
  /// which to start copying.
  /// 
  /// Calls
  /// [TypedArray.set](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/set)( [value], [offset] ) on the
  /// [array].
  /// 
  /// In particular, see that page for requirements on [value] being
  /// a [TypedData].
  BufferAttribute set(value, {int offset = 0}) {
    array[offset] = value;

    return this;
  }

  /// Returns the x component of the vector at the given index.
  double? getX(int index) {
    return getAt(index * itemSize);
  }

  /// Sets the x component of the vector at the given index.
  BufferAttribute setX(int index, num x) {
    array[index * itemSize] = x;

    return this;
  }

  /// Returns the y component of the vector at the given index.
  double? getY(int index) {
    return getAt(index * itemSize + 1);
  }

  /// Sets the y component of the vector at the given index.
  BufferAttribute setY(int index, num y) {
    array[index * itemSize + 1] = y;

    return this;
  }

  /// Returns the z component of the vector at the given index.
  double? getZ(int index) {
    return getAt(index * itemSize + 2);
  }

  /// Sets the z component of the vector at the given index.
  BufferAttribute setZ(int index, num z) {
    array[index * itemSize + 2] = z;

    return this;
  }

  /// Returns the w component of the vector at the given index.
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

  /// Sets the w component of the vector at the given index.
  BufferAttribute setW(int index, double w) {
    array[index * itemSize + 3] = w;

    return this;
  }

  /// Sets the x and y components of the vector at the given index.
  BufferAttribute setXY(int index, double x, double y) {
    index *= itemSize;

    array[index + 0] = x;
    array[index + 1] = y;

    return this;
  }

  /// Sets the x, y and z components of the vector at the given index.
  void setXYZ(int index, double x, double y, double z) {
    int idx = index * itemSize;

    array[idx + 0] = x.toDouble();
    array[idx + 1] = y.toDouble();
    array[idx + 2] = z.toDouble();
  }

  /// Sets the x, y, z and w components of the vector at the given index.
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

  /// Return a copy of this bufferAttribute.
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
