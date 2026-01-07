import 'dart:typed_data';
import '../others/constants.dart';
import '../math/index.dart';
import 'package:flutter_angle/flutter_angle.dart';

/// [Interleaved] means that multiple attributes, possibly of different types,
/// (e.g., position, normal, uv, color) are packed into a single array buffer.
///
/// An introduction into interleaved arrays can be found here:
/// [Interleaved array basics](https://blog.tojicode.com/2011/05/interleaved-array-basics.html)
class InterleavedBuffer {
  NativeArray array;
  int stride;
  late int meshPerAttribute;
  late int count;
  int usage = StaticDrawUsage;
  //late Map<String, dynamic> updateRange;
  int version = 0;
  late String uuid;
  bool isInterleavedBuffer = true;
  Function? onUploadCallback;

  List updateRanges = [];
  int itemSize = 3;

  String type = "InterleavedBuffer";

  void dispose(){
    array.dispose();
  }

  /// [array] -- A typed array with a shared buffer. Stores the
  /// geometry data.
  /// 
  /// [stride] -- The number of typed-array elements per vertex.
  InterleavedBuffer(this.array, this.stride) {
    count = array.length ~/ stride;
    uuid = MathUtils.generateUUID();
  }

  /// [array] -- A typed array with a shared buffer. Stores the
  /// geometry data.
  /// 
  /// [stride] -- The number of typed-array elements per vertex.
  factory InterleavedBuffer.fromList(TypedData array, int stride) {
    final totalLen = array.lengthInBytes;
    return InterleavedBuffer(Float32Array(totalLen).set(array.buffer.asFloat32List()), stride);
  }

  set needsUpdate(bool value) {
    if (value == true) {
      version++;
    }
  }

	void addUpdateRange(int start, int count ) {
		this.updateRanges.add({"start": start, "count": count});
	}

	///Clears the update ranges.
	void clearUpdateRanges() {
		this.updateRanges.clear();
	}

  InterleavedBuffer setUsage(int value) {
    usage = value;
    return this;
  }

  /// Copies another [source] to this [source].
  InterleavedBuffer copy(InterleavedBuffer source) {
    array = source.array.clone();
    count = source.count;
    stride = source.stride;
    usage = source.usage;

    return this;
  }

  /// Copies data from `attribute[index2]` to array[index1].
  InterleavedBuffer copyAt(int index1, InterleavedBuffer attribute, int index2) {
    index1 *= stride;
    index2 *= attribute.stride;

    for (int i = 0, l = stride; i < l; i++) {
      array[index1 + i] = attribute.array[index2 + i];
    }

    return this;
  }

  // set ( value, {int offset = 0} ) {

  // 	this.array.set( value, offset );

  // 	return this;

  // }

  /// [data] - This object holds shared array buffers required for properly
  /// cloning geometries with interleaved attributes.
  InterleavedBuffer clone([Map<String,dynamic>? data]) {
    // data.arrayBuffers ??= {};

    //TODO: InterleavedBuffer clone

    // if ( this.array.buffer._uuid == null ) {

    // 	this.array.buffer._uuid = MathUtils.generateUUID();

    // }

    // if ( data.arrayBuffers[ this.array.buffer._uuid ] == null ) {

    // 	data.arrayBuffers[ this.array.buffer._uuid ] = this.array.slice( 0 ).buffer;

    // }

    // const array = new this.array.constructor( data.arrayBuffers[ this.array.buffer._uuid ] );

    final ib = InterleavedBuffer(array, stride);
    ib.setUsage(usage);

    return ib;
  }

  InterleavedBuffer onUpload(Function callback) {
    onUploadCallback = callback;
    return this;
  }

  /// [data] - This object holds shared array buffers required for properly
  /// serializing geometries with interleaved attributes.
  Map<String, dynamic> toJson(InterleavedBuffer data) {
    // data.arrayBuffers ??= {};

    // generate UUID for array buffer if necessary

    // if ( this.array.buffer._uuid == null ) {

    // 	this.array.buffer._uuid = MathUtils.generateUUID();

    // }

    // if ( data.arrayBuffers[ this.array.buffer._uuid ] == null ) {

    // 	data.arrayBuffers[ this.array.buffer._uuid ] = Array.prototype.slice.call( new Uint32Array( this.array.buffer ) );

    // }

    //

    return {
      "uuid": uuid,
      // "buffer": this.array.buffer._uuid,
      // "type": this.array.constructor.name,
      "buffer": array,
      "type": "List",
      "stride": stride
    };
  }
}
