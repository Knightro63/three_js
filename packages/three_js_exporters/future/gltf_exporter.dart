import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/**
 * The KHR_mesh_quantization extension allows these extra attribute component types
 *
 * @see https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md#extending-mesh-attributes
 */
final Map<String,List<String>> KHR_mesh_quantization_ExtraAttrTypes = {
	'POSITION': [
		'byte',
		'byte normalized',
		'unsigned byte',
		'unsigned byte normalized',
		'short',
		'short normalized',
		'unsigned short',
		'unsigned short normalized',
	],
	'NORMAL': [
		'byte normalized',
		'short normalized',
	],
	'TANGENT': [
		'byte normalized',
		'short normalized',
	],
	'TEXCOORD': [
		'byte',
		'byte normalized',
		'unsigned byte',
		'short',
		'short normalized',
		'unsigned short',
	],
};


class GLTFExporter {
  final List pluginCallbacks = [];

	GLTFExporter() {
		this.register(( writer ) {
			return new GLTFLightExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsUnlitExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsTransmissionExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsVolumeExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsIorExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsSpecularExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsClearcoatExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsIridescenceExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsSheenExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsAnisotropyExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMaterialsEmissiveStrengthExtension( writer );
		} );

		this.register(( writer ) {
			return new GLTFMeshGpuInstancing( writer );
		} );
	}

	GLTFExporter register( callback ) {
		if ( this.pluginCallbacks.indexOf( callback ) == - 1 ) {
			this.pluginCallbacks.add( callback );
		}
		return this;
	}

	GLTFExporter unregister( callback ) {
		if ( this.pluginCallbacks.indexOf( callback ) != - 1 ) {
			this.pluginCallbacks.removeLast( this.pluginCallbacks.indexOf( callback ));
		}
		return this;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Function} onError  Callback on errors
	 * @param  {Object} options options
	 */
	parse( input, onDone, onError, options ) {
		final writer = new GLTFWriter();
		final plugins = [];

		for (int i = 0, il = this.pluginCallbacks.length; i < il; i ++ ) {
			plugins.add( this.pluginCallbacks[ i ]( writer ) );
		}

		writer.setPlugins( plugins );
		writer.write( input, onDone, options ).catch( onError );

	}

	parseAsync( input, options ) {
		final scope = this;

		return new Promise(( resolve, reject ) {
			scope.parse( input, resolve, reject, options );
		} );
	}
}

//------------------------------------------------------------------------------
// finalants
//------------------------------------------------------------------------------

class WEBGL_finalANTS {
	static int POINTS = 0x0000;
	static int LINES = 0x0001;
	static int LINE_LOOP = 0x0002;
	static int LINE_STRIP = 0x0003;
	static int TRIANGLES = 0x0004;
	static int TRIANGLE_STRIP = 0x0005;
	static int TRIANGLE_FAN = 0x0006;

	static int BYTE = 0x1400;
	static int UNSIGNED_BYTE = 0x1401;
	static int SHORT = 0x1402;
	static int UNSIGNED_SHORT = 0x1403;
	static int INT = 0x1404;
	static int UNSIGNED_INT = 0x1405;
	static int FLOAT = 0x1406;

	static int ARRAY_BUFFER = 0x8892;
	static int ELEMENT_ARRAY_BUFFER = 0x8893;

	static int NEAREST = 0x2600;
	static int LINEAR = 0x2601;
	static int NEAREST_MIPMAP_NEAREST = 0x2700;
	static int LINEAR_MIPMAP_NEAREST = 0x2701;
	static int NEAREST_MIPMAP_LINEAR = 0x2702;
	static int LINEAR_MIPMAP_LINEAR = 0x2703;

	static int CLAMP_TO_EDGE = 33071;
	static int MIRRORED_REPEAT = 33648;
	static int REPEAT = 1049;
}

final KHR_MESH_QUANTIZATION = 'KHR_mesh_quantization';

final THREE_TO_WEBGL = {};

THREE_TO_WEBGL[ NearestFilter ] = WEBGL_finalANTS.NEAREST;
THREE_TO_WEBGL[ NearestMipmapNearestFilter ] = WEBGL_finalANTS.NEAREST_MIPMAP_NEAREST;
THREE_TO_WEBGL[ NearestMipmapLinearFilter ] = WEBGL_finalANTS.NEAREST_MIPMAP_LINEAR;
THREE_TO_WEBGL[ LinearFilter ] = WEBGL_finalANTS.LINEAR;
THREE_TO_WEBGL[ LinearMipmapNearestFilter ] = WEBGL_finalANTS.LINEAR_MIPMAP_NEAREST;
THREE_TO_WEBGL[ LinearMipmapLinearFilter ] = WEBGL_finalANTS.LINEAR_MIPMAP_LINEAR;

THREE_TO_WEBGL[ ClampToEdgeWrapping ] = WEBGL_finalANTS.CLAMP_TO_EDGE;
THREE_TO_WEBGL[ RepeatWrapping ] = WEBGL_finalANTS.REPEAT;
THREE_TO_WEBGL[ MirroredRepeatWrapping ] = WEBGL_finalANTS.MIRRORED_REPEAT;

final Map<String,String> PATH_PROPERTIES = {
	'scale': 'scale',
	'position': 'translation',
	'quaternion': 'rotation',
	'morphTargetInfluences': 'weights'
};

final DEFAULT_SPECULAR_COLOR = new Color();

// GLB finalants
// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

final GLB_HEADER_BYTES = 12;
final GLB_HEADER_MAGIC = 0x46546C67;
final GLB_VERSION = 2;

final GLB_CHUNK_PREFIX_BYTES = 8;
final GLB_CHUNK_TYPE_JSON = 0x4E4F534A;
final GLB_CHUNK_TYPE_BIN = 0x004E4942;

//------------------------------------------------------------------------------
// Utility functions
//------------------------------------------------------------------------------

/**
 * Compare two arrays
 * @param  {Array} array1 Array 1 to compare
 * @param  {Array} array2 Array 2 to compare
 * @return {Boolean}        Returns true if both arrays are equal
 */
equalArray( array1, array2 ) {
	return ( array1.length == array2.length ) && array1.every(( element, index ) {
		return element == array2[ index ];
	} );
}

/**
 * Converts a string to an ArrayBuffer.
 * @param  {string} text
 * @return {ArrayBuffer}
 */
stringToArrayBuffer( text ) {
	return new TextEncoder().encode( text ).buffer;
}

/**
 * Is identity matrix
 *
 * @param {Matrix4} matrix
 * @returns {Boolean} Returns true, if parameter is identity matrix
 */
isIdentityMatrix( matrix ) {
	return equalArray( matrix.elements, [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ] );
}

/**
 * Get the min and max vectors from the given attribute
 * @param  {BufferAttribute} attribute Attribute to find the min/max in range from start to start + count
 * @param  {Integer} start
 * @param  {Integer} count
 * @return {Object} Object containing the `min` and `max` values (As an array of attribute.itemSize components)
 */getMinMax( attribute, start, count ) {

	final output = {
		'min': new Array( attribute.itemSize ).fill( Number.POSITIVE_INFINITY ),
		'max': new Array( attribute.itemSize ).fill( Number.NEGATIVE_INFINITY )
	};

	for (int i = start; i < start + count; i ++ ) {
		for (int a = 0; a < attribute.itemSize; a ++ ) {

			var value;

			if ( attribute.itemSize > 4 ) {
				 // no support for interleaved data for itemSize > 4
				value = attribute.array[ i * attribute.itemSize + a ];
			}
      else {
				if ( a == 0 ) value = attribute.getX( i );
				else if ( a == 1 ) value = attribute.getY( i );
				else if ( a == 2 ) value = attribute.getZ( i );
				else if ( a == 3 ) value = attribute.getW( i );

				if ( attribute.normalized == true ) {
					value = MathUtils.normalize( value, attribute.array );
				}
			}

			output['min'][ a ] = math.min( output['min'][ a ], value );
			output['max'][ a ] = math.max( output['max'][ a ], value );
		}
	}

	return output;
}

/**
 * Get the required size + padding for a buffer, rounded to the next 4-byte boundary.
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#data-alignment
 *
 * @param {Integer} bufferSize The size the original buffer.
 * @returns {Integer} new buffer size with required padding.
 *
 */
int getPaddedBufferSize(num bufferSize ) {
	return ( bufferSize / 4 ).ceil() * 4;
}

/**
 * Returns a buffer aligned to 4-byte boundary.
 *
 * @param {ArrayBuffer} arrayBuffer Buffer to pad
 * @param {Integer} paddingByte (Optional)
 * @returns {ArrayBuffer} The same buffer if it's already aligned to 4-byte boundary or a new buffer
 */
getPaddedArrayBuffer( arrayBuffer,[int paddingByte = 0 ]) {
	final paddedLength = getPaddedBufferSize( arrayBuffer.byteLength );

	if ( paddedLength != arrayBuffer.byteLength ) {

		final array = new Uint8List( paddedLength );
		array.set( new Uint8List( arrayBuffer ) );

		if ( paddingByte != 0 ) {
			for (int i = arrayBuffer.byteLength; i < paddedLength; i ++ ) {
				array[ i ] = paddingByte;
			}
		}

		return array.buffer;
	}

	return arrayBuffer;
}
getCanvas() {

	if ( typeof document == 'null' && typeof OffscreenCanvas != 'null' ) {

		return new OffscreenCanvas( 1, 1 );

	}

	return document.createElement( 'canvas' );

}
getToBlobPromise( canvas, mimeType ) {

	if ( canvas.toBlob != null ) {

		return new Promise( ( resolve ) => canvas.toBlob( resolve, mimeType ) );

	}

	var quality;

	// Blink's implementation of convertToBlob seems to default to a quality level of 100%
	// Use the Blink default quality levels of toBlob instead so that file sizes are comparable.
	if ( mimeType == 'image/jpeg' ) {

		quality = 0.92;

	} else if ( mimeType == 'image/webp' ) {

		quality = 0.8;

	}

	return canvas.convertToBlob( {

		type: mimeType,
		quality: quality

	} );

}

/**
 * Writer
 */
class GLTFWriter {
  List plugins = [];

  Map options = {};
  List pending = [];
  List buffers = [];

  int byteOffset = 0;
  List buffers = [];
  Map nodeMap = new Map();
  List skins = [];

  Map extensionsUsed = {};
  Map extensionsRequired = {};

  Map uids = new Map();
  int uid = 0;

  Map<String,dynamic> json = {
    'asset': {
      'version': '2.0',
      'generator': 'THREE.GLTFExporter'
    }
  };

  Map<String,Map> cache = {
    'meshes': new Map(),
    'attributes': new Map(),
    'attributesNormalized': new Map(),
    'materials': new Map(),
    'textures': new Map(),
    'images': new Map()
  };

	setPlugins( plugins ) {
		this.plugins = plugins;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Object} options options
	 */
	write( input, onDone, [Map options]) async {
    options ??= {};

		options = {
			// default options
			'binary': false,
			'trs': false,
			'onlyVisible': true,
			'maxTextureSize': double.infinity.toInt(),
			'animations': [],
			'includeCustomExtensions': false
		};

		if ( this.options['animations'].length > 0 ) {
			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options['trs'] = true;
		}

		this.processInput( input );

		await Promise.all( this.pending );

		final writer = this;
		final buffers = writer.buffers;
		final json = writer.json;
		options = writer.options;

		final extensionsUsed = writer.extensionsUsed;
		final extensionsRequired = writer.extensionsRequired;

		// Merge buffers.
		final blob = new Blob( buffers, { type: 'application/octet-stream' } );

		// Declare extensions.
		final extensionsUsedList = Object.keys( extensionsUsed );
		final extensionsRequiredList = Object.keys( extensionsRequired );

		if ( extensionsUsedList.length > 0 ) json.extensionsUsed = extensionsUsedList;
		if ( extensionsRequiredList.length > 0 ) json.extensionsRequired = extensionsRequiredList;

		// Update bytelength of the single buffer.
		if ( json.buffers && json.buffers.length > 0 ) json.buffers[ 0 ].byteLength = blob.size;

		if ( options.binary == true ) {

			// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

			final reader = new FileReader();
			reader.readAsArrayBuffer( blob );
			reader.onloadend =() {

				// Binary chunk.
				final binaryChunk = getPaddedArrayBuffer( reader.result );
				final binaryChunkPrefix = new DataView( new ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				binaryChunkPrefix.setUint32( 0, binaryChunk.byteLength, true );
				binaryChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_BIN, true );

				// JSON chunk.
				final jsonChunk = getPaddedArrayBuffer( stringToArrayBuffer( JSON.stringify( json ) ), 0x20 );
				final jsonChunkPrefix = new DataView( new ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				jsonChunkPrefix.setUint32( 0, jsonChunk.byteLength, true );
				jsonChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_JSON, true );

				// GLB header.
				final header = new ArrayBuffer( GLB_HEADER_BYTES );
				final headerView = new DataView( header );
				headerView.setUint32( 0, GLB_HEADER_MAGIC, true );
				headerView.setUint32( 4, GLB_VERSION, true );
				final totalByteLength = GLB_HEADER_BYTES
					+ jsonChunkPrefix.byteLength + jsonChunk.byteLength
					+ binaryChunkPrefix.byteLength + binaryChunk.byteLength;
				headerView.setUint32( 8, totalByteLength, true );

				final glbBlob = new Blob( [
					header,
					jsonChunkPrefix,
					jsonChunk,
					binaryChunkPrefix,
					binaryChunk
				], { type: 'application/octet-stream' } );

				final glbReader = new FileReader();
				glbReader.readAsArrayBuffer( glbBlob );
				glbReader.onloadend =() {
					onDone( glbReader.result );
				};
			};
		} 
    else {
			if ( json.buffers && json.buffers.length > 0 ) {
				final reader = new FileReader();
				reader.readAsDataURL( blob );
				reader.onloadend =() {
					final base64data = reader.result;
					json.buffers[ 0 ].uri = base64data;
					onDone( json );
				};

			} 
      else {
				onDone( json );
			}
		}
	}

	/**
	 * Serializes a userData.
	 *
	 * @param {THREE.Object3D|THREE.Material} object
	 * @param {Object} objectDef
	 */
	serializeUserData( object, objectDef ) {

		if (object.userData.keys.length == 0 ) return;

		final options = this.options;
		final extensionsUsed = this.extensionsUsed;

		try {
			final json = JSON.parse( JSON.stringify( object.userData ) );
			if ( options.includeCustomExtensions && json.gltfExtensions ) {
				if ( objectDef.extensions == null ) objectDef.extensions = {};
				for ( final extensionName in json.gltfExtensions ) {
					objectDef.extensions[ extensionName ] = json.gltfExtensions[ extensionName ];
					extensionsUsed[ extensionName ] = true;
				}

				delete json.gltfExtensions;
			}

			if (json.keys.length > 0 ) objectDef.extras = json;
		} catch ( error ) {
			console.warning( 'THREE.GLTFExporter: userData of \'' + object.name + '\' ' +
				'won\'t be serialized because of JSON.stringify error - ' + error.message );
		}
	}

	/**
	 * Returns ids for buffer attributes.
	 * @param  {Object} object
	 * @return {Integer}
	 */
	getUID( attribute, [bool isRelativeCopy = false ]) {
		if ( this.uids.containsKey( attribute ) == false ) {
			final uids = new Map();

			uids.set( true, this.uid ++ );
			uids.set( false, this.uid ++ );

			this.uids.set( attribute, uids );
		}

		final uids = this.uids.get( attribute );

		return uids.get( isRelativeCopy );
	}

	/**
	 * Checks if normal attribute values are normalized.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {Boolean}
	 */
	isNormalizedNormalAttribute( normal ) {
		final cache = this.cache;

		if ( cache.attributesNormalized.has( normal ) ) return false;

		final v = new Vector3();

		for (int i = 0, il = normal.count; i < il; i ++ ) {
			// 0.0005 is from glTF-validator
			if (( v.fromBufferAttribute( normal, i ).length() - 1.0 ).abs() > 0.0005 ) return false;
		}

		return true;
	}

	/**
	 * Creates normalized normal buffer attribute.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {BufferAttribute}
	 *
	 */
	createNormalizedNormalAttribute( normal ) {

		final cache = this.cache;

		if ( cache.attributesNormalized.has( normal ) )	return cache.attributesNormalized.get( normal );

		final attribute = normal.clone();
		final v = new Vector3();

		for (int i = 0, il = attribute.count; i < il; i ++ ) {

			v.fromBufferAttribute( attribute, i );

			if ( v.x == 0 && v.y == 0 && v.z == 0 ) {

				// if values can't be normalized set (1, 0, 0)
				v.setX( 1.0 );

			} else {

				v.normalize();

			}

			attribute.setXYZ( i, v.x, v.y, v.z );

		}

		cache.attributesNormalized.set( normal, attribute );

		return attribute;

	}

	/**
	 * Applies a texture transform, if present, to the map definition. Requires
	 * the KHR_texture_transform extension.
	 *
	 * @param {Object} mapDef
	 * @param {THREE.Texture} texture
	 */
	applyTextureTransform( mapDef, texture ) {

		var didTransform = false;
		final transformDef = {};

		if ( texture.offset.x != 0 || texture.offset.y != 0 ) {

			transformDef.offset = texture.offset.toArray();
			didTransform = true;

		}

		if ( texture.rotation != 0 ) {

			transformDef.rotation = texture.rotation;
			didTransform = true;

		}

		if ( texture.repeat.x != 1 || texture.repeat.y != 1 ) {

			transformDef.scale = texture.repeat.toArray();
			didTransform = true;

		}

		if ( didTransform ) {

			mapDef.extensions = mapDef.extensions || {};
			mapDef.extensions[ 'KHR_texture_transform' ] = transformDef;
			this.extensionsUsed[ 'KHR_texture_transform' ] = true;

		}

	}

	buildMetalRoughTexture( metalnessMap, roughnessMap ) {

		if ( metalnessMap == roughnessMap ) return metalnessMap;

	getEncodingConversion( map ) {

			if ( map.colorSpace == SRGBColorSpace ) {

				returnSRGBToLinear( c ) {

					return ( c < 0.04045 ) ? c * 0.0773993808 : math.pow( c * 0.9478672986 + 0.0521327014, 2.4 );

				};

			}

			returnLinearToLinear( c ) {

				return c;

			};

		}

		console.warn( 'THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.' );

		if ( metalnessMap instanceof CompressedTexture ) {

			metalnessMap = decompress( metalnessMap );

		}

		if ( roughnessMap instanceof CompressedTexture ) {

			roughnessMap = decompress( roughnessMap );

		}

		final metalness = metalnessMap ? metalnessMap.image : null;
		final roughness = roughnessMap ? roughnessMap.image : null;

		final width = math.max( metalness ? metalness.width : 0, roughness ? roughness.width : 0 );
		final height = math.max( metalness ? metalness.height : 0, roughness ? roughness.height : 0 );

		final canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;

		final context = canvas.getContext( '2d' );
		context.fillStyle = '#00ffff';
		context.fillRect( 0, 0, width, height );

		final composite = context.getImageData( 0, 0, width, height );

		if ( metalness ) {

			context.drawImage( metalness, 0, 0, width, height );

			final convert = getEncodingConversion( metalnessMap );
			final data = context.getImageData( 0, 0, width, height ).data;

			for (int i = 2; i < data.length; i += 4 ) {

				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;

			}

		}

		if ( roughness ) {

			context.drawImage( roughness, 0, 0, width, height );

			final convert = getEncodingConversion( roughnessMap );
			final data = context.getImageData( 0, 0, width, height ).data;

			for (int i = 1; i < data.length; i += 4 ) {

				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;

			}

		}

		context.putImageData( composite, 0, 0 );

		//

		final reference = metalnessMap || roughnessMap;

		final texture = reference.clone();

		texture.source = new Source( canvas );
		texture.colorSpace = NoColorSpace;
		texture.channel = ( metalnessMap || roughnessMap ).channel;

		if ( metalnessMap && roughnessMap && metalnessMap.channel != roughnessMap.channel ) {

			console.warn( 'THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.' );

		}

		return texture;

	}

	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	processBuffer( buffer ) {

		final json = this.json;
		final buffers = this.buffers;

		if ( ! json.buffers ) json.buffers = [ { byteLength: 0 } ];

		// All buffers are merged before export.
		buffers.add( buffer );

		return 0;

	}

	/**
	 * Process and generate a BufferView
	 * @param  {BufferAttribute} attribute
	 * @param  {number} componentType
	 * @param  {number} start
	 * @param  {number} count
	 * @param  {number} target (Optional) Target usage of the BufferView
	 * @return {Object}
	 */
	processBufferView( attribute, componentType, start, count, target ) {

		final json = this.json;

		if ( ! json.bufferViews ) json.bufferViews = [];

		// Create a new dataview and dump the attribute's array into it

		var componentSize;

		switch ( componentType ) {

			case WEBGL_finalANTS.BYTE:
			case WEBGL_finalANTS.UNSIGNED_BYTE:

				componentSize = 1;

				break;

			case WEBGL_finalANTS.SHORT:
			case WEBGL_finalANTS.UNSIGNED_SHORT:

				componentSize = 2;

				break;

			default:

				componentSize = 4;

		}

		final byteLength = getPaddedBufferSize( count * attribute.itemSize * componentSize );
		final dataView = new DataView( new ArrayBuffer( byteLength ) );
		var offset = 0;

		for (int i = start; i < start + count; i ++ ) {

			for (int a = 0; a < attribute.itemSize; a ++ ) {

				var value;

				if ( attribute.itemSize > 4 ) {

					 // no support for interleaved data for itemSize > 4

					value = attribute.array[ i * attribute.itemSize + a ];

				} else {

					if ( a == 0 ) value = attribute.getX( i );
					else if ( a == 1 ) value = attribute.getY( i );
					else if ( a == 2 ) value = attribute.getZ( i );
					else if ( a == 3 ) value = attribute.getW( i );

					if ( attribute.normalized == true ) {

						value = MathUtils.normalize( value, attribute.array );

					}

				}

				if ( componentType == WEBGL_finalANTS.FLOAT ) {

					dataView.setFloat32( offset, value, true );

				} else if ( componentType == WEBGL_finalANTS.INT ) {

					dataView.setInt32( offset, value, true );

				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_INT ) {

					dataView.setUint32( offset, value, true );

				} else if ( componentType == WEBGL_finalANTS.SHORT ) {

					dataView.setInt16( offset, value, true );

				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_SHORT ) {

					dataView.setUint16( offset, value, true );

				} else if ( componentType == WEBGL_finalANTS.BYTE ) {

					dataView.setInt8( offset, value );

				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_BYTE ) {

					dataView.setUint8( offset, value );

				}

				offset += componentSize;

			}

		}

		final bufferViewDef = {

			buffer: this.processBuffer( dataView.buffer ),
			byteOffset: this.byteOffset,
			byteLength: byteLength

		};

		if ( target != null ) bufferViewDef.target = target;

		if ( target == WEBGL_finalANTS.ARRAY_BUFFER ) {

			// Only define byteStride for vertex attributes.
			bufferViewDef.byteStride = attribute.itemSize * componentSize;

		}

		this.byteOffset += byteLength;

		json.bufferViews.add( bufferViewDef );

		// @TODO Merge bufferViews where possible.
		final output = {

			id: json.bufferViews.length - 1,
			byteLength: 0

		};

		return output;

	}

	/**
	 * Process and generate a BufferView from an image Blob.
	 * @param {Blob} blob
	 * @return {Promise<Integer>}
	 */
	processBufferViewImage( blob ) {

		final writer = this;
		final json = writer.json;

		if ( ! json.bufferViews ) json.bufferViews = [];

		return new Promise(( resolve ) {

			final reader = new FileReader();
			reader.readAsArrayBuffer( blob );
			reader.onloadend =() {

				final buffer = getPaddedArrayBuffer( reader.result );

				final bufferViewDef = {
					buffer: writer.processBuffer( buffer ),
					byteOffset: writer.byteOffset,
					byteLength: buffer.byteLength
				};

				writer.byteOffset += buffer.byteLength;
				resolve( json.bufferViews.add( bufferViewDef ) - 1 );

			};

		} );

	}

	/**
	 * Process attribute to generate an accessor
	 * @param  {BufferAttribute} attribute Attribute to process
	 * @param  {THREE.BufferGeometry} geometry (Optional) Geometry used for truncated draw range
	 * @param  {Integer} start (Optional)
	 * @param  {Integer} count (Optional)
	 * @return {Integer|null} Index of the processed accessor on the "accessors" array
	 */
	processAccessor( attribute, geometry, start, count ) {

		final json = this.json;

		final types = {

			1: 'SCALAR',
			2: 'VEC2',
			3: 'VEC3',
			4: 'VEC4',
			9: 'MAT3',
			16: 'MAT4'

		};

		var componentType;

		// Detect the component type of the attribute array
		if ( attribute.array.finalructor == Float32Array ) {

			componentType = WEBGL_finalANTS.FLOAT;

		} else if ( attribute.array.finalructor == Int32Array ) {

			componentType = WEBGL_finalANTS.INT;

		} else if ( attribute.array.finalructor == Uint32Array ) {

			componentType = WEBGL_finalANTS.UNSIGNED_INT;

		} else if ( attribute.array.finalructor == Int16Array ) {

			componentType = WEBGL_finalANTS.SHORT;

		} else if ( attribute.array.finalructor == Uint16Array ) {

			componentType = WEBGL_finalANTS.UNSIGNED_SHORT;

		} else if ( attribute.array.finalructor == Int8Array ) {

			componentType = WEBGL_finalANTS.BYTE;

		} else if ( attribute.array.finalructor == Uint8Array ) {

			componentType = WEBGL_finalANTS.UNSIGNED_BYTE;

		} else {

			throw new Error( 'THREE.GLTFExporter: Unsupported bufferAttribute component type: ' + attribute.array.finalructor.name );

		}

		if ( start == null ) start = 0;
		if ( count == null || count == Infinity ) count = attribute.count;

		// Skip creating an accessor if the attribute doesn't have data to export
		if ( count == 0 ) return null;

		final minMax = getMinMax( attribute, start, count );
		var bufferViewTarget;

		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if ( geometry != null ) {

			bufferViewTarget = attribute == geometry.index ? WEBGL_finalANTS.ELEMENT_ARRAY_BUFFER : WEBGL_finalANTS.ARRAY_BUFFER;

		}

		final bufferView = this.processBufferView( attribute, componentType, start, count, bufferViewTarget );

		final accessorDef = {

			bufferView: bufferView.id,
			byteOffset: bufferView.byteOffset,
			componentType: componentType,
			count: count,
			max: minMax.max,
			min: minMax.min,
			type: types[ attribute.itemSize ]

		};

		if ( attribute.normalized == true ) accessorDef.normalized = true;
		if ( ! json.accessors ) json.accessors = [];

		return json.accessors.add( accessorDef ) - 1;

	}

	/**
	 * Process image
	 * @param  {Image} image to process
	 * @param  {Integer} format of the image (RGBAFormat)
	 * @param  {Boolean} flipY before writing out the image
	 * @param  {String} mimeType export format
	 * @return {Integer}     Index of the processed texture in the "images" array
	 */
	processImage( image, format, flipY, mimeType = 'image/png' ) {

		if ( image != null ) {

			final writer = this;
			final cache = writer.cache;
			final json = writer.json;
			final options = writer.options;
			final pending = writer.pending;

			if ( ! cache.images.has( image ) ) cache.images.set( image, {} );

			final cachedImages = cache.images.get( image );

			final key = mimeType + ':flipY/' + flipY.toString();

			if ( cachedImages[ key ] != null ) return cachedImages[ key ];

			if ( ! json.images ) json.images = [];

			final imageDef = { mimeType: mimeType };

			final canvas = getCanvas();

			canvas.width = math.min( image.width, options.maxTextureSize );
			canvas.height = math.min( image.height, options.maxTextureSize );

			final ctx = canvas.getContext( '2d' );

			if ( flipY == true ) {

				ctx.translate( 0, canvas.height );
				ctx.scale( 1, - 1 );

			}

			if ( image.data != null ) { // THREE.DataTexture

				if ( format != RGBAFormat ) {

					console.error( 'GLTFExporter: Only RGBAFormat is supported.', format );

				}

				if ( image.width > options.maxTextureSize || image.height > options.maxTextureSize ) {

					console.warn( 'GLTFExporter: Image size is bigger than maxTextureSize', image );

				}

				final data = new Uint8ClampedArray( image.height * image.width * 4 );

				for (int i = 0; i < data.length; i += 4 ) {

					data[ i + 0 ] = image.data[ i + 0 ];
					data[ i + 1 ] = image.data[ i + 1 ];
					data[ i + 2 ] = image.data[ i + 2 ];
					data[ i + 3 ] = image.data[ i + 3 ];

				}

				ctx.putImageData( new ImageData( data, image.width, image.height ), 0, 0 );

			} else {

				ctx.drawImage( image, 0, 0, canvas.width, canvas.height );

			}

			if ( options.binary == true ) {

				pending.add(

					getToBlobPromise( canvas, mimeType )
						.then( blob => writer.processBufferViewImage( blob ) )
						.then( bufferViewIndex => {

							imageDef.bufferView = bufferViewIndex;

						} )

				);

			} else {

				if ( canvas.toDataURL != null ) {

					imageDef.uri = canvas.toDataURL( mimeType );

				} else {

					pending.add(

						getToBlobPromise( canvas, mimeType )
							.then( blob => new FileReader().readAsDataURL( blob ) )
							.then( dataURL => {

								imageDef.uri = dataURL;

							} )

					);

				}

			}

			final index = json.images.add( imageDef ) - 1;
			cachedImages[ key ] = index;
			return index;

		} else {

			throw new Error( 'THREE.GLTFExporter: No valid image data found. Unable to process texture.' );

		}

	}

	/**
	 * Process sampler
	 * @param  {Texture} map Texture to process
	 * @return {Integer}     Index of the processed texture in the "samplers" array
	 */
	processSampler( map ) {

		final json = this.json;

		if ( ! json.samplers ) json.samplers = [];

		final samplerDef = {
			'magFilter': THREE_TO_WEBGL[ map.magFilter ],
			'minFilter': THREE_TO_WEBGL[ map.minFilter ],
			'wrapS': THREE_TO_WEBGL[ map.wrapS ],
			'wrapT': THREE_TO_WEBGL[ map.wrapT ]
		};

		return json.samplers.add( samplerDef ) - 1;

	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	processTexture( map ) {

		final writer = this;
		final options = writer.options;
		final cache = this.cache;
		final json = this.json;

		if ( cache.textures.has( map ) ) return cache.textures.get( map );

		if ( ! json.textures ) json.textures = [];

		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
		if ( map instanceof CompressedTexture ) {

			map = decompress( map, options.maxTextureSize );

		}

		var mimeType = map.userData.mimeType;

		if ( mimeType == 'image/webp' ) mimeType = 'image/png';

		final textureDef = {
			'sampler': this.processSampler( map ),
			'source': this.processImage( map.image, map.format, map.flipY, mimeType )
		};

		if ( map.name ) textureDef.name = map.name;

		this._invokeAll(( ext ) {

			ext.writeTexture && ext.writeTexture( map, textureDef );

		} );

		final index = json.textures.add( textureDef ) - 1;
		cache.textures.set( map, index );
		return index;

	}

	/**
	 * Process material
	 * @param  {THREE.Material} material Material to process
	 * @return {Integer|null} Index of the processed material in the "materials" array
	 */
	processMaterial( material ) {
		final cache = this.cache;
		final json = this.json;

		if ( cache['materials'].has( material ) ) return cache.materials.get( material );

		if ( material is ShaderMaterial ) {
			console.warning( 'GLTFExporter: THREE.ShaderMaterial not supported.' );
			return null;
		}

		if (json['materials'] == null) json['materials'] = [];
		// @QUESTION Should we avoid including any attribute that has the default value?
		final Map<String,dynamic> materialDef = {	'pbrMetallicRoughness': {} };

		if ( material.isMeshStandardMaterial != true && material.isMeshBasicMaterial != true ) {
			console.warning( 'GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.' );
		}

		// pbrMetallicRoughness.baseColorFactor
		final color = material.color.toArray().concat( [ material.opacity ] );

		if ( ! equalArray( color, [ 1, 1, 1, 1 ] ) ) {

			materialDef.pbrMetallicRoughness.baseColorFactor = color;

		}

		if ( material.isMeshStandardMaterial ) {

			materialDef.pbrMetallicRoughness.metallicFactor = material.metalness;
			materialDef.pbrMetallicRoughness.roughnessFactor = material.roughness;

		} else {

			materialDef.pbrMetallicRoughness.metallicFactor = 0.5;
			materialDef.pbrMetallicRoughness.roughnessFactor = 0.5;

		}

		// pbrMetallicRoughness.metallicRoughnessTexture
		if ( material.metalnessMap || material.roughnessMap ) {

			final metalRoughTexture = this.buildMetalRoughTexture( material.metalnessMap, material.roughnessMap );

			final metalRoughMapDef = {
				index: this.processTexture( metalRoughTexture ),
				channel: metalRoughTexture.channel
			};
			this.applyTextureTransform( metalRoughMapDef, metalRoughTexture );
			materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;

		}

		// pbrMetallicRoughness.baseColorTexture
		if ( material.map ) {

			final baseColorMapDef = {
				index: this.processTexture( material.map ),
				texCoord: material.map.channel
			};
			this.applyTextureTransform( baseColorMapDef, material.map );
			materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;

		}

		if ( material.emissive ) {

			final emissive = material.emissive;
			final maxEmissiveComponent = math.max( emissive.r, emissive.g, emissive.b );

			if ( maxEmissiveComponent > 0 ) {

				materialDef.emissiveFactor = material.emissive.toArray();

			}

			// emissiveTexture
			if ( material.emissiveMap ) {

				final emissiveMapDef = {
					index: this.processTexture( material.emissiveMap ),
					texCoord: material.emissiveMap.channel
				};
				this.applyTextureTransform( emissiveMapDef, material.emissiveMap );
				materialDef.emissiveTexture = emissiveMapDef;

			}

		}

		// normalTexture
		if ( material.normalMap ) {

			final normalMapDef = {
				index: this.processTexture( material.normalMap ),
				texCoord: material.normalMap.channel
			};

			if ( material.normalScale && material.normalScale.x != 1 ) {

				// glTF normal scale is univariate. Ignore `y`, which may be flipped.
				// Context: https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
				normalMapDef.scale = material.normalScale.x;

			}

			this.applyTextureTransform( normalMapDef, material.normalMap );
			materialDef.normalTexture = normalMapDef;

		}

		// occlusionTexture
		if ( material.aoMap ) {

			final occlusionMapDef = {
				index: this.processTexture( material.aoMap ),
				texCoord: material.aoMap.channel
			};

			if ( material.aoMapIntensity != 1.0 ) {

				occlusionMapDef.strength = material.aoMapIntensity;

			}

			this.applyTextureTransform( occlusionMapDef, material.aoMap );
			materialDef.occlusionTexture = occlusionMapDef;

		}

		// alphaMode
		if ( material.transparent ) {
			materialDef.alphaMode = 'BLEND';
		} 
    else {
			if ( material.alphaTest > 0.0 ) {
				materialDef.alphaMode = 'MASK';
				materialDef.alphaCutoff = material.alphaTest;
			}
		}

		// doubleSided
		if ( material.side == DoubleSide ) materialDef.doubleSided = true;
		if ( material.name != '' ) materialDef.name = material.name;

		this.serializeUserData( material, materialDef );

		this._invokeAll(( ext ) {

			ext.writeMaterial && ext.writeMaterial( material, materialDef );

		} );

		final index = json.materials.add( materialDef ) - 1;
		cache.materials.set( material, index );
		return index;

	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	processMesh( mesh ) {
		final cache = this.cache;
		final json = this.json;

		final meshCacheKeyParts = [ mesh.geometry.uuid ];

		if (mesh.material is GroupMaterial) {
			for (int i = 0, l = mesh.material.length; i < l; i ++ ) {
				meshCacheKeyParts.add( mesh.material[ i ].uuid	);
			}
		} else {
			meshCacheKeyParts.add( mesh.material.uuid );
		}

		final meshCacheKey = meshCacheKeyParts.join( ':' );

		if ( cache.meshes.has( meshCacheKey ) ) return cache.meshes.get( meshCacheKey );

		final geometry = mesh.geometry;

		var mode;

		// Use the correct mode
		if ( mesh.isLineSegments ) {

			mode = WEBGL_finalANTS.LINES;

		} else if ( mesh.isLineLoop ) {

			mode = WEBGL_finalANTS.LINE_LOOP;

		} else if ( mesh.isLine ) {

			mode = WEBGL_finalANTS.LINE_STRIP;

		} else if ( mesh.isPoints ) {

			mode = WEBGL_finalANTS.POINTS;

		} else {

			mode = mesh.material.wireframe ? WEBGL_finalANTS.LINES : WEBGL_finalANTS.TRIANGLES;

		}

		final meshDef = {};
		final attributes = {};
		final primitives = [];
		final targets = [];

		// Conversion between attributes names in threejs and gltf spec
		final nameConversion = {
			'uv': 'TEXCOORD_0',
			'uv1': 'TEXCOORD_1',
			'uv2': 'TEXCOORD_2',
			'uv3': 'TEXCOORD_3',
			'color': 'COLOR_0',
			'skinWeight': 'WEIGHTS_0',
			'skinIndex': 'JOINTS_0'
		};

		final originalNormal = geometry.getAttribute( 'normal' );

		if ( originalNormal != null && ! this.isNormalizedNormalAttribute( originalNormal ) ) {

			console.warning( 'THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.' );

			geometry.setAttribute( 'normal', this.createNormalizedNormalAttribute( originalNormal ) );

		}

		// @QUESTION Detect if .vertexColors = true?
		// For every attribute create an accessor
		var modifiedAttribute = null;

		for (int attributeName in geometry.attributes ) {

			// Ignore morph target attributes, which are exported later.
			if ( attributeName.slice( 0, 5 ) == 'morph' ) continue;

			final attribute = geometry.attributes[ attributeName ];
			attributeName = nameConversion[ attributeName ] || attributeName.toUpperCase();

			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
			final validVertexAttributes =
					/^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;

			if ( ! validVertexAttributes.test( attributeName ) ) attributeName = '_' + attributeName;

			if ( cache.attributes.has( this.getUID( attribute ) ) ) {

				attributes[ attributeName ] = cache.attributes.get( this.getUID( attribute ) );
				continue;

			}

			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			final array = attribute.array;

			if ( attributeName == 'JOINTS_0' &&
				! ( array is Uint16Array ) &&
				! ( array is Uint8Array ) ) {

				console.warn( 'GLTFExporter: Attribute "skinIndex" converted to type UNSIGNED_SHORT.' );
				modifiedAttribute = new BufferAttribute( new Uint16Array( array ), attribute.itemSize, attribute.normalized );

			}

			final accessor = this.processAccessor( modifiedAttribute || attribute, geometry );

			if ( accessor != null ) {

				if ( ! attributeName.startsWith( '_' ) ) {

					this.detectMeshQuantization( attributeName, attribute );

				}

				attributes[ attributeName ] = accessor;
				cache.attributes.set( this.getUID( attribute ), accessor );

			}

		}

		if ( originalNormal != null ) geometry.setAttribute( 'normal', originalNormal );

		// Skip if no exportable attributes found
		if ( Object.keys( attributes ).length == 0 ) return null;

		// Morph targets
		if ( mesh.morphTargetInfluences != null && mesh.morphTargetInfluences.length > 0 ) {

			final weights = [];
			final targetNames = [];
			final reverseDictionary = {};

			if ( mesh.morphTargetDictionary != null ) {

				for ( final key in mesh.morphTargetDictionary ) {

					reverseDictionary[ mesh.morphTargetDictionary[ key ] ] = key;

				}

			}

			for (int i = 0; i < mesh.morphTargetInfluences.length; ++ i ) {

				final target = {};
				var warned = false;

				for ( final attributeName in geometry.morphAttributes ) {

					// glTF 2.0 morph supports only POSITION/NORMAL/TANGENT.
					// Three.js doesn't support TANGENT yet.

					if ( attributeName != 'position' && attributeName != 'normal' ) {

						if ( ! warned ) {

							console.warn( 'GLTFExporter: Only POSITION and NORMAL morph are supported.' );
							warned = true;

						}

						continue;

					}

					final attribute = geometry.morphAttributes[ attributeName ][ i ];
					final gltfAttributeName = attributeName.toUpperCase();

					// Three.js morph attribute has absolute values while the one of glTF has relative values.
					//
					// glTF 2.0 Specification:
					// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets

					final baseAttribute = geometry.attributes[ attributeName ];

					if ( cache.attributes.has( this.getUID( attribute, true ) ) ) {

						target[ gltfAttributeName ] = cache.attributes.get( this.getUID( attribute, true ) );
						continue;

					}

					// Clones attribute not to override
					final relativeAttribute = attribute.clone();

					if ( ! geometry.morphTargetsRelative ) {

						for (int j = 0, jl = attribute.count; j < jl; j ++ ) {

							for (int a = 0; a < attribute.itemSize; a ++ ) {

								if ( a == 0 ) relativeAttribute.setX( j, attribute.getX( j ) - baseAttribute.getX( j ) );
								if ( a == 1 ) relativeAttribute.setY( j, attribute.getY( j ) - baseAttribute.getY( j ) );
								if ( a == 2 ) relativeAttribute.setZ( j, attribute.getZ( j ) - baseAttribute.getZ( j ) );
								if ( a == 3 ) relativeAttribute.setW( j, attribute.getW( j ) - baseAttribute.getW( j ) );

							}

						}

					}

					target[ gltfAttributeName ] = this.processAccessor( relativeAttribute, geometry );
					cache.attributes.set( this.getUID( baseAttribute, true ), target[ gltfAttributeName ] );

				}

				targets.add( target );

				weights.add( mesh.morphTargetInfluences[ i ] );

				if ( mesh.morphTargetDictionary != null ) targetNames.add( reverseDictionary[ i ] );

			}

			meshDef.weights = weights;

			if ( targetNames.length > 0 ) {

				meshDef.extras = {};
				meshDef.extras.targetNames = targetNames;

			}

		}

		final isMultiMaterial = Array.isArray( mesh.material );

		if ( isMultiMaterial && geometry.groups.length == 0 ) return null;

		final materials = isMultiMaterial ? mesh.material : [ mesh.material ];
		final groups = isMultiMaterial ? geometry.groups : [ { materialIndex: 0, start: null, count: null } ];

		for (int i = 0, il = groups.length; i < il; i ++ ) {

			final primitive = {
				mode: mode,
				attributes: attributes,
			};

			this.serializeUserData( geometry, primitive );

			if ( targets.length > 0 ) primitive.targets = targets;

			if ( geometry.index != null ) {

				var cacheKey = this.getUID( geometry.index );

				if ( groups[ i ].start != null || groups[ i ].count != null ) {

					cacheKey += ':' + groups[ i ].start + ':' + groups[ i ].count;

				}

				if ( cache.attributes.has( cacheKey ) ) {

					primitive.indices = cache.attributes.get( cacheKey );

				} else {

					primitive.indices = this.processAccessor( geometry.index, geometry, groups[ i ].start, groups[ i ].count );
					cache.attributes.set( cacheKey, primitive.indices );

				}

				if ( primitive.indices == null ) delete primitive.indices;

			}

			final material = this.processMaterial( materials[ groups[ i ].materialIndex ] );

			if ( material != null ) primitive.material = material;

			primitives.add( primitive );

		}

		meshDef.primitives = primitives;

		if ( ! json.meshes ) json.meshes = [];

		this._invokeAll(( ext ) {

			ext.writeMesh && ext.writeMesh( mesh, meshDef );

		} );

		final index = json.meshes.add( meshDef ) - 1;
		cache.meshes.set( meshCacheKey, index );
		return index;

	}

	/**
	 * If a vertex attribute with a
	 * [non-standard data type](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes-overview)
	 * is used, it is checked whether it is a valid data type according to the
	 * [KHR_mesh_quantization](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md)
	 * extension.
	 * In this case the extension is automatically added to the list of used extensions.
	 *
	 * @param {string} attributeName
	 * @param {THREE.BufferAttribute} attribute
	 */
	detectMeshQuantization( attributeName, attribute ) {

		if ( this.extensionsUsed[ KHR_MESH_QUANTIZATION ] ) return;

		var attrType = null;

		switch ( attribute.array.finalructor ) {

			case Int8Array:

				attrType = 'byte';

				break;

			case Uint8Array:

				attrType = 'unsigned byte';

				break;

			case Int16Array:

				attrType = 'short';

				break;

			case Uint16Array:

				attrType = 'unsigned short';

				break;

			default:

				return;

		}

		if ( attribute.normalized ) attrType += ' normalized';

		final attrNamePrefix = attributeName.split( '_', 1 )[ 0 ];

		if ( KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ] && KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ].includes( attrType ) ) {

			this.extensionsUsed[ KHR_MESH_QUANTIZATION ] = true;
			this.extensionsRequired[ KHR_MESH_QUANTIZATION ] = true;

		}

	}

	/**
	 * Process camera
	 * @param  {THREE.Camera} camera Camera to process
	 * @return {Integer}      Index of the processed mesh in the "camera" array
	 */
	processCamera( camera ) {

		final json = this.json;

		if ( ! json.cameras ) json.cameras = [];

		final isOrtho = camera.isOrthographicCamera;

		final cameraDef = {
			type: isOrtho ? 'orthographic' : 'perspective'
		};

		if ( isOrtho ) {

			cameraDef.orthographic = {
				xmag: camera.right * 2,
				ymag: camera.top * 2,
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};

		} else {

			cameraDef.perspective = {
				aspectRatio: camera.aspect,
				yfov: MathUtils.degToRad( camera.fov ),
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};

		}

		// Question: Is saving "type" as name intentional?
		if ( camera.name != '' ) cameraDef.name = camera.type;

		return json.cameras.add( cameraDef ) - 1;

	}

	/**
	 * Creates glTF animation entry from AnimationClip object.
	 *
	 * Status:
	 * - Only properties listed in PATH_PROPERTIES may be animated.
	 *
	 * @param {THREE.AnimationClip} clip
	 * @param {THREE.Object3D} root
	 * @return {number|null}
	 */
	processAnimation( clip, root ) {

		final json = this.json;
		final nodeMap = this.nodeMap;

		if ( ! json.animations ) json.animations = [];

		clip = GLTFExporter.Utils.mergeMorphTargetTracks( clip.clone(), root );

		final tracks = clip.tracks;
		final channels = [];
		final samplers = [];

		for (int i = 0; i < tracks.length; ++ i ) {

			final track = tracks[ i ];
			final trackBinding = PropertyBinding.parseTrackName( track.name );
			var trackNode = PropertyBinding.findNode( root, trackBinding.nodeName );
			final trackProperty = PATH_PROPERTIES[ trackBinding.propertyName ];

			if ( trackBinding.objectName == 'bones' ) {

				if ( trackNode.isSkinnedMesh == true ) {

					trackNode = trackNode.skeleton.getBoneByName( trackBinding.objectIndex );

				} else {

					trackNode = null;

				}

			}

			if ( ! trackNode || ! trackProperty ) {

				console.warn( 'THREE.GLTFExporter: Could not export animation track "%s".', track.name );
				return null;

			}

			final inputItemSize = 1;
			var outputItemSize = track.values.length / track.times.length;

			if ( trackProperty == PATH_PROPERTIES.morphTargetInfluences ) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}

			var interpolation;

			// @TODO export CubicInterpolant(InterpolateSmooth) as CUBICSPLINE

			// Detecting glTF cubic spline interpolant by checking factory method's special property
			// GLTFCubicSplineInterpolant is a custom interpolant and track doesn't return
			// valid value from .getInterpolation().
			if ( track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline == true ) {

				interpolation = 'CUBICSPLINE';

				// itemSize of CUBICSPLINE keyframe is 9
				// (VEC3 * 3: inTangent, splineVertex, and outTangent)
				// but needs to be stored as VEC3 so dividing by 3 here.
				outputItemSize /= 3;

			} else if ( track.getInterpolation() == InterpolateDiscrete ) {

				interpolation = 'STEP';

			} else {

				interpolation = 'LINEAR';

			}

			samplers.add( {
				input: this.processAccessor( new BufferAttribute( track.times, inputItemSize ) ),
				output: this.processAccessor( new BufferAttribute( track.values, outputItemSize ) ),
				interpolation: interpolation
			} );

			channels.add( {
				sampler: samplers.length - 1,
				target: {
					node: nodeMap.get( trackNode ),
					path: trackProperty
				}
			} );

		}

		json.animations.add( {
			name: clip.name || 'clip_' + json.animations.length,
			samplers: samplers,
			channels: channels
		} );

		return json.animations.length - 1;

	}

	/**
	 * @param {THREE.Object3D} object
	 * @return {number|null}
	 */
	 processSkin( object ) {

		final json = this.json;
		final nodeMap = this.nodeMap;

		final node = json.nodes[ nodeMap.get( object ) ];

		final skeleton = object.skeleton;

		if ( skeleton == null ) return null;

		final rootJoint = object.skeleton.bones[ 0 ];

		if ( rootJoint == null ) return null;

		final joints = [];
		final inverseBindMatrices = new Float32Array( skeleton.bones.length * 16 );
		final temporaryBoneInverse = new Matrix4();

		for (int i = 0; i < skeleton.bones.length; ++ i ) {

			joints.add( nodeMap.get( skeleton.bones[ i ] ) );
			temporaryBoneInverse.copy( skeleton.boneInverses[ i ] );
			temporaryBoneInverse.multiply( object.bindMatrix ).toArray( inverseBindMatrices, i * 16 );

		}

		if ( json.skins == null ) json.skins = [];

		json.skins.add( {
			inverseBindMatrices: this.processAccessor( new BufferAttribute( inverseBindMatrices, 16 ) ),
			joints: joints,
			skeleton: nodeMap.get( rootJoint )
		} );

		final skinIndex = node.skin = json.skins.length - 1;

		return skinIndex;

	}

	/**
	 * Process Object3D node
	 * @param  {THREE.Object3D} node Object3D to processNode
	 * @return {Integer} Index of the node in the nodes list
	 */
	processNode( object ) {

		final json = this.json;
		final options = this.options;
		final nodeMap = this.nodeMap;

		if ( ! json.nodes ) json.nodes = [];

		final nodeDef = {};

		if ( options.trs ) {

			final rotation = object.quaternion.toArray();
			final position = object.position.toArray();
			final scale = object.scale.toArray();

			if ( ! equalArray( rotation, [ 0, 0, 0, 1 ] ) ) {

				nodeDef.rotation = rotation;

			}

			if ( ! equalArray( position, [ 0, 0, 0 ] ) ) {

				nodeDef.translation = position;

			}

			if ( ! equalArray( scale, [ 1, 1, 1 ] ) ) {

				nodeDef.scale = scale;

			}

		} else {

			if ( object.matrixAutoUpdate ) {

				object.updateMatrix();

			}

			if ( isIdentityMatrix( object.matrix ) == false ) {

				nodeDef.matrix = object.matrix.elements;

			}

		}

		// We don't export empty strings name because it represents no-name in Three.js.
		if ( object.name != '' ) nodeDef.name = String( object.name );

		this.serializeUserData( object, nodeDef );

		if ( object.isMesh || object.isLine || object.isPoints ) {

			final meshIndex = this.processMesh( object );

			if ( meshIndex != null ) nodeDef.mesh = meshIndex;

		} else if ( object.isCamera ) {

			nodeDef.camera = this.processCamera( object );

		}

		if ( object.isSkinnedMesh ) this.skins.add( object );

		if ( object.children.length > 0 ) {

			final children = [];

			for (int i = 0, l = object.children.length; i < l; i ++ ) {

				final child = object.children[ i ];

				if ( child.visible || options.onlyVisible == false ) {

					final nodeIndex = this.processNode( child );

					if ( nodeIndex != null ) children.add( nodeIndex );

				}

			}

			if ( children.length > 0 ) nodeDef.children = children;

		}

		this._invokeAll(( ext ) {

			ext.writeNode && ext.writeNode( object, nodeDef );

		} );

		final nodeIndex = json.nodes.add( nodeDef ) - 1;
		nodeMap.set( object, nodeIndex );
		return nodeIndex;

	}

	/**
	 * Process Scene
	 * @param  {Scene} node Scene to process
	 */
	processScene( scene ) {

		final json = this.json;
		final options = this.options;

		if ( ! json.scenes ) {

			json.scenes = [];
			json.scene = 0;

		}

		final sceneDef = {};

		if ( scene.name != '' ) sceneDef.name = scene.name;

		json.scenes.add( sceneDef );

		final nodes = [];

		for (int i = 0, l = scene.children.length; i < l; i ++ ) {

			final child = scene.children[ i ];

			if ( child.visible || options.onlyVisible == false ) {

				final nodeIndex = this.processNode( child );

				if ( nodeIndex != null ) nodes.add( nodeIndex );

			}

		}

		if ( nodes.length > 0 ) sceneDef.nodes = nodes;

		this.serializeUserData( scene, sceneDef );

	}

	/**
	 * Creates a Scene to hold a list of objects and parse it
	 * @param  {Array} objects List of objects to process
	 */
	processObjects( objects ) {

		final scene = new Scene();
		scene.name = 'AuxScene';

		for (int i = 0; i < objects.length; i ++ ) {

			// We push directly to children instead of calling `add` to prevent
			// modify the .parent and break its original scene and hierarchy
			scene.children.add( objects[ i ] );

		}

		this.processScene( scene );

	}

	/**
	 * @param {THREE.Object3D|Array<THREE.Object3D>} input
	 */
	processInput( input ) {

		final options = this.options;

		input = input instanceof Array ? input : [ input ];

		this._invokeAll(( ext ) {

			ext.beforeParse && ext.beforeParse( input );

		} );

		final objectsWithoutScene = [];

		for (int i = 0; i < input.length; i ++ ) {

			if ( input[ i ] instanceof Scene ) {

				this.processScene( input[ i ] );

			} else {

				objectsWithoutScene.add( input[ i ] );

			}

		}

		if ( objectsWithoutScene.length > 0 ) this.processObjects( objectsWithoutScene );

		for (int i = 0; i < this.skins.length; ++ i ) {
			this.processSkin( this.skins[ i ] );
		}

		for (int i = 0; i < options.animations.length; ++ i ) {
			this.processAnimation( options.animations[ i ], input[ 0 ] );
		}

		this._invokeAll(( ext ) {
			ext.afterParse && ext.afterParse( input );
		} );
	}

	_invokeAll( func ) {
		for (int i = 0, il = this.plugins.length; i < il; i ++ ) {
			func( this.plugins[ i ] );
		}
	}
}

/**
 * Punctual Lights Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_lights_punctual
 */
class GLTFLightExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_lights_punctual';

	}

	writeNode( light, nodeDef ) {

		if ( ! light.isLight ) return;

		if ( ! light.isDirectionalLight && ! light.isPointLight && ! light.isSpotLight ) {

			console.warn( 'THREE.GLTFExporter: Only directional, point, and spot lights are supported.', light );
			return;

		}

		final writer = this.writer;
		final json = writer.json;
		final extensionsUsed = writer.extensionsUsed;

		final lightDef = {};

		if ( light.name ) lightDef.name = light.name;

		lightDef.color = light.color.toArray();

		lightDef.intensity = light.intensity;

		if ( light.isDirectionalLight ) {

			lightDef.type = 'directional';

		} else if ( light.isPointLight ) {

			lightDef.type = 'point';

			if ( light.distance > 0 ) lightDef.range = light.distance;

		} else if ( light.isSpotLight ) {

			lightDef.type = 'spot';

			if ( light.distance > 0 ) lightDef.range = light.distance;

			lightDef.spot = {};
			lightDef.spot.innerConeAngle = ( 1.0 - light.penumbra ) * light.angle;
			lightDef.spot.outerConeAngle = light.angle;

		}

		if ( light.decay != null && light.decay != 2 ) {

			console.warn( 'THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, '
				+ 'and expects light.decay=2.' );

		}

		if ( light.target
				&& ( light.target.parent != light
				|| light.target.position.x != 0
				|| light.target.position.y != 0
				|| light.target.position.z != - 1 ) ) {

			console.warn( 'THREE.GLTFExporter: Light direction may be lost. For best results, '
				+ 'make light.target a child of the light with position 0,0,-1.' );

		}

		if ( ! extensionsUsed[ this.name ] ) {

			json.extensions = json.extensions || {};
			json.extensions[ this.name ] = { lights: [] };
			extensionsUsed[ this.name ] = true;

		}

		final lights = json.extensions[ this.name ].lights;
		lights.add( lightDef );

		nodeDef.extensions = nodeDef.extensions || {};
		nodeDef.extensions[ this.name ] = { light: lights.length - 1 };

	}

}

/**
 * Unlit Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_unlit
 */
class GLTFMaterialsUnlitExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_unlit';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshBasicMaterial ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = {};

		extensionsUsed[ this.name ] = true;

		materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
		materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;

	}

}

/**
 * Clearcoat Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_clearcoat
 */
class GLTFMaterialsClearcoatExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_clearcoat';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.clearcoat == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.clearcoatFactor = material.clearcoat;

		if ( material.clearcoatMap ) {

			final clearcoatMapDef = {
				index: writer.processTexture( material.clearcoatMap ),
				texCoord: material.clearcoatMap.channel
			};
			writer.applyTextureTransform( clearcoatMapDef, material.clearcoatMap );
			extensionDef.clearcoatTexture = clearcoatMapDef;

		}

		extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

		if ( material.clearcoatRoughnessMap ) {

			final clearcoatRoughnessMapDef = {
				index: writer.processTexture( material.clearcoatRoughnessMap ),
				texCoord: material.clearcoatRoughnessMap.channel
			};
			writer.applyTextureTransform( clearcoatRoughnessMapDef, material.clearcoatRoughnessMap );
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;

		}

		if ( material.clearcoatNormalMap ) {

			final clearcoatNormalMapDef = {
				index: writer.processTexture( material.clearcoatNormalMap ),
				texCoord: material.clearcoatNormalMap.channel
			};
			writer.applyTextureTransform( clearcoatNormalMapDef, material.clearcoatNormalMap );
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;


	}

}

/**
 * Iridescence Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_iridescence
 */
class GLTFMaterialsIridescenceExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_iridescence';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.iridescence == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.iridescenceFactor = material.iridescence;

		if ( material.iridescenceMap ) {

			final iridescenceMapDef = {
				index: writer.processTexture( material.iridescenceMap ),
				texCoord: material.iridescenceMap.channel
			};
			writer.applyTextureTransform( iridescenceMapDef, material.iridescenceMap );
			extensionDef.iridescenceTexture = iridescenceMapDef;

		}

		extensionDef.iridescenceIor = material.iridescenceIOR;
		extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[ 0 ];
		extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[ 1 ];

		if ( material.iridescenceThicknessMap ) {

			final iridescenceThicknessMapDef = {
				index: writer.processTexture( material.iridescenceThicknessMap ),
				texCoord: material.iridescenceThicknessMap.channel
			};
			writer.applyTextureTransform( iridescenceThicknessMapDef, material.iridescenceThicknessMap );
			extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Transmission Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_transmission
 */
class GLTFMaterialsTransmissionExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_transmission';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.transmissionFactor = material.transmission;

		if ( material.transmissionMap ) {

			final transmissionMapDef = {
				index: writer.processTexture( material.transmissionMap ),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform( transmissionMapDef, material.transmissionMap );
			extensionDef.transmissionTexture = transmissionMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Materials Volume Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_volume
 */
class GLTFMaterialsVolumeExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_volume';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.thicknessFactor = material.thickness;

		if ( material.thicknessMap ) {

			final thicknessMapDef = {
				index: writer.processTexture( material.thicknessMap ),
				texCoord: material.thicknessMap.channel
			};
			writer.applyTextureTransform( thicknessMapDef, material.thicknessMap );
			extensionDef.thicknessTexture = thicknessMapDef;

		}

		extensionDef.attenuationDistance = material.attenuationDistance;
		extensionDef.attenuationColor = material.attenuationColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Materials ior Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_ior
 */
class GLTFMaterialsIorExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_ior';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.ior == 1.5 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.ior = material.ior;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Materials specular Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_specular
 */
class GLTFMaterialsSpecularExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_specular';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || ( material.specularIntensity == 1.0 &&
		       material.specularColor.equals( DEFAULT_SPECULAR_COLOR ) &&
		     ! material.specularIntensityMap && ! material.specularColorTexture ) ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.specularIntensityMap ) {

			final specularIntensityMapDef = {
				index: writer.processTexture( material.specularIntensityMap ),
				texCoord: material.specularIntensityMap.channel
			};
			writer.applyTextureTransform( specularIntensityMapDef, material.specularIntensityMap );
			extensionDef.specularTexture = specularIntensityMapDef;

		}

		if ( material.specularColorMap ) {

			final specularColorMapDef = {
				index: writer.processTexture( material.specularColorMap ),
				texCoord: material.specularColorMap.channel
			};
			writer.applyTextureTransform( specularColorMapDef, material.specularColorMap );
			extensionDef.specularColorTexture = specularColorMapDef;

		}

		extensionDef.specularFactor = material.specularIntensity;
		extensionDef.specularColorFactor = material.specularColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Sheen Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_sheen
 */
class GLTFMaterialsSheenExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_sheen';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.sheen == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.sheenRoughnessMap ) {

			final sheenRoughnessMapDef = {
				index: writer.processTexture( material.sheenRoughnessMap ),
				texCoord: material.sheenRoughnessMap.channel
			};
			writer.applyTextureTransform( sheenRoughnessMapDef, material.sheenRoughnessMap );
			extensionDef.sheenRoughnessTexture = sheenRoughnessMapDef;

		}

		if ( material.sheenColorMap ) {

			final sheenColorMapDef = {
				index: writer.processTexture( material.sheenColorMap ),
				texCoord: material.sheenColorMap.channel
			};
			writer.applyTextureTransform( sheenColorMapDef, material.sheenColorMap );
			extensionDef.sheenColorTexture = sheenColorMapDef;

		}

		extensionDef.sheenRoughnessFactor = material.sheenRoughness;
		extensionDef.sheenColorFactor = material.sheenColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Anisotropy Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_anisotropy
 */
class GLTFMaterialsAnisotropyExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_anisotropy';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.anisotropy == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.anisotropyMap ) {

			final anisotropyMapDef = { index: writer.processTexture( material.anisotropyMap ) };
			writer.applyTextureTransform( anisotropyMapDef, material.anisotropyMap );
			extensionDef.anisotropyTexture = anisotropyMapDef;

		}

		extensionDef.anisotropyStrength = material.anisotropy;
		extensionDef.anisotropyRotation = material.anisotropyRotation;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Materials Emissive Strength Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/blob/5768b3ce0ef32bc39cdf1bef10b948586635ead3/extensions/2.0/Khronos/KHR_materials_emissive_strength/README.md
 */
class GLTFMaterialsEmissiveStrengthExtension {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_emissive_strength';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshStandardMaterial || material.emissiveIntensity == 1.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef.emissiveStrength = material.emissiveIntensity;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * GPU Instancing Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Vendor/EXT_mesh_gpu_instancing
 */
class GLTFMeshGpuInstancing {

	finalructor( writer ) {

		this.writer = writer;
		this.name = 'EXT_mesh_gpu_instancing';

	}

	writeNode( object, nodeDef ) {

		if ( ! object.isInstancedMesh ) return;

		final writer = this.writer;

		final mesh = object;

		final translationAttr = new Float32Array( mesh.count * 3 );
		final rotationAttr = new Float32Array( mesh.count * 4 );
		final scaleAttr = new Float32Array( mesh.count * 3 );

		final matrix = new Matrix4();
		final position = new Vector3();
		final quaternion = new Quaternion();
		final scale = new Vector3();

		for (int i = 0; i < mesh.count; i ++ ) {

			mesh.getMatrixAt( i, matrix );
			matrix.decompose( position, quaternion, scale );

			position.toArray( translationAttr, i * 3 );
			quaternion.toArray( rotationAttr, i * 4 );
			scale.toArray( scaleAttr, i * 3 );

		}

		final attributes = {
			TRANSLATION: writer.processAccessor( new BufferAttribute( translationAttr, 3 ) ),
			ROTATION: writer.processAccessor( new BufferAttribute( rotationAttr, 4 ) ),
			SCALE: writer.processAccessor( new BufferAttribute( scaleAttr, 3 ) ),
		};

		if ( mesh.instanceColor )
			attributes._COLOR_0 = writer.processAccessor( mesh.instanceColor );

		nodeDef.extensions = nodeDef.extensions || {};
		nodeDef.extensions[ this.name ] = { attributes };

		writer.extensionsUsed[ this.name ] = true;
		writer.extensionsRequired[ this.name ] = true;

	}

}

/**
 * Static utility functions
 */
GLTFExporter.Utils = {

	insertKeyframe:( track, time ) {

		final tolerance = 0.001; // 1ms
		final valueSize = track.getValueSize();

		final times = new track.TimeBufferType( track.times.length + 1 );
		final values = new track.ValueBufferType( track.values.length + valueSize );
		final interpolant = track.createInterpolant( new track.ValueBufferType( valueSize ) );

		var index;

		if ( track.times.length == 0 ) {

			times[ 0 ] = time;

			for (int i = 0; i < valueSize; i ++ ) {

				values[ i ] = 0;

			}

			index = 0;

		} else if ( time < track.times[ 0 ] ) {

			if ( math.abs( track.times[ 0 ] - time ) < tolerance ) return 0;

			times[ 0 ] = time;
			times.set( track.times, 1 );

			values.set( interpolant.evaluate( time ), 0 );
			values.set( track.values, valueSize );

			index = 0;

		} else if ( time > track.times[ track.times.length - 1 ] ) {

			if ( math.abs( track.times[ track.times.length - 1 ] - time ) < tolerance ) {

				return track.times.length - 1;

			}

			times[ times.length - 1 ] = time;
			times.set( track.times, 0 );

			values.set( track.values, 0 );
			values.set( interpolant.evaluate( time ), track.values.length );

			index = times.length - 1;

		} else {

			for (int i = 0; i < track.times.length; i ++ ) {

				if ( math.abs( track.times[ i ] - time ) < tolerance ) return i;

				if ( track.times[ i ] < time && track.times[ i + 1 ] > time ) {

					times.set( track.times.slice( 0, i + 1 ), 0 );
					times[ i + 1 ] = time;
					times.set( track.times.slice( i + 1 ), i + 2 );

					values.set( track.values.slice( 0, ( i + 1 ) * valueSize ), 0 );
					values.set( interpolant.evaluate( time ), ( i + 1 ) * valueSize );
					values.set( track.values.slice( ( i + 1 ) * valueSize ), ( i + 2 ) * valueSize );

					index = i + 1;

					break;

				}

			}

		}

		track.times = times;
		track.values = values;

		return index;

	},

	mergeMorphTargetTracks:( clip, root ) {

		final tracks = [];
		final mergedTracks = {};
		final sourceTracks = clip.tracks;

		for (int i = 0; i < sourceTracks.length; ++ i ) {

			var sourceTrack = sourceTracks[ i ];
			final sourceTrackBinding = PropertyBinding.parseTrackName( sourceTrack.name );
			final sourceTrackNode = PropertyBinding.findNode( root, sourceTrackBinding.nodeName );

			if ( sourceTrackBinding.propertyName != 'morphTargetInfluences' || sourceTrackBinding.propertyIndex == null ) {

				// Tracks that don't affect morph targets, or that affect all morph targets together, can be left as-is.
				tracks.add( sourceTrack );
				continue;

			}

			if ( sourceTrack.createInterpolant != sourceTrack.InterpolantFactoryMethodDiscrete
				&& sourceTrack.createInterpolant != sourceTrack.InterpolantFactoryMethodLinear ) {

				if ( sourceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline ) {

					// This should never happen, because glTF morph target animations
					// affect all targets already.
					throw new Error( 'THREE.GLTFExporter: Cannot merge tracks with glTF CUBICSPLINE interpolation.' );

				}

				console.warn( 'THREE.GLTFExporter: Morph target interpolation mode not yet supported. Using LINEAR instead.' );

				sourceTrack = sourceTrack.clone();
				sourceTrack.setInterpolation( InterpolateLinear );

			}

			final targetCount = sourceTrackNode.morphTargetInfluences.length;
			final targetIndex = sourceTrackNode.morphTargetDictionary[ sourceTrackBinding.propertyIndex ];

			if ( targetIndex == null ) {

				throw new Error( 'THREE.GLTFExporter: Morph target name not found: ' + sourceTrackBinding.propertyIndex );

			}

			var mergedTrack;

			// If this is the first time we've seen this object, create a new
			// track to store merged keyframe data for each morph target.
			if ( mergedTracks[ sourceTrackNode.uuid ] == null ) {

				mergedTrack = sourceTrack.clone();

				final values = new mergedTrack.ValueBufferType( targetCount * mergedTrack.times.length );

				for (int j = 0; j < mergedTrack.times.length; j ++ ) {

					values[ j * targetCount + targetIndex ] = mergedTrack.values[ j ];

				}

				// We need to take into consideration the intended target node
				// of our original un-merged morphTarget animation.
				mergedTrack.name = ( sourceTrackBinding.nodeName || '' ) + '.morphTargetInfluences';
				mergedTrack.values = values;

				mergedTracks[ sourceTrackNode.uuid ] = mergedTrack;
				tracks.add( mergedTrack );

				continue;

			}

			final sourceInterpolant = sourceTrack.createInterpolant( new sourceTrack.ValueBufferType( 1 ) );

			mergedTrack = mergedTracks[ sourceTrackNode.uuid ];

			// For every existing keyframe of the merged track, write a (possibly
			// interpolated) value from the source track.
			for (int j = 0; j < mergedTrack.times.length; j ++ ) {

				mergedTrack.values[ j * targetCount + targetIndex ] = sourceInterpolant.evaluate( mergedTrack.times[ j ] );

			}

			// For every existing keyframe of the source track, write a (possibly
			// new) keyframe to the merged track. Values from the previous loop may
			// be written again, but keyframes are de-duplicated.
			for (int j = 0; j < sourceTrack.times.length; j ++ ) {

				final keyframeIndex = this.insertKeyframe( mergedTrack, sourceTrack.times[ j ] );
				mergedTrack.values[ keyframeIndex * targetCount + targetIndex ] = sourceTrack.values[ j ];

			}

		}

		clip.tracks = tracks;

		return clip;

	}

};
