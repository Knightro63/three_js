
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/gpu_backend.dart';
import 'package:three_js_math/three_js_math.dart';

final typedArraysToVertexFormatPrefix = new Map( [
	[ Int8Array, [ 'sint8', 'snorm8' ]],
	[ Uint8Array, [ 'uint8', 'unorm8' ]],
	[ Int16Array, [ 'sint16', 'snorm16' ]],
	[ Uint16Array, [ 'uint16', 'unorm16' ]],
	[ Int32Array, [ 'sint32', 'snorm32' ]],
	[ Uint32Array, [ 'uint32', 'unorm32' ]],
	[ Float32Array, [ 'float32', ]],
] );

if ( typeof Float16Array != null ) {

	typedArraysToVertexFormatPrefix.set( Float16Array, [ 'float16' ] );

}

final typedAttributeToVertexFormatPrefix = new Map( [
	[ Float16BufferAttribute, [ 'float16', ]],
] );

final typeArraysToVertexFormatPrefixForItemSize1 = new Map( [
	[ Int32Array, 'sint32' ],
	[ Int16Array, 'sint32' ], // patch for INT16
	[ Uint32Array, 'uint32' ],
	[ Uint16Array, 'uint32' ], // patch for UINT16
	[ Float32Array, 'float32' ]
] );

/**
 * A WebGPU backend utility module for managing shader attributes.
 *
 * @private
 */
class WebGPUAttributeUtils {
  WebGPUBackend backend;

	WebGPUAttributeUtils( this.backend );

	/**
	 * Creates the GPU buffer for the given buffer attribute.
	 *
	 * @param {BufferAttribute} attribute - The buffer attribute.
	 * @param {GPUBufferUsage} usage - A flag that indicates how the buffer may be used after its creation.
	 */
	createAttribute(BufferAttribute attribute, GPUBufferUsage usage ) {
		final bufferAttribute = this._getBufferAttribute( attribute );
		final backend = this.backend;
		final bufferData = backend.get( bufferAttribute );

		let buffer = bufferData.buffer;

		if ( buffer == null ) {
			final device = backend.device;
			let array = bufferAttribute.array;

			// patch for INT16 and UINT16
			if ( attribute.normalized == false ) {
				if ( array.constructor == Int16Array || array.constructor == Int8Array ) {
					array = new Int32Array( array );
				} 
        else if ( array.constructor == Uint16Array || array.constructor == Uint8Array ) {
					array = new Uint32Array( array );

					if ( usage & GPUBufferUsage.INDEX ) {
						for ( int i = 0; i < array.length; i ++ ) {
							if ( array[ i ] == 0xffff ) array[ i ] = 0xffffffff; // use correct primitive restart index
						}
					}
				}
			}

			bufferAttribute.array = array;

			if ( ( bufferAttribute.isStorageBufferAttribute || bufferAttribute.isStorageInstancedBufferAttribute ) && bufferAttribute.itemSize == 3 ) {
				array = new array.constructor( bufferAttribute.count * 4 );

				for ( int i = 0; i < bufferAttribute.count; i ++ ) {
					array.set( bufferAttribute.array.subarray( i * 3, i * 3 + 3 ), i * 4 );
				}

				// Update BufferAttribute
				bufferAttribute.itemSize = 4;
				bufferAttribute.array = array;

				bufferData._force3to4BytesAlignment = true;
			}

			// ensure 4 byte alignment
			final byteLength = array.byteLength;
			final size = byteLength + ( ( 4 - ( byteLength % 4 ) ) % 4 );

			buffer = device.createBuffer( {
				'label': bufferAttribute.name,
				'size': size,
				'usage': usage,
				'mappedAtCreation': true
			} );

			new array.constructor( buffer.getMappedRange() ).set( array );
			buffer.unmap();
			bufferData.buffer = buffer;
		}
	}

	/**
	 * Updates the GPU buffer of the given buffer attribute.
	 *
	 * @param {BufferAttribute} attribute - The buffer attribute.
	 */
	updateAttribute( attribute ) {
		final bufferAttribute = this._getBufferAttribute( attribute );

		final backend = this.backend;
		final device = backend.device;

		final bufferData = backend.get( bufferAttribute );
		final buffer = backend.get( bufferAttribute ).buffer;

		let array = bufferAttribute.array;

		//  if storage buffer ensure 4 byte alignment
		if ( bufferData._force3to4BytesAlignment == true ) {
			array = new array.constructor( bufferAttribute.count * 4 );
			for ( int i = 0; i < bufferAttribute.count; i ++ ) {
				array.set( bufferAttribute.array.subarray( i * 3, i * 3 + 3 ), i * 4 );
			}

			bufferAttribute.array = array;
		}

		final isTypedArray = this._isTypedArray( array );
		final updateRanges = bufferAttribute.updateRanges;

		if ( updateRanges.length == 0 ) {
			// Not using update ranges
			device.queue.writeBuffer(
				buffer,
				0,
				array,
				0
			);
		} 
    else {
			final byteOffsetFactor = isTypedArray ? 1 : array.BYTES_PER_ELEMENT;

			for ( int i = 0, l = updateRanges.length; i < l; i ++ ) {
				final range = updateRanges[ i ];
				let dataOffset, size;

				if ( bufferData._force3to4BytesAlignment == true ) {
					final vertexStart = ( range.start / 3 ).floor();
					final vertexCount = ( range.count / 3 ).ceil();
					dataOffset = vertexStart * 4 * byteOffsetFactor;
					size = vertexCount * 4 * byteOffsetFactor;
				} 
        else {
					dataOffset = range.start * byteOffsetFactor;
					size = range.count * byteOffsetFactor;
				}

				final bufferOffset = dataOffset * ( isTypedArray ? array.BYTES_PER_ELEMENT : 1 ); // bufferOffset is always in bytes

				device.queue.writeBuffer(
					buffer,
					bufferOffset,
					array,
					dataOffset,
					size
				);
			}

			bufferAttribute.clearUpdateRanges();
		}
	}

	/**
	 * This method creates the vertex buffer layout data which are
	 * require when creating a render pipeline for the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {Array<Object>} An array holding objects which describe the vertex buffer layout.
	 */
	createShaderVertexBuffers( renderObject ) {
		final attributes = renderObject.getAttributes();
		final vertexBuffers = new Map();

		for ( int slot = 0; slot < attributes.length; slot ++ ) {
			final geometryAttribute = attributes[ slot ];
			final bytesPerElement = geometryAttribute.array.BYTES_PER_ELEMENT;
			final bufferAttribute = this._getBufferAttribute( geometryAttribute );

			let vertexBufferLayout = vertexBuffers.get( bufferAttribute );

			if ( vertexBufferLayout == null ) {
				let arrayStride, stepMode;

				if ( geometryAttribute.isInterleavedBufferAttribute == true ) {
					arrayStride = geometryAttribute.data.stride * bytesPerElement;
					stepMode = geometryAttribute.data.isInstancedInterleavedBuffer ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
				} 
        else {
					arrayStride = geometryAttribute.itemSize * bytesPerElement;
					stepMode = geometryAttribute.isInstancedBufferAttribute ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
				}

				// patch for INT16 and UINT16
				if ( geometryAttribute.normalized == false && ( geometryAttribute.array.constructor == Int16Array || geometryAttribute.array.constructor == Uint16Array ) ) {

					arrayStride = 4;

				}

				vertexBufferLayout = {
					arrayStride,
					attributes: [],
					stepMode
				};

				vertexBuffers.set( bufferAttribute, vertexBufferLayout );

			}

			final format = this._getVertexFormat( geometryAttribute );
			final offset = ( geometryAttribute.isInterleavedBufferAttribute == true ) ? geometryAttribute.offset * bytesPerElement : 0;

			vertexBufferLayout.attributes.push( {
				shaderLocation: slot,
				offset,
				format
			} );

		}

		return Array.from( vertexBuffers.values() );
	}

	/**
	 * Destroys the GPU buffer of the given buffer attribute.
	 *
	 * @param {BufferAttribute} attribute - The buffer attribute.
	 */
	destroyAttribute(BufferAttribute attribute ) {
		final backend = this.backend;
		final data = backend.get( this._getBufferAttribute( attribute ) );

		data.buffer.destroy();
		backend.delete( attribute );
	}

	/**
	 * This method performs a readback operation by moving buffer data from
	 * a storage buffer attribute from the GPU to the CPU.
	 *
	 * @async
	 * @param {StorageBufferAttribute} attribute - The storage buffer attribute.
	 * @return {Promise<ArrayBuffer>} A promise that resolves with the buffer data when the data are ready.
	 */
	Future getArrayBufferAsync( attribute ) async{
		final backend = this.backend;
		final device = backend.device;

		final data = backend.get( this._getBufferAttribute( attribute ) );
		final bufferGPU = data.buffer;
		final size = bufferGPU.size;

		final readBufferGPU = device.createBuffer( {
			label: '${ attribute.name }_readback',
			size,
			usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
		} );

		final cmdEncoder = device.createCommandEncoder( {
			label: 'readback_encoder_${ attribute.name }'
		} );

		cmdEncoder.copyBufferToBuffer(
			bufferGPU,
			0,
			readBufferGPU,
			0,
			size
		);

		final gpuCommands = cmdEncoder.finish();
		device.queue.submit( [ gpuCommands ] );

		await readBufferGPU.mapAsync( GPUMapMode.READ );

		final arrayBuffer = readBufferGPU.getMappedRange();

		final dstBuffer = new attribute.array.constructor( arrayBuffer.slice( 0 ) );

		readBufferGPU.unmap();

		return dstBuffer.buffer;

	}

	/**
	 * Returns the vertex format of the given buffer attribute.
	 *
	 * @private
	 * @param {BufferAttribute} geometryAttribute - The buffer attribute.
	 * @return {string|null} The vertex format (e.g. 'float32x3').
	 */
	_getVertexFormat( geometryAttribute ) {
		final { itemSize, normalized } = geometryAttribute;
		final ArrayType = geometryAttribute.array.constructor;
		final AttributeType = geometryAttribute.constructor;

		let format;

		if ( itemSize == 1 ) {
			format = typeArraysToVertexFormatPrefixForItemSize1.get( ArrayType );
		} 
    else {
			final prefixOptions = typedAttributeToVertexFormatPrefix.get( AttributeType ) || typedArraysToVertexFormatPrefix.get( ArrayType );
			final prefix = prefixOptions[ normalized ? 1 : 0 ];

			if ( prefix ) {
				final bytesPerUnit = ArrayType.BYTES_PER_ELEMENT * itemSize;
				final paddedBytesPerUnit = ( ( bytesPerUnit + 3 ) / 4 ).floor() * 4;
				final paddedItemSize = paddedBytesPerUnit / ArrayType.BYTES_PER_ELEMENT;

				if ( paddedItemSize % 1 ) {
					throw( 'THREE.WebGPUAttributeUtils: Bad vertex format item size.' );
				}

				format = '${prefix}x${paddedItemSize}';
			}
		}

		if ( ! format ) {
			console.error( 'THREE.WebGPUAttributeUtils: Vertex format not supported yet.' );
		}

		return format;
	}

	/**
	 * Returns `true` if the given array is a typed array.
	 *
	 * @private
	 * @param {any} array - The array.
	 * @return {boolean} Whether the given array is a typed array or not.
	 */
	bool _isTypedArray(dynamic array ) {
		return ArrayBuffer.isView( array ) && ! ( array is DataView );
	}

	/**
	 * Utility method for handling interleaved buffer attributes correctly.
	 * To process them, their `InterleavedBuffer` is returned.
	 *
	 * @private
	 * @param {BufferAttribute} attribute - The attribute.
	 * @return {BufferAttribute|InterleavedBuffer}
	 */
	BufferAttribute _getBufferAttribute(BufferAttribute attribute ) {
		if ( attribute is InterleavedBufferAttribute ) attribute = attribute.data;
		return attribute;
	}
}
