import 'package:three_js_math/three_js_math.dart';

class InterleavedBufferAttribute extends BufferAttribute{
  final Vector3 _vector = Vector3.zero();
  int offset;
  InterleavedBuffer? data;
  late String type;
  String? name;
  late int itemSize;
  bool normalized = false;

  InterleavedBufferAttribute(
    InterleavedBuffer? data, 
    int itemSize, 
    this.offset, 
    [bool _normalized = false]
  ):super(Float32Array(0),itemSize, _normalized){
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
    return data?.array ?? Uint16Array(0);
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

  /// Applies normal matrix [m] to every Vector3 element of this
  /// InterleavedBufferAttribute.
  @override
  InterleavedBufferAttribute applyNormalMatrix(Matrix3 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );
      _vector.applyNormalMatrix(m);
      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  /// Applies matrix [m] to every Vector3 element of this
  /// InterleavedBufferAttribute, interpreting the elements as a direction
  /// vectors.
  @override
  InterleavedBufferAttribute transformDirection(Matrix4 m) {
    for (int i = 0, l = count; i < l; i++) {
      _vector.fromBuffer( this, i );
      _vector.transformDirection(m);
      setXYZ(i, _vector.x, _vector.y, _vector.z);
    }

    return this;
  }

  ///
  /// Returns the given component of the vector at the given index.
	///
  /// @param {number} index - The index into the buffer attribute.
  /// @param {number} component - The component index.
  /// @return {number} The returned value.
	///
	double getComponent(int index, int component ) {
		num value = this.array[ index * this.data!.stride + this.offset + component ];
		if ( this.normalized ) value = MathUtils.denormalize( value, this.array );
		return value.toDouble();
	}

  ///
  /// Sets the given value to the given component of the vector at the given index.
	///
  /// @param {number} index - The index into the buffer attribute.
  /// @param {number} component - The component index.
  /// @param {number} value - The value to set.
  /// @return {InterleavedBufferAttribute} A reference to this instance.
	///
	InterleavedBufferAttribute setComponent(int index, int component, double value ) {
		if ( this.normalized ){ 
      value = MathUtils.normalize( value, this.array );
    }
		this.data?.array[ index * this.data!.stride + this.offset + component ] = value;
		return this;
	}


  /// Sets the x component of the item at the given index.
  @override
  InterleavedBufferAttribute setX(int index, num x) {
    if ( this.normalized ) x = MathUtils.normalize( x, this.array );
    data!.array[index * data!.stride + offset] = x.toDouble();
    return this;
  }

  /// Sets the y component of the item at the given index.
  @override
  InterleavedBufferAttribute setY(int index, num y) {
    if ( this.normalized ) y = MathUtils.normalize( y, this.array );
    data!.array[index * data!.stride + offset + 1] = y.toDouble();
    return this;
  }

  /// Sets the z component of the item at the given index.
  @override
  InterleavedBufferAttribute setZ(int index, num z) {
    if ( this.normalized ) z = MathUtils.normalize( z, this.array );
    data!.array[index * data!.stride + offset + 2] = z.toDouble();
    return this;
  }

  // Sets the w component of the item at the given index.
  @override
  InterleavedBufferAttribute setW(int index, w) {
    if ( this.normalized ) w = MathUtils.normalize( w, this.array );
    data!.array[index * data!.stride + offset + 3] = w;
    return this;
  }

  /// Returns the x component of the item at the given index.
  @override
  double getX(int index) {
		num x = this.data!.array[ index * this.data!.stride + this.offset ];
		if ( this.normalized ) x = MathUtils.denormalize( x, this.array );
		return x.toDouble();
  }

  /// Returns the y component of the item at the given index.
  @override
  double getY(int index) {
		num y = this.data!.array[ index * this.data!.stride + this.offset + 1 ];
		if ( this.normalized ) y = MathUtils.denormalize( y, this.array );
		return y.toDouble();
  }

  /// Returns the z component of the item at the given index.
  @override
  double getZ(int index) {
		num z = this.data!.array[ index * this.data!.stride + this.offset + 2 ];
		if ( this.normalized ) z = MathUtils.denormalize( z, this.array );
		return z.toDouble();
  }

  /// Returns the w component of the item at the given index.
  @override
  double getW(int index) {
		num w = this.data!.array[ index * this.data!.stride + this.offset + 3 ];
		if ( this.normalized ) w = MathUtils.denormalize( w, this.array );
		return w.toDouble();
  }

  /// Sets the x and y components of the item at the given index.
  @override
  InterleavedBufferAttribute setXY(int index, x, y) {
		index = index * this.data!.stride + this.offset;

		if ( this.normalized ) {
			x = MathUtils.normalize( x, this.array );
			y = MathUtils.normalize( y, this.array );
		}

		this.data!.array[ index + 0 ] = x;
		this.data!.array[ index + 1 ] = y;

		return this;
  }

  /// Sets the x, y and z components of the item at the given index.
  @override
  InterleavedBufferAttribute setXYZ(int index, x, y, z) {
		index = index * this.data!.stride + this.offset;

		if ( this.normalized ) {
			x = MathUtils.normalize( x, this.array );
			y = MathUtils.normalize( y, this.array );
			z = MathUtils.normalize( z, this.array );
		}

		this.data!.array[ index + 0 ] = x;
		this.data!.array[ index + 1 ] = y;
		this.data!.array[ index + 2 ] = z;

		return this;
  }

  /// Sets the x, y, z and w components of the item at the given index.
  @override
  InterleavedBufferAttribute setXYZW(int index, num x, num y, num z, num w) {
		index = index * this.data!.stride + this.offset;

		if ( this.normalized ) {
			x = MathUtils.normalize( x, this.array );
			y = MathUtils.normalize( y, this.array );
			z = MathUtils.normalize( z, this.array );
			w = MathUtils.normalize( w, this.array );
		}

		this.data!.array[ index + 0 ] = x;
		this.data!.array[ index + 1 ] = y;
		this.data!.array[ index + 2 ] = z;
		this.data!.array[ index + 3 ] = w;

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
      //print('InterleavedBufferAttribute.toJson(): Serializing an interlaved buffer attribute will deinterleave buffer data!.');

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
