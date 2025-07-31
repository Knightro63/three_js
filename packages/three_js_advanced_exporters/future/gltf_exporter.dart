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
			return GLTFLightExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsUnlitExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsTransmissionExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsVolumeExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsIorExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsSpecularExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsClearcoatExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsIridescenceExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsSheenExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsAnisotropyExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMaterialsEmissiveStrengthExtension( writer );
		} );

		this.register(( writer ) {
			return GLTFMeshGpuInstancing( writer );
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
			this.pluginCallbacks.removeAt( this.pluginCallbacks.indexOf( callback ));
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
	Future parse( input, onDone, onError, options ) async{
		final writer = GLTFWriter();
		final plugins = [];

		for (int i = 0, il = this.pluginCallbacks.length; i < il; i ++ ) {
			plugins.add( this.pluginCallbacks[ i ]( writer ) );
		}

		writer.setPlugins( plugins );
		writer.write( input, onDone, options ).catchError( onError );
	}

	// Future parseAsync( input, options ) async{
	// 	return await parse( input, resolve, reject, options );
	// }
}

//------------------------------------------------------------------------------
// finalants
//------------------------------------------------------------------------------

class WEBGL_finalANTS {
	static const int POINTS = 0x0000;
	static const int LINES = 0x0001;
	static const int LINE_LOOP = 0x0002;
	static const int LINE_STRIP = 0x0003;
	static const int TRIANGLES = 0x0004;
	static const int TRIANGLE_STRIP = 0x0005;
	static const int TRIANGLE_FAN = 0x0006;

	static const int BYTE = 0x1400;
	static const int UNSIGNED_BYTE = 0x1401;
	static const int SHORT = 0x1402;
	static const int UNSIGNED_SHORT = 0x1403;
	static const int INT = 0x1404;
	static const int UNSIGNED_INT = 0x1405;
	static const int FLOAT = 0x1406;

	static const int ARRAY_BUFFER = 0x8892;
	static const int ELEMENT_ARRAY_BUFFER = 0x8893;

	static const int NEAREST = 0x2600;
	static const int LINEAR = 0x2601;
	static const int NEAREST_MIPMAP_NEAREST = 0x2700;
	static const int LINEAR_MIPMAP_NEAREST = 0x2701;
	static const int NEAREST_MIPMAP_LINEAR = 0x2702;
	static const int LINEAR_MIPMAP_LINEAR = 0x2703;

	static const int CLAMP_TO_EDGE = 33071;
	static const int MIRRORED_REPEAT = 33648;
	static const int REPEAT = 1049;
}

final KHR_MESH_QUANTIZATION = 'KHR_mesh_quantization';

final THREE_TO_WEBGL = {
  NearestFilter: WEBGL_finalANTS.NEAREST,
  NearestMipmapNearestFilter: WEBGL_finalANTS.NEAREST_MIPMAP_NEAREST,
  NearestMipmapLinearFilter: WEBGL_finalANTS.NEAREST_MIPMAP_LINEAR,
  LinearFilter: WEBGL_finalANTS.LINEAR,
  LinearMipmapNearestFilter: WEBGL_finalANTS.LINEAR_MIPMAP_NEAREST,
  LinearMipmapLinearFilter: WEBGL_finalANTS.LINEAR_MIPMAP_LINEAR,

  ClampToEdgeWrapping: WEBGL_finalANTS.CLAMP_TO_EDGE,
  RepeatWrapping: WEBGL_finalANTS.REPEAT,
  MirroredRepeatWrapping: WEBGL_finalANTS.MIRRORED_REPEAT,
};



final Map<String,String> PATH_PROPERTIES = {
	'scale': 'scale',
	'position': 'translation',
	'quaternion': 'rotation',
	'morphTargetInfluences': 'weights'
};

final DEFAULT_SPECULAR_COLOR = Color();

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
ByteBuffer stringToArrayBuffer(String text ) {
	return Uint8List.fromList(text.codeUnits).buffer;//TextEncoder().encode( text ).buffer;
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
 */
Map<String,List<double>> getMinMax(BufferAttribute attribute, int start, int count ) {

	final Map<String,List<double>> output = {
		'min': List.filled(attribute.itemSize, double.infinity),// Array( attribute.itemSize ).fill( Number.POSITIVE_INFINITY ),
		'max': List.filled(attribute.itemSize, -double.infinity),//Array( attribute.itemSize ).fill( Number.NEGATIVE_INFINITY )
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

			output['min']![ a ] = math.min( output['min']![ a ], value );
			output['max']![ a ] = math.max( output['max']![ a ], value );
		}
	}

	return output;
}

/**
 * Get the required size + padding for a buffer, rounded to the next 4-byte boundary.
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#data-alignment
 *
 * @param {Integer} bufferSize The size the original buffer.
 * @returns {Integer} buffer size with required padding.
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
 * @returns {ArrayBuffer} The same buffer if it's already aligned to 4-byte boundary or a buffer
 */
getPaddedArrayBuffer( arrayBuffer,[int paddingByte = 0 ]) {
	final paddedLength = getPaddedBufferSize( arrayBuffer.byteLength );

	if ( paddedLength != arrayBuffer.byteLength ) {

		final array = Uint8List( paddedLength );
		array.set( Uint8List( arrayBuffer ) );

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
		return OffscreenCanvas( 1, 1 );
	}

	return document.createElement( 'canvas' );
}
getToBlobPromise( canvas, mimeType ) {
	if ( canvas.toBlob != null ) {
		return Promise( ( resolve ) => canvas.toBlob( resolve, mimeType ) );
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
		'type': mimeType,
		'quality': quality
	});
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
  Map nodeMap = Map();
  List skins = [];

  Map extensionsUsed = {};
  Map extensionsRequired = {};

  Map uids = Map();
  int uid = 0;

  Map<String,dynamic> json = {
    'asset': {
      'version': '2.0',
      'generator': 'THREE.GLTFExporter'
    }
  };

  Map<String,Map> cache = {
    'meshes': Map(),
    'attributes': Map(),
    'attributesNormalized': Map(),
    'materials': Map(),
    'textures': Map(),
    'images': Map()
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
	Future<Map<String,dynamic>> write(Scene input, Function onDone, [Map? options]) async {
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

		this.processInput( [input] );

		await this.pending;

		final writer = this;
		final buffers = writer.buffers;
		final json = writer.json;
		options = writer.options;

		final extensionsUsed = writer.extensionsUsed;
		final extensionsRequired = writer.extensionsRequired;

		// Merge buffers.
		final blob = Blob( buffers, { 'type': 'application/octet-stream' } );

		// Declare extensions.
		final extensionsUsedList = extensionsUsed.keys;
		final extensionsRequiredList = extensionsRequired.keys;

		if ( extensionsUsedList.length > 0 ) json['extensionsUsed'] = extensionsUsedList;
		if ( extensionsRequiredList.length > 0 ) json['extensionsRequired'] = extensionsRequiredList;

		// Update bytelength of the single buffer.
		if ( json['buffers'] && json['buffers'].length > 0 ) json['buffers'][ 0 ].byteLength = blob.size;

		if ( options['binary'] == true ) {

			// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

			final reader = FileReader();
			reader.readAsArrayBuffer( blob );
			reader.onloadend =() {

				// Binary chunk.
				final binaryChunk = getPaddedArrayBuffer( reader.result );
				final binaryChunkPrefix = DataView( ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				binaryChunkPrefix.setUint32( 0, binaryChunk.byteLength, true );
				binaryChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_BIN, true );

				// JSON chunk.
				final jsonChunk = getPaddedArrayBuffer( stringToArrayBuffer( JSON.stringify( json ) ), 0x20 );
				final jsonChunkPrefix = DataView( ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				jsonChunkPrefix.setUint32( 0, jsonChunk.byteLength, true );
				jsonChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_JSON, true );

				// GLB header.
				final header = ArrayBuffer( GLB_HEADER_BYTES );
				final headerView = DataView( header );
				headerView.setUint32( 0, GLB_HEADER_MAGIC, true );
				headerView.setUint32( 4, GLB_VERSION, true );
				final totalByteLength = GLB_HEADER_BYTES
					+ jsonChunkPrefix.byteLength + jsonChunk.byteLength
					+ binaryChunkPrefix.byteLength + binaryChunk.byteLength;
				headerView.setUint32( 8, totalByteLength, true );

				final glbBlob = Blob( [
					header,
					jsonChunkPrefix,
					jsonChunk,
					binaryChunkPrefix,
					binaryChunk
				], { type: 'application/octet-stream' } );

				final glbReader = FileReader();
				glbReader.readAsArrayBuffer( glbBlob );
				glbReader.onloadend =() {
					onDone( glbReader.result );
				};
			};
		} 
    else {
			if ( json.buffers && json.buffers.length > 0 ) {
				final reader = FileReader();
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
	serializeUserData( object, Map objectDef ) {

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
			final uids = Map();

			uids[this.uid ++] = true;//.set( true, this.uid ++ );
			uids[this.uid ++] = false;//.set( false, this.uid ++ );

			this.uids[uids] = attribute;//.set( attribute, uids );
		}

		final uids = this.uids[attribute];

		return uids[isRelativeCopy];
	}

	/**
	 * Checks if normal attribute values are normalized.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {Boolean}
	 */
	bool isNormalizedNormalAttribute(BufferAttribute normal ) {
		final cache = this.cache;

		if ( cache['attributesNormalized']?.containsValue( normal ) ?? false) return false;

		final v = Vector3();

		for (int i = 0, il = normal.count; i < il; i ++ ) {
			// 0.0005 is from glTF-validator
			if (( v.fromBuffer( normal, i ).length - 1.0 ).abs() > 0.0005 ) return false;
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
	BufferAttribute createNormalizedNormalAttribute(BufferAttribute normal ) {
		final cache = this.cache;

		if ( cache['attributesNormalized']?.containsValue( normal ) ?? false)	return cache['attributesNormalized']?[normal];//CHECK

		final BufferAttribute attribute = normal.clone();
		final v = Vector3();

		for (int i = 0, il = attribute.count; i < il; i ++ ) {
			v.fromBuffer( attribute, i );

			if ( v.x == 0 && v.y == 0 && v.z == 0 ) {
				// if values can't be normalized set (1, 0, 0)
				v.setX( 1.0 );
			} else {
				v.normalize();
			}

			attribute.setXYZ( i, v.x, v.y, v.z );
		}

		cache['attributesNormalized']?[attribute] = normal;//.set( normal, attribute );

		return attribute;
	}

	/**
	 * Applies a texture transform, if present, to the map definition. Requires
	 * the KHR_texture_transform extension.
	 *
	 * @param {Object} mapDef
	 * @param {THREE.Texture} texture
	 */
	void applyTextureTransform(Map mapDef, Texture texture ) {
		var didTransform = false;
		final transformDef = {};

		if ( texture.offset.x != 0 || texture.offset.y != 0 ) {
			transformDef['offset'] = texture.offset.toNumArray([]);
			didTransform = true;
		}

		if ( texture.rotation != 0 ) {
			transformDef['rotation'] = texture.rotation;
			didTransform = true;
		}

		if ( texture.repeat.x != 1 || texture.repeat.y != 1 ) {
			transformDef['scale'] = texture.repeat.toNumArray([]);
			didTransform = true;
		}

		if ( didTransform ) {
			mapDef['extensions'] = mapDef['extensions'] ?? {};
			mapDef['extensions'][ 'KHR_texture_transform' ] = transformDef;
			this.extensionsUsed[ 'KHR_texture_transform' ] = true;
		}
	}

	Texture? buildMetalRoughTexture(Texture? metalnessMap, Texture? roughnessMap ) {

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

		console.warning( 'THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.' );

		if ( metalnessMap is CompressedTexture ) {
			metalnessMap = MathUtils.decompress( metalnessMap );
		}

		if ( roughnessMap is CompressedTexture ) {
			roughnessMap = MathUtils.decompress( roughnessMap );
		}

		final metalness = metalnessMap != null? metalnessMap.image : null;
		final roughness = roughnessMap != null? roughnessMap.image : null;

		final width = math.max<num>( metalness ? metalness.width : 0, roughness ? roughness.width : 0 );
		final height = math.max<num>( metalness ? metalness.height : 0, roughness ? roughness.height : 0 );

		final canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;

		final context = canvas.getContext( '2d' );
		context.fillStyle = '#00ffff';
		context.fillRect( 0, 0, width, height );

		final composite = context.getImageData( 0, 0, width, height );

		if ( metalness != null) {
			context.drawImage( metalness, 0, 0, width, height );

			final convert = getEncodingConversion( metalnessMap );
			final data = context.getImageData( 0, 0, width, height ).data;

			for (int i = 2; i < data.length; i += 4 ) {
				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;
			}
		}

		if ( roughness != null) {
			context.drawImage( roughness, 0, 0, width, height );

			final convert = getEncodingConversion( roughnessMap );
			final data = context.getImageData( 0, 0, width, height ).data;

			for (int i = 1; i < data.length; i += 4 ) {
				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;
			}
		}

		context.putImageData( composite, 0, 0 );

		//

		final reference = metalnessMap ?? roughnessMap;
		final Texture? texture = reference?.clone();

		texture?.source = Source( canvas );
		texture?.colorSpace = NoColorSpace;
		texture?.channel =  metalnessMap?.channel ?? roughnessMap?.channel ?? 0;

		if ( metalnessMap != null && roughnessMap != null && metalnessMap.channel != roughnessMap.channel ) {
			console.warning( 'THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.' );
		}

		return texture;
	}

	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	int processBuffer( buffer ) {
		final json = this.json;
		final buffers = this.buffers;

		if (json['buffers'] == null) json['buffers'] = [ { 'byteLength': 0 } ];

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
	Map<String,dynamic> processBufferView(BufferAttribute attribute, int componentType, int start, int count, [int? target ]) {
		final json = this.json;

		if (json['bufferViews'] == null) json['bufferViews'] = [];

		// Create a dataview and dump the attribute's array into it

		int componentSize;

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
		final ByteData dataView = ByteData(byteLength);
		int offset = 0;

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

				if ( componentType == WEBGL_finalANTS.FLOAT ) {
					dataView.setFloat32( offset, value, Endian.little );
				} else if ( componentType == WEBGL_finalANTS.INT ) {
					dataView.setInt32( offset, value, Endian.little );
				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_INT ) {
					dataView.setUint32( offset, value, Endian.little );
				} else if ( componentType == WEBGL_finalANTS.SHORT ) {
					dataView.setInt16( offset, value, Endian.little );
				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_SHORT ) {
					dataView.setUint16( offset, value, Endian.little );
				} else if ( componentType == WEBGL_finalANTS.BYTE ) {
					dataView.setInt8( offset, value );
				} else if ( componentType == WEBGL_finalANTS.UNSIGNED_BYTE ) {
					dataView.setUint8( offset, value );
				}

				offset += componentSize;
			}
		}

		final bufferViewDef = {
			'buffer': this.processBuffer( dataView.buffer ),
			'byteOffset': this.byteOffset,
			'byteLength': byteLength
		};

		if ( target != null ) bufferViewDef['target'] = target;

		if ( target == WEBGL_finalANTS.ARRAY_BUFFER ) {
			// Only define byteStride for vertex attributes.
			bufferViewDef['byteStride'] = attribute.itemSize * componentSize;
		}

		this.byteOffset += byteLength;

		json['bufferViews'].add( bufferViewDef );

		// @TODO Merge bufferViews where possible.
		final output = {
			'id': json['bufferViews'].length - 1,
			'byteLength': 0
		};

		return output;
	}

	/**
	 * Process and generate a BufferView from an image Blob.
	 * @param {Blob} blob
	 * @return {Promise<Integer>}
	 */
	Future<void> processBufferViewImage( blob ) async{
		final writer = this;
		final json = writer.json;

		if (json['bufferViews'] == null) json['bufferViews'] = [];

    final reader = FileReader();
    reader.readAsArrayBuffer( blob );
    reader.onloadend = () {
      final buffer = getPaddedArrayBuffer( reader.result );

      final bufferViewDef = {
        'buffer': writer.processBuffer( buffer ),
        'byteOffset': writer.byteOffset,
        'byteLength': buffer.byteLength
      };

      writer.byteOffset += buffer.byteLength;
      resolve( json['bufferViews'].add( bufferViewDef ) - 1 );
    };
	}

	/**
	 * Process attribute to generate an accessor
	 * @param  {BufferAttribute} attribute Attribute to process
	 * @param  {THREE.BufferGeometry} geometry (Optional) Geometry used for truncated draw range
	 * @param  {Integer} start (Optional)
	 * @param  {Integer} count (Optional)
	 * @return {Integer|null} Index of the processed accessor on the "accessors" array
	 */
	Map<String, dynamic>? processAccessor(BufferAttribute attribute, [BufferGeometry? geometry, int start = 0, int count = 0]) {
		final json = this.json;

		final Map<int,String> types = {
			1: 'SCALAR',
			2: 'VEC2',
			3: 'VEC3',
			4: 'VEC4',
			9: 'MAT3',
			16: 'MAT4'
		};

		var componentType;

		// Detect the component type of the attribute array
		if ( attribute.array is Float32Array ) {
			componentType = WEBGL_finalANTS.FLOAT;
		} else if ( attribute.array is Int32Array ) {
			componentType = WEBGL_finalANTS.INT;
		} else if ( attribute.array is Uint32Array ) {
			componentType = WEBGL_finalANTS.UNSIGNED_INT;
		} else if ( attribute.array is Int16Array ) {
			componentType = WEBGL_finalANTS.SHORT;
		} else if ( attribute.array is Uint16Array ) {
			componentType = WEBGL_finalANTS.UNSIGNED_SHORT;
		} else if ( attribute.array is Int8Array ) {
			componentType = WEBGL_finalANTS.BYTE;
		} else if ( attribute.array is Uint8Array ) {
			componentType = WEBGL_finalANTS.UNSIGNED_BYTE;
		} else {
			throw( 'THREE.GLTFExporter: Unsupported bufferAttribute component type: ${attribute.array}');
		}

		if (count == double.infinity.toInt() ) count = attribute.count;

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
			'bufferView': bufferView['id'],
			'byteOffset': bufferView['byteOffset'],
			'componentType': componentType,
			'count': count,
			'max': minMax['max'],
			'min': minMax['min'],
			'type': types[ attribute.itemSize ]
		};

		if ( attribute.normalized == true ) accessorDef['normalized'] = true;
		if ( json['accessors'] == null) json['accessors'] = [];

		return json['accessors'].add( accessorDef ) - 1;
	}

	/**
	 * Process image
	 * @param  {Image} image to process
	 * @param  {Integer} format of the image (RGBAFormat)
	 * @param  {Boolean} flipY before writing out the image
	 * @param  {String} mimeType export format
	 * @return {Integer}     Index of the processed texture in the "images" array
	 */
	processImage( image, int format, bool flipY, [String mimeType = 'image/png'] ) {

		if ( image != null ) {

			final writer = this;
			final cache = writer.cache;
			final json = writer.json;
			final options = writer.options;
			final pending = writer.pending;

			if (cache['images']?.containsValue( image ) ?? false) cache['images'].set( image, {} );

			final cachedImages = cache['images']?[image];

			final key = mimeType + ':flipY/' + flipY.toString();

			if ( cachedImages[ key ] != null ) return cachedImages[ key ];

			if (json['images'] == null) json['images'] = [];

			final imageDef = { mimeType: mimeType };

			final canvas = getCanvas();

			canvas.width = math.min<int>( image.width, options.maxTextureSize );
			canvas.height = math.min<int>( image.height, options.maxTextureSize );

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
					console.warning( 'GLTFExporter: Image size is bigger than maxTextureSize', image );
				}

				final data = Uint8ClampedArray( image.height * image.width * 4 );

				for (int i = 0; i < data.length; i += 4 ) {
					data[ i + 0 ] = image.data[ i + 0 ];
					data[ i + 1 ] = image.data[ i + 1 ];
					data[ i + 2 ] = image.data[ i + 2 ];
					data[ i + 3 ] = image.data[ i + 3 ];
				}
				ctx.putImageData( ImageData( data, image.width, image.height ), 0, 0 );
			}
      else {
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

			}
      else {
				if ( canvas.toDataURL != null ) {
					imageDef.uri = canvas.toDataURL( mimeType );
				} 
        else {
					pending.add(

						getToBlobPromise( canvas, mimeType )
							.then( blob => FileReader().readAsDataURL( blob ) )
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
			throw( 'THREE.GLTFExporter: No valid image data found. Unable to process texture.' );
		}
	}

	/**
	 * Process sampler
	 * @param  {Texture} map Texture to process
	 * @return {Integer}     Index of the processed texture in the "samplers" array
	 */
	Map<String,dynamic> processSampler(Texture map ) {
		final json = this.json;

		if (json['samplers'] == null) json['samplers'] = [];

		final samplerDef = {
			'magFilter': THREE_TO_WEBGL[ map.magFilter ],
			'minFilter': THREE_TO_WEBGL[ map.minFilter ],
			'wrapS': THREE_TO_WEBGL[ map.wrapS ],
			'wrapT': THREE_TO_WEBGL[ map.wrapT ]
		};

		return json['samplers'].add( samplerDef ) - 1;
	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	int processTexture(Texture map ) {
		final writer = this;
		final options = writer.options;
		final cache = this.cache;
		final json = this.json;

		if ( cache['textures']?.containsValue( map ) ?? false) return cache['textures']?[map];//CHECK

		if (json['textures'] == null) json['textures'] = [];

		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a texture
		if ( map is CompressedTexture ) {
			map = decompress( map, options['maxTextureSize'] );
		}

		var mimeType = map.userData['mimeType'];

		if ( mimeType == 'image/webp' ) mimeType = 'image/png';

		final textureDef = {
			'sampler': this.processSampler( map ),
			'source': this.processImage( map.image, map.format, map.flipY, mimeType )
		};

		textureDef['name'] = map.name;

		this._invokeAll(( ext ) {
			ext.writeTexture && ext.writeTexture( map, textureDef );
		} );

		final index = json['textures'].add( textureDef ) - 1;
		cache['textures']?[index] = map;
		return index;
	}

	/**
	 * Process material
	 * @param  {THREE.Material} material Material to process
	 * @return {Integer|null} Index of the processed material in the "materials" array
	 */
	int? processMaterial(Material material ) {
		final cache = this.cache;
		final json = this.json;

		if ( cache['materials']?.containsKey( material ) == true) return cache['materials']?[material];

		if ( material is ShaderMaterial ) {
			console.warning( 'GLTFExporter: THREE.ShaderMaterial not supported.' );
			return null;
		}

		if (json['materials'] == null) json['materials'] = [];
		// @QUESTION Should we avoid including any attribute that has the default value?
		final Map<String,dynamic> materialDef = {	'pbrMetallicRoughness': {} };

		if ( material is! MeshStandardMaterial && material is! MeshBasicMaterial) {
			console.warning( 'GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.' );
		}

		// pbrMetallicRoughness.baseColorFactor
		final color = material.color.toNumArray([]).concat( [ material.opacity ] );

		if ( ! equalArray( color, [ 1, 1, 1, 1 ] ) ) {
			materialDef['pbrMetallicRoughness']['baseColorFactor'] = color;
		}

		if ( material is MeshStandardMaterial ) {
			materialDef['pbrMetallicRoughness']['metallicFactor'] = material.metalness;
			materialDef['pbrMetallicRoughness']['roughnessFactor'] = material.roughness;
		} 
    else {
			materialDef['pbrMetallicRoughness']['metallicFactor'] = 0.5;
			materialDef['pbrMetallicRoughness']['roughnessFactor'] = 0.5;
		}

		// pbrMetallicRoughness.metallicRoughnessTexture
		if ( material.metalnessMap != null || material.roughnessMap != null) {

			final metalRoughTexture = this.buildMetalRoughTexture( material.metalnessMap, material.roughnessMap );

			final metalRoughMapDef = {
				'index': this.processTexture( metalRoughTexture! ),
				'channel': metalRoughTexture.channel
			};
			this.applyTextureTransform( metalRoughMapDef, metalRoughTexture );
			materialDef['pbrMetallicRoughness'].metallicRoughnessTexture = metalRoughMapDef;
		}

		// pbrMetallicRoughness.baseColorTexture
		if ( material.map != null) {
			final baseColorMapDef = {
				'index': this.processTexture( material.map! ),
				'texCoord': material.map?.channel
			};
			this.applyTextureTransform( baseColorMapDef, material.map! );
			materialDef['pbrMetallicRoughness'].baseColorTexture = baseColorMapDef;
		}

		if ( material.emissive != null) {

			final emissive = material.emissive;
			final maxEmissiveComponent = math.max( math.max(emissive!.red, emissive.green), emissive.blue );

			if ( maxEmissiveComponent > 0 ) {
				materialDef['emissiveFactor'] = material.emissive?.toNumArray([]);
			}

			// emissiveTexture
			if ( material.emissiveMap != null) {
				final emissiveMapDef = {
					'index': this.processTexture( material.emissiveMap! ),
					'texCoord': material.emissiveMap?.channel
				};
				this.applyTextureTransform( emissiveMapDef, material.emissiveMap! );
				materialDef['emissiveTexture'] = emissiveMapDef;
			}
		}

		// normalTexture
		if ( material.normalMap != null) {

			final Map<String,dynamic> normalMapDef = {
				'index': this.processTexture( material.normalMap! ),
				'texCoord': material.normalMap?.channel
			};

			if ( material.normalScale != null && material.normalScale?.x != 1 ) {
				// glTF normal scale is univariate. Ignore `y`, which may be flipped.
				// Context: https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
				normalMapDef['scale'] = material.normalScale?.x;
			}

			this.applyTextureTransform( normalMapDef, material.normalMap! );
			materialDef['normalTexture'] = normalMapDef;

		}

		// occlusionTexture
		if ( material.aoMap != null) {
			final Map<String,dynamic> occlusionMapDef = {
				'index': this.processTexture( material.aoMap! ),
				'texCoord': material.aoMap?.channel
			};

			if ( material.aoMapIntensity != 1.0 ) {
				occlusionMapDef['strength'] = material.aoMapIntensity;
			}

			this.applyTextureTransform( occlusionMapDef, material.aoMap! );
			materialDef['occlusionTexture'] = occlusionMapDef;
		}

		// alphaMode
		if ( material.transparent) {
			materialDef['alphaMode'] = 'BLEND';
		} 
    else {
			if ( material.alphaTest > 0.0 ) {
				materialDef['alphaMode'] = 'MASK';
				materialDef['alphaCutoff'] = material.alphaTest;
			}
		}

		// doubleSided
		if ( material.side == DoubleSide ) materialDef['doubleSided'] = true;
		if ( material.name != '' ) materialDef['name'] = material.name;

		this.serializeUserData( material, materialDef );

		this._invokeAll(( ext ) {
			ext.writeMaterial == null?null:ext.writeMaterial( material, materialDef );
		} );

		final index = json['materials'].add( materialDef ) - 1;
		cache['materials']?[index] = material;
		return index;
	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	int? processMesh(Object3D mesh ) {
		final cache = this.cache;
		final json = this.json;

		final meshCacheKeyParts = [ mesh.geometry?.uuid ];

		if (mesh.material is GroupMaterial) {
			for (int i = 0, l = (mesh.material as GroupMaterial).children.length; i < l; i ++ ) {
				meshCacheKeyParts.add( (mesh.material as GroupMaterial).children[ i ].uuid	);
			}
		} 
    else {
			meshCacheKeyParts.add( mesh.material?.uuid );
		}

		final meshCacheKey = meshCacheKeyParts.join( ':' );

		if ( cache['meshes']?.containsKey( meshCacheKey ) ?? false) return cache['meshes']?[meshCacheKey];

		final geometry = mesh.geometry;

		var mode;

		// Use the correct mode
		if ( mesh is LineSegments ) {
			mode = WEBGL_finalANTS.LINES;
		} else if ( mesh is LineLoop ) {
			mode = WEBGL_finalANTS.LINE_LOOP;
		} else if ( mesh is Line ) {
			mode = WEBGL_finalANTS.LINE_STRIP;
		} else if ( mesh is Points ) {
			mode = WEBGL_finalANTS.POINTS;
		} else {
			mode = mesh.material?.wireframe == null? WEBGL_finalANTS.LINES : WEBGL_finalANTS.TRIANGLES;
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

		final originalNormal = geometry?.getAttributeFromString( 'normal' );

		if ( originalNormal != null && ! this.isNormalizedNormalAttribute( originalNormal ) ) {
			console.warning( 'THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.' );
			geometry?.setAttributeFromString( 'normal', this.createNormalizedNormalAttribute( originalNormal ) );
		}

		// @QUESTION Detect if .vertexColors = true?
		// For every attribute create an accessor
		var modifiedAttribute = null;

		for (String attributeName in geometry!.attributes.keys ) {

			// Ignore morph target attributes, which are exported later.
			if ( attributeName.slice( 0, 5 ) == 'morph' ) continue;

			final attribute = geometry.attributes[ attributeName ];
			attributeName = nameConversion[ attributeName ] ?? attributeName.toUpperCase();

			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
			final validVertexAttributes = '/^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/';

			if ( ! validVertexAttributes.test( attributeName ) ) attributeName = '_$attributeName';

			if ( cache['attributes']?.containsKey( this.getUID( attribute ) ) == true) {

				attributes[ attributeName ] = cache['attributes']?[this.getUID( attribute )];
				continue;

			}

			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			final array = attribute.array;

			if ( attributeName == 'JOINTS_0' &&
				! ( array is Uint16Array ) &&
				! ( array is Uint8Array ) ) {

				console.warning( 'GLTFExporter: Attribute "skinIndex" converted to type UNSIGNED_SHORT.' );
				modifiedAttribute = Uint16BufferAttribute( Uint16Array( array ), attribute.itemSize, attribute.normalized );

			}

			final accessor = this.processAccessor( modifiedAttribute ?? attribute, geometry );

			if ( accessor != null ) {
				if ( ! attributeName.startsWith( '_' ) ) {
					this.detectMeshQuantization( attributeName, attribute );
				}

				attributes[ attributeName ] = accessor;
				cache['attributes'].set( this.getUID( attribute ), accessor );
			}
		}

		if ( originalNormal != null ) geometry.setAttributeFromString( 'normal', originalNormal );

		// Skip if no exportable attributes found
		if (attributes.keys.length == 0 ) return null;

		// Morph targets
		if (mesh.morphTargetInfluences.isNotEmpty) {
			final weights = [];
			final targetNames = [];
			final reverseDictionary = {};

			if ( mesh.morphTargetDictionary != null ) {
				for ( final key in mesh.morphTargetDictionary!.keys ) {
					reverseDictionary[ mesh.morphTargetDictionary?[ key ] ] = key;
				}
			}

			for (int i = 0; i < mesh.morphTargetInfluences.length; ++ i ) {

				final target = {};
				var warned = false;

				for ( final attributeName in geometry.morphAttributes.keys ) {
					// glTF 2.0 morph supports only POSITION/NORMAL/TANGENT.
					// Three.js doesn't support TANGENT yet.

					if ( attributeName != 'position' && attributeName != 'normal' ) {
						if ( ! warned ) {
							console.warning( 'GLTFExporter: Only POSITION and NORMAL morph are supported.' );
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

					if ( cache['attributes'].has( this.getUID( attribute, true ) ) ) {
						target[ gltfAttributeName ] = cache['attributes'].get( this.getUID( attribute, true ) );
						continue;
					}

					// Clones attribute not to override
					final relativeAttribute = attribute.clone();

					if ( ! geometry.morphTargetsRelative ) {
						for (int j = 0, jl = attribute.count; j < jl; j ++ ) {
							for (int a = 0; a < attribute.itemSize; a ++ ) {
								if ( a == 0 ) relativeAttribute.setX( j, attribute.getX( j )! - baseAttribute.getX( j ) );
								if ( a == 1 ) relativeAttribute.setY( j, attribute.getY( j )! - baseAttribute.getY( j ) );
								if ( a == 2 ) relativeAttribute.setZ( j, attribute.getZ( j )! - baseAttribute.getZ( j ) );
								if ( a == 3 ) relativeAttribute.setW( j, attribute.getW( j )! - baseAttribute.getW( j ) );
							}
						}
					}

					target[ gltfAttributeName ] = this.processAccessor( relativeAttribute, geometry );
					cache['attributes'].set( this.getUID( baseAttribute, true ), target[ gltfAttributeName ] );
				}

				targets.add( target );
				weights.add( mesh.morphTargetInfluences[ i ] );
				if ( mesh.morphTargetDictionary != null ) targetNames.add( reverseDictionary[ i ] );
			}

			meshDef['weights'] = weights;

			if ( targetNames.length > 0 ) {
				meshDef['extras'] = {};
				meshDef['extras']['targetNames'] = targetNames;
			}
		}

		final isMultiMaterial = mesh.material is GroupMaterial;

		if ( isMultiMaterial && geometry.groups.length == 0 ) return null;

		final materials = isMultiMaterial ? mesh.material : [ mesh.material ];
		final groups = isMultiMaterial ? geometry.groups : [ { 'materialIndex': 0, 'start': null, 'count': null } ];

		for (int i = 0, il = groups.length; i < il; i ++ ) {
			final Map<String,dynamic> primitive = {
				'mode': mode,
				'attributes': attributes,
			};

			this.serializeUserData( geometry, primitive );

			if ( targets.length > 0 ) primitive['targets'] = targets;
			if ( geometry.index != null ) {
				var cacheKey = this.getUID( geometry.index );

				if ( groups[ i ]['start'] != null || groups[ i ]['count'] != null ) {
					cacheKey += ':' + groups[ i ]['start'] + ':' + groups[ i ]['count'];
				}

				if ( cache['attributes'].has( cacheKey ) ) {
					primitive['indices'] = cache['attributes'].get( cacheKey );
				} 
        else {
					primitive['indices'] = this.processAccessor( geometry.index!, geometry, groups[ i ]['start'], groups[ i ]['count'] );
					cache['attributes'].set( cacheKey, primitive['indices'] );
				}

				if ( primitive['indices'] == null ) primitive.remove('indices');
			}

			final material = this.processMaterial( materials[groups[ i ]['materialIndex']] );

			if ( material != null ) primitive['material'] = material;

			primitives.add( primitive );

		}

		meshDef['primitives'] = primitives;

		if (json['meshes'] == null) json['meshes'] = [];

		this._invokeAll(( ext ) {
			ext.writeMesh && ext.writeMesh( mesh, meshDef );
		} );

		final index = json['meshes'].add( meshDef ) - 1;
		cache['meshes'].set( meshCacheKey, index );
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
	void detectMeshQuantization(String attributeName, BufferAttribute attribute ) {
		if ( this.extensionsUsed[ KHR_MESH_QUANTIZATION ] ) return;

		var attrType = null;

		switch ( attribute.array.runtimeType) {
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

		if ( KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ] != null && KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ]!.contains( attrType ) ) {
			this.extensionsUsed[ KHR_MESH_QUANTIZATION ] = true;
			this.extensionsRequired[ KHR_MESH_QUANTIZATION ] = true;
		}
	}

	/**
	 * Process camera
	 * @param  {THREE.Camera} camera Camera to process
	 * @return {Integer}      Index of the processed mesh in the "camera" array
	 */
	Map<String,dynamic> processCamera(Camera camera ) {
		final json = this.json;

		if (json['cameras'] == null) json['cameras'] = [];

		final isOrtho = camera is OrthographicCamera;

		final Map<String,dynamic> cameraDef = {
			'type': isOrtho ? 'orthographic' : 'perspective'
		};

		if ( isOrtho ) {
			cameraDef['orthographic'] = {
				'xmag': camera.right * 2,
				'ymag': camera.top * 2,
				'zfar': camera.far <= 0 ? 0.001 : camera.far,
				'znear': camera.near < 0 ? 0 : camera.near
			};
		} 
    else {
			cameraDef['perspective'] = {
				'aspectRatio': camera.aspect,
				'yfov': MathUtils.degToRad( camera.fov ),
				'zfar': camera.far <= 0 ? 0.001 : camera.far,
				'znear': camera.near < 0 ? 0 : camera.near
			};
		}

		// Question: Is saving "type" as name intentional?
		if ( camera.name != '' ) cameraDef['name'] = camera.type;
		return json['cameras'].add( cameraDef ) - 1;
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
	int? processAnimation( clip, Object3D root ) {
		final json = this.json;
		final nodeMap = this.nodeMap;

		if (json['animations'] == null) json['animations'] = [];

		clip = GLTFExporterUtils.mergeMorphTargetTracks( clip.clone(), root );

		final tracks = clip.tracks;
		final channels = [];
		final samplers = [];

		for (int i = 0; i < tracks.length; ++ i ) {

			final track = tracks[ i ];
			final trackBinding = PropertyBinding.parseTrackName( track.name );
			var trackNode = PropertyBinding.findNode( root, trackBinding.nodeName );
			final trackProperty = PATH_PROPERTIES[ trackBinding.propertyName ];

			if ( trackBinding.objectName == 'bones' ) {
				if ( trackNode is SkinnedMesh) {
					trackNode = trackNode.skeleton?.getBoneByName( trackBinding.objectIndex );
				} 
        else {
					trackNode = null;
				}
			}

			if ( ! trackNode || trackProperty == null) {
				console.warning( 'THREE.GLTFExporter: Could not export animation track "${track.name}".',  );
				return null;
			}

			final inputItemSize = 1;
			var outputItemSize = track.values.length / track.times.length;

			if ( trackProperty == PATH_PROPERTIES['morphTargetInfluences'] ) {
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
				'input': this.processAccessor( BufferAttribute( track.times, inputItemSize ) ),
				'output': this.processAccessor( BufferAttribute( track.values, outputItemSize ) ),
				'interpolation': interpolation
			} );

			channels.add( {
				'sampler': samplers.length - 1,
				'target': {
					'node': nodeMap.get( trackNode ),
					'path': trackProperty
				}
			} );

		}

		json['animations'].add( {
			'name': clip.name ?? 'clip_${json['animations'].length}',
			'samplers': samplers,
			'channels': channels
		} );

		return json['animations'].length - 1;
	}

	/**
	 * @param {THREE.Object3D} object
	 * @return {number|null}
	 */
	 int? processSkin(Object3D object ) {
		final json = this.json;
		final nodeMap = this.nodeMap;

		final node = json['nodes'][nodeMap[object]];

		final skeleton = object.skeleton;

		if ( skeleton == null ) return null;

		final rootJoint = object.skeleton?.bones[ 0 ];

		if ( rootJoint == null ) return null;

		final joints = [];
		final inverseBindMatrices = Float32Array( skeleton.bones.length * 16 );
		final temporaryBoneInverse = Matrix4();

		for (int i = 0; i < skeleton.bones.length; ++ i ) {
			joints.add( nodeMap[skeleton.bones[ i ]]);
			temporaryBoneInverse.setFrom( skeleton.boneInverses[ i ] );
			temporaryBoneInverse.multiply( object.bindMatrix! ).toArray( inverseBindMatrices, i * 16 );
		}

		if ( json['skins'] == null ) json['skins'] = [];

		json['skins'].add( {
			inverseBindMatrices: this.processAccessor( Float32BufferAttribute( inverseBindMatrices, 16 ) ),
			joints: joints,
			skeleton: nodeMap[rootJoint]
		} );

		final skinIndex = node.skin = json['skins'].length - 1;

		return skinIndex;
	}

	/**
	 * Process Object3D node
	 * @param  {THREE.Object3D} node Object3D to processNode
	 * @return {Integer} Index of the node in the nodes list
	 */
	int processNode(Object3D object ) {
		final json = this.json;
		final options = this.options;
		final nodeMap = this.nodeMap;

		if (json['nodes'] == null) json['nodes'] = [];

		final nodeDef = {};

		if ( options['trs'] != null) {

			final rotation = object.quaternion.toArray([]);
			final position = object.position.toNumArray([]);
			final scale = object.scale.toNumArray([]);

			if ( ! equalArray( rotation, [ 0, 0, 0, 1 ] ) ) {
				nodeDef['rotation'] = rotation;
			}

			if ( ! equalArray( position, [ 0, 0, 0 ] ) ) {
				nodeDef['translation'] = position;
			}

			if ( ! equalArray( scale, [ 1, 1, 1 ] ) ) {
				nodeDef['scale'] = scale;
			}
		} 
    else {
			if ( object.matrixAutoUpdate ) {
				object.updateMatrix();
			}

			if ( isIdentityMatrix( object.matrix ) == false ) {
				nodeDef['matrix'] = object.matrix.storage;
			}
		}

		// We don't export empty strings name because it represents no-name in Three.js.
		if ( object.name != '' ) nodeDef['name'] = object.name;

		this.serializeUserData( object, nodeDef );

		if ( object is Mesh || object is Line || object is Points ) {
			final meshIndex = this.processMesh( object );
			if ( meshIndex != null ) nodeDef['mesh'] = meshIndex;
		} 
    else if ( object is Camera ) {
			nodeDef['camera'] = this.processCamera( object );
		}

		if ( object is SkinnedMesh ) this.skins.add( object );

		if ( object.children.length > 0 ) {
			final children = [];

			for (int i = 0, l = object.children.length; i < l; i ++ ) {
				final child = object.children[ i ];

				if ( child.visible || options['onlyVisible'] == false ) {
					final nodeIndex = this.processNode( child );
					if ( nodeIndex != 0 ) children.add( nodeIndex );
				}
			}

			if ( children.length > 0 ) nodeDef['children'] = children;
		}

		this._invokeAll(( ext ) {
			ext.writeNode == null?null:ext.writeNode( object, nodeDef );
		} );

		final nodeIndex = json['nodes'].add( nodeDef ) - 1;
		nodeMap[object] = nodeIndex;
		return nodeIndex;
	}

	/**
	 * Process Scene
	 * @param  {Scene} node Scene to process
	 */
	void processScene(Scene scene ) {
		final json = this.json;
		final options = this.options;

		if ( ! json['scenes'] ) {
			json['scenes'] = [];
			json['scene'] = 0;
		}

		final sceneDef = {};

		if ( scene.name != '' ) sceneDef['name'] = scene.name;
		json['scenes'].add( sceneDef );
		final nodes = [];

		for (int i = 0, l = scene.children.length; i < l; i ++ ) {
			final child = scene.children[ i ];

			if ( child.visible || options['onlyVisible'] == false ) {
				final nodeIndex = this.processNode( child );
				if ( nodeIndex != 0 ) nodes.add( nodeIndex );
			}
		}

		if ( nodes.length > 0 ) sceneDef['nodes'] = nodes;
		this.serializeUserData( scene, sceneDef );
	}

	/**
	 * Creates a Scene to hold a list of objects and parse it
	 * @param  {Array} objects List of objects to process
	 */
	void processObjects(List objects ) {
		final scene = Scene();
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
	void processInput(List<Object3D> input ) {
		final options = this.options;

		this._invokeAll(( ext ) {
			ext.beforeParse == null? null:ext.beforeParse( input );
		} );

		final objectsWithoutScene = [];

		for (int i = 0; i < input.length; i ++ ) {
			if (input[ i ] is Scene ) {
				processScene( input[ i ] as Scene);
			} 
      else {
				objectsWithoutScene.add( input[ i ] );
			}
		}

		if ( objectsWithoutScene.length > 0 ) this.processObjects( objectsWithoutScene );

		for (int i = 0; i < this.skins.length; ++ i ) {
			this.processSkin( this.skins[ i ] );
		}

		for (int i = 0; i < options['animations'].length; ++ i ) {
			this.processAnimation( options['animations'][ i ], input[ 0 ] );
		}

		this._invokeAll(( ext ) {
			ext.afterParse != null? ext.afterParse( input ): null;
		} );
	}

	_invokeAll( func ) {
		for (int i = 0, il = this.plugins.length; i < il; i ++ ) {
			func( this.plugins[ i ] );
		}
	}
}

class GLTFExtension {
  late String name;
  dynamic writer;
  GLTFExtension(this.writer);
}

/**
 * Punctual Lights Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_lights_punctual
 */
class GLTFLightExtension extends GLTFExtension{

	GLTFLightExtension(super.writer ) {
		this.name = 'KHR_lights_punctual';
	}

	void writeNode(Light light, Map nodeDef ) {
		if (light is! DirectionalLight && light is! PointLight && light is! SpotLight ) {
			console.warning( 'THREE.GLTFExporter: Only directional, point, and spot lights are supported. $light',  );
			return;
		}

		final writer = this.writer;
		final json = writer.json;
		final extensionsUsed = writer.extensionsUsed;

		final lightDef = {};
    lightDef['name'] = light.name;

		lightDef['color'] = light.color?.toNumArray([]);
		lightDef['intensity'] = light.intensity;

		if ( light is DirectionalLight ) {
			lightDef['type'] = 'directional';
		} else if ( light is PointLight ) {
			lightDef['type'] = 'point';
			if ( (light.distance ?? 0) > 0 ) lightDef['range'] = light.distance;
		} else if ( light is SpotLight ) {
			lightDef['type'] = 'spot';
			if ( (light.distance ?? 0) > 0 ) lightDef['range'] = light.distance;
			lightDef['spot'] = {};
			lightDef['spot']['innerConeAngle'] = ( 1.0 - (light.penumbra ?? 0) ) * (light.angle ?? 0);
			lightDef['spot']['outerConeAngle'] = light.angle;
		}

		if ( light.decay != null && light.decay != 2 ) {

			console.warning( 'THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, '
				+ 'and expects light.decay=2.' );

		}

		if ( light.target != null
				&& ( light.target?.parent != light
				|| light.target?.position.x != 0
				|| light.target?.position.y != 0
				|| light.target?.position.z != - 1 ) ) {

			console.warning( 'THREE.GLTFExporter: Light direction may be lost. For best results, '
				+ 'make light.target a child of the light with position 0,0,-1.' );

		}

		if ( ! extensionsUsed[ this.name ] ) {
			json['extensions'] = json['extensions'] ?? {};
			json['extensions'][ this.name ] = { 'lights': [] };
			extensionsUsed[ this.name ] = true;
		}

		final List lights = json['extensions'][ this.name ].lights;
		lights.add( lightDef );

		nodeDef['extensions'] = nodeDef['extensions'] ?? {};
		nodeDef['extensions'][ this.name ] = { 'light': lights.length - 1 };
	}
}

/**
 * Unlit Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_unlit
 */
class GLTFMaterialsUnlitExtension extends GLTFExtension{
	GLTFMaterialsUnlitExtension( super.writer ) {
		this.name = 'KHR_materials_unlit';
	}

	void writeMaterial(MeshBasicMaterial material, Map materialDef ) {
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = {};

		extensionsUsed[ this.name ] = true;

		materialDef['pbrMetallicRoughness'].metallicFactor = 0.0;
		materialDef['pbrMetallicRoughness'].roughnessFactor = 0.9;
	}
}

/**
 * Clearcoat Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_clearcoat
 */
class GLTFMaterialsClearcoatExtension extends GLTFExtension{

	GLTFMaterialsClearcoatExtension( super.writer ) {
		this.name = 'KHR_materials_clearcoat';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.clearcoat == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['clearcoatFactor'] = material.clearcoat;

		if ( material.clearcoatMap != null) {
			final clearcoatMapDef = {
				'index': writer.processTexture( material.clearcoatMap ),
				'texCoord': material.clearcoatMap?.channel
			};
			writer.applyTextureTransform( clearcoatMapDef, material.clearcoatMap );
			extensionDef['clearcoatTexture'] = clearcoatMapDef;
		}

		extensionDef['clearcoatRoughnessFactor'] = material.clearcoatRoughness;

		if ( material.clearcoatRoughnessMap != null) {
			final clearcoatRoughnessMapDef = {
				'index': writer.processTexture( material.clearcoatRoughnessMap ),
				'texCoord': material.clearcoatRoughnessMap?.channel
			};
			writer.applyTextureTransform( clearcoatRoughnessMapDef, material.clearcoatRoughnessMap );
			extensionDef['clearcoatRoughnessTexture'] = clearcoatRoughnessMapDef;
		}

		if ( material.clearcoatNormalMap != null) {
			final clearcoatNormalMapDef = {
				'index': writer.processTexture( material.clearcoatNormalMap ),
				'texCoord': material.clearcoatNormalMap?.channel
			};
			writer.applyTextureTransform( clearcoatNormalMapDef, material.clearcoatNormalMap );
			extensionDef['clearcoatNormalTexture'] = clearcoatNormalMapDef;
		}

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Iridescence Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_iridescence
 */
class GLTFMaterialsIridescenceExtension extends GLTFExtension{

	GLTFMaterialsIridescenceExtension(super.writer ) {
		this.name = 'KHR_materials_iridescence';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.iridescence == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['iridescenceFactor'] = material.iridescence;

		if ( material.iridescenceMap != null) {
			final iridescenceMapDef = {
				'index': writer.processTexture( material.iridescenceMap ),
				'texCoord': material.iridescenceMap?.channel
			};
			writer.applyTextureTransform( iridescenceMapDef, material.iridescenceMap );
			extensionDef['iridescenceTexture'] = iridescenceMapDef;
		}

		extensionDef['iridescenceIor'] = material.iridescenceIOR;
		extensionDef['iridescenceThicknessMinimum'] = material.iridescenceThicknessRange[ 0 ];
		extensionDef['iridescenceThicknessMaximum'] = material.iridescenceThicknessRange[ 1 ];

		if ( material.iridescenceThicknessMap != null) {
			final iridescenceThicknessMapDef = {
				'index': writer.processTexture( material.iridescenceThicknessMap ),
				'texCoord': material.iridescenceThicknessMap?.channel
			};
			writer.applyTextureTransform( iridescenceThicknessMapDef, material.iridescenceThicknessMap );
			extensionDef['iridescenceThicknessTexture'] = iridescenceThicknessMapDef;
		}

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Transmission Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_transmission
 */
class GLTFMaterialsTransmissionExtension extends GLTFExtension{

	GLTFMaterialsTransmissionExtension( super.writer ) {
		this.name = 'KHR_materials_transmission';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['transmissionFactor'] = material.transmission;

		if ( material.transmissionMap != null) {
			final transmissionMapDef = {
				'index': writer.processTexture( material.transmissionMap ),
				'texCoord': material.transmissionMap?.channel
			};
			writer.applyTextureTransform( transmissionMapDef, material.transmissionMap );
			extensionDef['transmissionTexture'] = transmissionMapDef;
		}

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Materials Volume Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_volume
 */
class GLTFMaterialsVolumeExtension extends GLTFExtension{

	GLTFMaterialsVolumeExtension( super.writer ) {
		this.name = 'KHR_materials_volume';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['thicknessFactor'] = material.thickness;

		if ( material.thicknessMap != null) {

			final thicknessMapDef = {
				'index': writer.processTexture( material.thicknessMap ),
				'texCoord': material.thicknessMap?.channel
			};
			writer.applyTextureTransform( thicknessMapDef, material.thicknessMap );
			extensionDef['thicknessTexture'] = thicknessMapDef;

		}

		extensionDef['attenuationDistance'] = material.attenuationDistance;
		extensionDef['attenuationColor'] = material.attenuationColor?.toNumArray([]);

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}

/**
 * Materials ior Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_ior
 */
class GLTFMaterialsIorExtension extends GLTFExtension{

	GLTFMaterialsIorExtension( super.writer ) {
		this.name = 'KHR_materials_ior';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.ior == 1.5 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['ior'] = material.ior;

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Materials specular Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_specular
 */
class GLTFMaterialsSpecularExtension extends GLTFExtension{

	GLTFMaterialsSpecularExtension( super.writer ) {
		this.name = 'KHR_materials_specular';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (( material.specularIntensity == 1.0 &&
		      (material.specularColor?.equals( DEFAULT_SPECULAR_COLOR ) ?? false) &&
		     material.specularIntensityMap == null && ! material.specularColorTexture ) ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.specularIntensityMap != null) {
			final specularIntensityMapDef = {
				'index': writer.processTexture( material.specularIntensityMap ),
				'texCoord': material.specularIntensityMap?.channel
			};
			writer.applyTextureTransform( specularIntensityMapDef, material.specularIntensityMap );
			extensionDef['specularTexture'] = specularIntensityMapDef;
		}

		if ( material.specularColorMap != null) {
			final specularColorMapDef = {
				'index': writer.processTexture( material.specularColorMap ),
				'texCoord': material.specularColorMap?.channel
			};
			writer.applyTextureTransform( specularColorMapDef, material.specularColorMap );
			extensionDef['specularColorTexture'] = specularColorMapDef;
		}

		extensionDef['specularFactor'] = material.specularIntensity;
		extensionDef['specularColorFactor'] = material.specularColor?.toNumArray([]);

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Sheen Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_sheen
 */
class GLTFMaterialsSheenExtension extends GLTFExtension{

	GLTFMaterialsSheenExtension( super.writer ) {
		this.name = 'KHR_materials_sheen';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.sheen == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.sheenRoughnessMap != null) {
			final sheenRoughnessMapDef = {
				'index': writer.processTexture( material.sheenRoughnessMap ),
				'texCoord': material.sheenRoughnessMap?.channel
			};
			writer.applyTextureTransform( sheenRoughnessMapDef, material.sheenRoughnessMap );
			extensionDef['sheenRoughnessTexture'] = sheenRoughnessMapDef;
		}

		if ( material.sheenColorMap != null) {
			final sheenColorMapDef = {
				'index': writer.processTexture( material.sheenColorMap ),
				'texCoord': material.sheenColorMap?.channel
			};
			writer.applyTextureTransform( sheenColorMapDef, material.sheenColorMap );
			extensionDef['sheenColorTexture'] = sheenColorMapDef;
		}

		extensionDef['sheenRoughnessFactor'] = material.sheenRoughness;
		extensionDef['sheenColorFactor'] = material.sheenColor?.toNumArray([]);

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Anisotropy Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_anisotropy
 */
class GLTFMaterialsAnisotropyExtension extends GLTFExtension{

	GLTFMaterialsAnisotropyExtension( super.writer ) {
		this.name = 'KHR_materials_anisotropy';
	}

	void writeMaterial(MeshPhysicalMaterial material, Map materialDef ) {
		if (material.anisotropy == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.anisotropyMap != null) {
			final anisotropyMapDef = { 'index': writer.processTexture( material.anisotropyMap ) };
			writer.applyTextureTransform( anisotropyMapDef, material.anisotropyMap );
			extensionDef['anisotropyTexture'] = anisotropyMapDef;
		}

		extensionDef['anisotropyStrength'] = material.anisotropy;
		extensionDef['anisotropyRotation'] = material.anisotropyRotation;

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * Materials Emissive Strength Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/blob/5768b3ce0ef32bc39cdf1bef10b948586635ead3/extensions/2.0/Khronos/KHR_materials_emissive_strength/README.md
 */
class GLTFMaterialsEmissiveStrengthExtension extends GLTFExtension{
	GLTFMaterialsEmissiveStrengthExtension(super.writer ) {
		this.name = 'KHR_materials_emissive_strength';
	}

	void writeMaterial(MeshStandardMaterial material, Map materialDef ) {
		if (material.emissiveIntensity == 1.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['emissiveStrength'] = material.emissiveIntensity;

		materialDef['extensions'] = materialDef['extensions'] ?? {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

/**
 * GPU Instancing Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Vendor/EXT_mesh_gpu_instancing
 */
class GLTFMeshGpuInstancing extends GLTFExtension{

	GLTFMeshGpuInstancing( super.writer ) {
		this.name = 'EXT_mesh_gpu_instancing';
	}

	void writeNode(InstancedMesh object, Map nodeDef ) {
		final writer = this.writer;
		final mesh = object;

		final translationAttr = Float32Array( mesh.count * 3 );
		final rotationAttr = Float32Array( mesh.count * 4 );
		final scaleAttr = Float32Array( mesh.count * 3 );

		final matrix = Matrix4();
		final position = Vector3();
		final quaternion = Quaternion();
		final scale = Vector3();

		for (int i = 0; i < (mesh.count ?? 0); i ++ ) {
			mesh.getMatrixAt( i, matrix );
			matrix.decompose( position, quaternion, scale );

			position.toArray( translationAttr, i * 3 );
			quaternion.toArray( rotationAttr, i * 4 );
			scale.toArray( scaleAttr, i * 3 );
		}

		final attributes = {
			'TRANSLATION': writer.processAccessor( Float32BufferAttribute( translationAttr, 3 ) ),
			'ROTATION': writer.processAccessor( Float32BufferAttribute( rotationAttr, 4 ) ),
			'SCALE': writer.processAccessor( Float32BufferAttribute( scaleAttr, 3 ) ),
		};

		if ( mesh.instanceColor != null)
			attributes['_COLOR_0'] = writer.processAccessor( mesh.instanceColor );

		nodeDef['extensions'] = nodeDef['extensions'] ?? {};
		nodeDef['extensions'][ this.name ] = { attributes };

		writer.extensionsUsed[ this.name ] = true;
		writer.extensionsRequired[ this.name ] = true;
	}
}

/**
 * Static utility functions
 */
class GLTFExporterUtils{

	insertKeyframe( track, time ) {
		final tolerance = 0.001; // 1ms
		final valueSize = track.getValueSize();

		final times = track.TimeBufferType( track.times.length + 1 );
		final values = track.ValueBufferType( track.values.length + valueSize );
		final interpolant = track.createInterpolant( track.ValueBufferType( valueSize ) );

		var index;

		if ( track.times.length == 0 ) {
			times[ 0 ] = time;

			for (int i = 0; i < valueSize; i ++ ) {
				values[ i ] = 0;
			}

			index = 0;
		} 
    else if ( time < track.times[ 0 ] ) {
			if (( track.times[ 0 ] - time ).abs() < tolerance ) return 0;

			times[ 0 ] = time;
			times.set( track.times, 1 );

			values.set( interpolant.evaluate( time ), 0 );
			values.set( track.values, valueSize );

			index = 0;
		} 
    else if ( time > track.times[ track.times.length - 1 ] ) {
			if (( track.times[ track.times.length - 1 ] - time ).abs() < tolerance ) {
				return track.times.length - 1;
			}
			times[ times.length - 1 ] = time;
			times.set( track.times, 0 );

			values.set( track.values, 0 );
			values.set( interpolant.evaluate( time ), track.values.length );

			index = times.length - 1;
		} 
    else {
			for (int i = 0; i < track.times.length; i ++ ) {
				if (( track.times[ i ] - time ).abs() < tolerance ) return i;
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
	}

	static mergeMorphTargetTracks( clip, root ) {
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
					throw( 'THREE.GLTFExporter: Cannot merge tracks with glTF CUBICSPLINE interpolation.' );
				}

				console.warning( 'THREE.GLTFExporter: Morph target interpolation mode not yet supported. Using LINEAR instead.' );

				sourceTrack = sourceTrack.clone();
				sourceTrack.setInterpolation( InterpolateLinear );
			}

			final targetCount = sourceTrackNode.morphTargetInfluences.length;
			final targetIndex = sourceTrackNode.morphTargetDictionary[ sourceTrackBinding.propertyIndex ];

			if ( targetIndex == null ) {
				throw('THREE.GLTFExporter: Morph target name not found: ' + sourceTrackBinding.propertyIndex );
			}

			var mergedTrack;

			// If this is the first time we've seen this object, create a new
			// track to store merged keyframe data for each morph target.
			if ( mergedTracks[ sourceTrackNode.uuid ] == null ) {
				mergedTrack = sourceTrack.clone();

				final values = mergedTrack.ValueBufferType( targetCount * mergedTrack.times.length );

				for (int j = 0; j < mergedTrack.times.length; j ++ ) {
					values[ j * targetCount + targetIndex ] = mergedTrack.values[ j ];
				}

				// We need to take into consideration the intended target node
				// of our original un-merged morphTarget animation.
				mergedTrack.name = ( sourceTrackBinding.nodeName ?? '' ) + '.morphTargetInfluences';
				mergedTrack.values = values;

				mergedTracks[ sourceTrackNode.uuid ] = mergedTrack;
				tracks.add( mergedTrack );

				continue;
			}

			final sourceInterpolant = sourceTrack.createInterpolant(sourceTrack.ValueBufferType( 1 ) );

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
}
