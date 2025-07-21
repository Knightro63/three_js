import "dart:typed_data";

import "package:three_js_core/three_js_core.dart" hide Uniform;
import "package:three_js_gpu/common/constants.dart";
import "./uniform.dart";
import "package:three_js_math/three_js_math.dart";

import "./uniform_buffer.dart";

/**
 * This class represents a uniform buffer binding but with
 * an API that allows to maintain individual uniform objects.
 *
 * @private
 * @augments UniformBuffer
 */
class UniformsGroup extends UniformBuffer {
  bool isUniformsGroup = true;
  List? _values;
  List uniforms = [];

	UniformsGroup( name ):super(name);

	UniformsGroup addUniform(Uniform uniform ) {
		this.uniforms.add( uniform );
		return this;
	}

	UniformsGroup removeUniform(Uniform uniform ) {
		final index = this.uniforms.indexOf( uniform );

		if ( index != - 1 ) {
			this.uniforms.splice( index, 1 );
		}

		return this;
	}

	/**
	 * An array with the raw uniform values.
	 *
	 * @type {Array<number>}
	 */
	get values => () {
		if ( this._values == null ) {
			this._values = Array.from( this.buffer );
		}
		return this._values;
	};

	/**
	 * A Float32 array buffer with the uniform values.
	 *
	 * @type {Float32Array}
	 */
	get buffer => () {
		dynamic buffer = this._buffer;

		if ( buffer == null ) {
			final byteLength = this.byteLength;
			buffer = Float32Array.fromList( new ArrayBuffer( byteLength ) );
			this._buffer = buffer;
		}
		return buffer;
	};

	/**
	 * The byte length of the buffer with correct buffer alignment.
	 *
	 * @type {number}
	 */
	get byteLength => () {

		final bytesPerElement = this.bytesPerElement;

		int offset = 0; // global buffer offset in bytes

		for (int i = 0, l = this.uniforms.length; i < l; i ++ ) {

			final uniform = this.uniforms[ i ];

			final int boundary = uniform.boundary;
			final int itemSize = uniform.itemSize * bytesPerElement; // size of the uniform in bytes

			final chunkOffset = offset % gpuChunkBytes; // offset in the current chunk
			final chunkPadding = chunkOffset % boundary; // required padding to match boundary
			final chunkStart = chunkOffset + chunkPadding; // start position in the current chunk for the data

			offset += chunkPadding;

			// Check for chunk overflow
			if ( chunkStart != 0 && ( gpuChunkBytes - chunkStart ) < itemSize ) {

				// Add padding to the end of the chunk
				offset += ( gpuChunkBytes - chunkStart );

			}

			uniform.offset = offset / bytesPerElement;

			offset += itemSize;

		}

		return ( offset / gpuChunkBytes ).ceil() * gpuChunkBytes;

	}

	/**
	 * Updates this group by updating each uniform object of
	 * the internal uniform list. The uniform objects check if their
	 * values has actually changed so this method only returns
	 * `true` if there is a real value change.
	 *
	 * @return {boolean} Whether the uniforms have been updated and
	 * must be uploaded to the GPU.
	 */
	bool update() {
		bool updated = false;

		for ( final uniform in this.uniforms ) {
			if ( this.updateByType( uniform ) == true ) {
				updated = true;
			}
		}

		return updated;
	}

	/**
	 * Updates a given uniform by calling an update method matching
	 * the uniforms type.
	 *
	 * @param {Uniform} uniform - The uniform to update.
	 * @return {boolean} Whether the uniform has been updated or not.
	 */
	bool updateByType(Uniform uniform ) {
		if ( uniform is NumberUniform ) return this.updateNumber( uniform );
		if ( uniform is Vector2Uniform ) return this.updateVector2( uniform );
		if ( uniform is Vector3Uniform ) return this.updateVector3( uniform );
		if ( uniform is Vector4Uniform ) return this.updateVector4( uniform );
		if ( uniform is ColorUniform ) return this.updateColor( uniform );
		if ( uniform is Matrix3Uniform ) return this.updateMatrix3( uniform );
		if ( uniform is Matrix4Uniform ) return this.updateMatrix4( uniform );

		throw( 'THREE.WebGPUUniformsGroup: Unsupported uniform type. $uniform', );
	}

	/**
	 * Updates a given Number uniform.
	 *
	 * @param {NumberUniform} uniform - The Number uniform.
	 * @return {boolean} Whether the uniform has been updated or not.
	 */
	bool updateNumber(NumberUniform uniform ) {
		bool updated = false;

		final a = this.values;
		final v = uniform.getValue();
		final offset = uniform.offset;
		final type = uniform.getType();

		if ( a[ offset ] != v ) {
			final b = this._getBufferForType( type );

			b[ offset ] = a[ offset ] = v;
			updated = true;
		}

		return updated;
	}

	/**
	 * Updates a given Vector2 uniform.
	 *
	 * @param {Vector2Uniform} uniform - The Vector2 uniform.
	 * @return {boolean} Whether the uniform has been updated or not.
	 */
	bool updateVector2(Vector2Uniform uniform ) {
		bool updated = false;

		final a = this.values;
		final v = uniform.getValue();
		final offset = uniform.offset;
		final type = uniform.getType();

		if ( a[ offset + 0 ] != v.x || a[ offset + 1 ] != v.y ) {
			final b = this._getBufferForType( type );

			b[ offset + 0 ] = a[ offset + 0 ] = v.x;
			b[ offset + 1 ] = a[ offset + 1 ] = v.y;

			updated = true;
		}

		return updated;
	}

	/**
	 * Updates a given Vector3 uniform.
	 *
	 * @param {Vector3Uniform} uniform - The Vector3 uniform.
	 * @return {boolean} Whether the uniform has been updated or not.
	 */
	bool updateVector3(Vector3Uniform uniform ) {
		bool updated = false;

		final a = this.values;
		final Vector3 v = uniform.getValue();
		final offset = uniform.offset;
		final type = uniform.getType();

		if ( a[ offset + 0 ] != v.x || a[ offset + 1 ] != v.y || a[ offset + 2 ] != v.z ) {

			final b = this._getBufferForType( type );

			b[ offset + 0 ] = a[ offset + 0 ] = v.x;
			b[ offset + 1 ] = a[ offset + 1 ] = v.y;
			b[ offset + 2 ] = a[ offset + 2 ] = v.z;

			updated = true;

		}

		return updated;

	}

	/**
	 * Updates a given Vector4 uniform.
	 *
	 * @param {Vector4Uniform} uniform - The Vector4 uniform.
	 * @return {boolean} Whether the uniform has been updated or not.
	 */
	bool updateVector4(Vector4Uniform uniform ) {
		bool updated = false;

		final a = this.values;
		final Vector4 v = uniform.getValue();
		final offset = uniform.offset;
		final type = uniform.getType();

		if ( a[ offset + 0 ] != v.x || a[ offset + 1 ] != v.y || a[ offset + 2 ] != v.z || a[ offset + 4 ] != v.w ) {
			final b = this._getBufferForType( type );

			b[ offset + 0 ] = a[ offset + 0 ] = v.x;
			b[ offset + 1 ] = a[ offset + 1 ] = v.y;
			b[ offset + 2 ] = a[ offset + 2 ] = v.z;
			b[ offset + 3 ] = a[ offset + 3 ] = v.w;

			updated = true;
		}

		return updated;
	}

	bool updateColor(ColorUniform uniform ) {
		bool updated = false;

		final a = this.values;
		final Color c = uniform.getValue();
		final offset = uniform.offset;

		if ( a[ offset + 0 ] != c.red || a[ offset + 1 ] != c.green || a[ offset + 2 ] != c.blue ) {

			final b = this.buffer;

			b[ offset + 0 ] = a[ offset + 0 ] = c.red;
			b[ offset + 1 ] = a[ offset + 1 ] = c.green;
			b[ offset + 2 ] = a[ offset + 2 ] = c.blue;

			updated = true;
		}

		return updated;
	}

	bool updateMatrix3(Matrix3Uniform uniform ) {
		bool updated = false;

		final a = this.values;
		final e = (uniform.getValue() as Matrix3).storage;
		final offset = uniform.offset;

		if ( a[ offset + 0 ] != e[ 0 ] || a[ offset + 1 ] != e[ 1 ] || a[ offset + 2 ] != e[ 2 ] ||
			a[ offset + 4 ] != e[ 3 ] || a[ offset + 5 ] != e[ 4 ] || a[ offset + 6 ] != e[ 5 ] ||
			a[ offset + 8 ] != e[ 6 ] || a[ offset + 9 ] != e[ 7 ] || a[ offset + 10 ] != e[ 8 ] ) {

			final b = this.buffer;

			b[ offset + 0 ] = a[ offset + 0 ] = e[ 0 ];
			b[ offset + 1 ] = a[ offset + 1 ] = e[ 1 ];
			b[ offset + 2 ] = a[ offset + 2 ] = e[ 2 ];
			b[ offset + 4 ] = a[ offset + 4 ] = e[ 3 ];
			b[ offset + 5 ] = a[ offset + 5 ] = e[ 4 ];
			b[ offset + 6 ] = a[ offset + 6 ] = e[ 5 ];
			b[ offset + 8 ] = a[ offset + 8 ] = e[ 6 ];
			b[ offset + 9 ] = a[ offset + 9 ] = e[ 7 ];
			b[ offset + 10 ] = a[ offset + 10 ] = e[ 8 ];

			updated = true;
		}

		return updated;
	}

	bool updateMatrix4(Matrix4Uniform uniform ) {
		bool updated = false;

		final a = this.values;
		final e = (uniform.getValue() as Matrix4).storage;
		final offset = uniform.offset;

		if ( arraysEqual( a, e, offset ) == false ) {

			final b = this.buffer;
			b.set( e, offset );
			setArray( a, e, offset );
			updated = true;
		}

		return updated;
	}

	/**
	 * Returns a typed array that matches the given data type.
	 *
	 * @param {string} type - The data type.
	 * @return {TypedArray} The typed array.
	 */
	NativeArray _getBufferForType(String type ) {
		if ( type == 'int' || type == 'ivec2' || type == 'ivec3' || type == 'ivec4' ) return Int32Array( this.buffer.buffer );
		if ( type == 'uint' || type == 'uvec2' || type == 'uvec3' || type == 'uvec4' ) return Uint32Array( this.buffer.buffer );
		return this.buffer;
	}
}

/**
 * Sets the values of the second array to the first array.
 *
 * @private
 * @param {TypedArray} a - The first array.
 * @param {TypedArray} b - The second array.
 * @param {number} offset - An index offset for the first array.
 */
void setArray(NativeArray a,NativeArray b, int offset ) {
	for ( int i = 0, l = b.length; i < l; i ++ ) {
		a[ offset + i ] = b[ i ];
	}
}

/**
 * Returns `true` if the given arrays are equal.
 *
 * @private
 * @param {TypedArray} a - The first array.
 * @param {TypedArray} b - The second array.
 * @param {number} offset - An index offset for the first array.
 * @return {boolean} Whether the given arrays are equal or not.
 */
bool arraysEqual(NativeArray a, NativeArray b, int offset ) {
	for (int i = 0, l = b.length; i < l; i ++ ) {
		if ( a[ offset + i ] != b[ i ] ) return false;
	}

	return true;

}
