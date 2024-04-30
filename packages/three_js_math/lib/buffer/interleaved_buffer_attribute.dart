import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';

final Vector3 _vector = Vector3.zero();

class InterleavedBufferAttribute extends BufferAttribute {
  int offset;

  InterleavedBufferAttribute(
    InterleavedBuffer? data, 
    int itemSize, 
    this.offset, 
    [bool _normalized = false]
  ): super(Float32Array(0), itemSize) {
    this.data = data;
    type = "InterleavedBufferAttribute";
    this.itemSize = itemSize;
    normalized = _normalized;
  }

  @override
  int get count {
    return data!.count;
  }

  @override
  NativeArray get array {
    return data!.array;
  }

  @override
  set needsUpdate(bool value) {
    data!.needsUpdate = value;
  }

  @override
  InterleavedBufferAttribute applyMatrix4(Matrix4 m) {
    for (int i = 0, l = data!.count; i < l; i++) {
      _vector.fromBuffer( this, i );
      _vector.applyMatrix4(m);
      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  @override
  InterleavedBufferAttribute applyNormalMatrix(Matrix3 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );
      _vector.applyNormalMatrix(m);
      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  @override
  InterleavedBufferAttribute transformDirection(Matrix4 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.x = getX(i).toDouble();
      _vector.y = getY(i).toDouble();
      _vector.z = getZ(i).toDouble();
      _vector.transformDirection(m);
      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  @override
  InterleavedBufferAttribute setX(int index, x) {
    data!.array[index * data!.stride + offset] = x;
    return this;
  }

  @override
  InterleavedBufferAttribute setY(int index, y) {
    data!.array[index * data!.stride + offset + 1] = y;
    return this;
  }

  @override
  InterleavedBufferAttribute setZ(int index, z) {
    data!.array[index * data!.stride + offset + 2] = z;
    return this;
  }

  @override
  InterleavedBufferAttribute setW(int index, w) {
    data!.array[index * data!.stride + offset + 3] = w;
    return this;
  }

  @override
  double getX(int index) {
    return data!.array[index * data!.stride + offset].toDouble();
  }

  @override
  double getY(int index) {
    return data!.array[index * data!.stride + offset + 1].toDouble();
  }

  @override
  double getZ(int index) {
    return data!.array[index * data!.stride + offset + 2].toDouble();
  }

  @override
  double getW(int index) {
    return data!.array[index * data!.stride + offset + 3].toDouble();
  }

  @override
  InterleavedBufferAttribute setXY(int index, x, y) {
    index = index * data!.stride + offset;
    data!.array[index + 0] = x;
    data!.array[index + 1] = y;

    return this;
  }

  @override
  InterleavedBufferAttribute setXYZ(int index, x, y, z) {
    index = index * data!.stride + offset;

    data!.array[index + 0] = x;
    data!.array[index + 1] = y;
    data!.array[index + 2] = z;

    return this;
  }

  @override
  InterleavedBufferAttribute setXYZW(int index, x, y, z, w) {
    index = index * data!.stride + offset;

    data!.array[index + 0] = x;
    data!.array[index + 1] = y;
    data!.array[index + 2] = z;
    data!.array[index + 3] = w;

    return this;
  }

  // clone ( data ) {

  // 	if ( data == null ) {

  // 		print( 'THREE.InterleavedBufferAttribute.clone(): Cloning an interlaved buffer attribute will deinterleave buffer data!.' );

  // 		List<num> array = [];

  // 		for ( int i = 0; i < this.count; i ++ ) {

  // 			final index = i * this.data!.stride + this.offset;

  // 			for ( int j = 0; j < this.itemSize; j ++ ) {

  // 				array.add( this.data!.array[ index + j ] );

  // 			}

  // 		}

  // 		return new BufferAttribute(array, this.itemSize, this.normalized );

  // 	} else {

  // 		if ( data!.interleavedBuffers == null ) {

  // 			data!.interleavedBuffers = {};

  // 		}

  // 		if ( data!.interleavedBuffers[ this.data!.uuid ] == null ) {

  // 			data!.interleavedBuffers[ this.data!.uuid ] = this.data!.clone( data );

  // 		}

  // 		return new InterleavedBufferAttribute( data!.interleavedBuffers[ this.data!.uuid ], this.itemSize, this.offset, this.normalized );

  // 	}

  // }

  @override
  Map<String, Object> toJson([InterleavedBuffer? data]) {
    if (data == null) {
      print('InterleavedBufferAttribute.toJson(): Serializing an interlaved buffer attribute will deinterleave buffer data!.');

      List<double> array = [];

      for (int i = 0; i < count; i++) {
        final index = i * this.data!.stride + offset;
        for (int j = 0; j < itemSize; j++) {
          array.add(this.data!.array[index + j].toDouble());
        }
      }

      // deinterleave data and save it as an ordinary buffer attribute for now

      return {
        "itemSize": itemSize,
        "type": this.array.runtimeType.toString(),
        "array": array,
        "normalized": normalized
      };
    } 
    else {
      // save as true interlaved attribtue

      // data.interleavedBuffers ??= {};

      // if (data.interleavedBuffers[this.data!.uuid] == null) {
      //   data.interleavedBuffers[this.data!.uuid] = this.data!.toJson(data);
      // }

      return {
        "isInterleavedBufferAttribute": true,
        "itemSize": itemSize,
        "data": this.data!.uuid,
        "offset": offset,
        "normalized": normalized
      };
    }
  }
}
