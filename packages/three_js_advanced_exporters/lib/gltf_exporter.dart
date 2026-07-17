import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';
import 'package:three_js_advanced_exporters/image/texture_converter.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:image/image.dart' as img;

class GLTFOptions{
  ExportTypes type;
  bool trs; 
  bool onlyVisible;
  bool includeCustomExtensions;
  late int maxTextureSize;
  late final List<AnimationClip> animations;

  GLTFOptions({
    this.type = ExportTypes.ascii,
    this.trs = false,
    this.onlyVisible = true,
    int? maxTextureSize,
    List<AnimationClip>? animations,
    this.includeCustomExtensions = false
  }){
    this.maxTextureSize = maxTextureSize ?? double.maxFinite.toInt();
    this.animations = animations ?? [];
  }
}

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

extension on BytesBuilder {
  void addUint32(int value) {
    add(Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little));
  }
}

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
		this.register( ( writer ) {
			return new GLTFMaterialsDispersionExtension( writer );
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
		this.register( ( writer ) {
			return new GLTFMaterialsBumpExtension( writer );
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

  Future<void> export(String fileName, Object3D scene, {String? path, GLTFOptions? options}) async{
    exportList(fileName, [scene],path: path,options: options);
  }

  Future<void> exportList(String fileName, List<Object3D> scene, {String? path, GLTFOptions? options}) async{
    options ??= GLTFOptions();
    final data = await parseList(scene,options);
    if(options.type == ExportTypes.ascii){
      final encoder = JsonEncoder.withIndent('\t');
      SaveFile.saveString(
        printName: fileName, 
        fileType: 'gltf',
        data: encoder.convert(data),
        path: path
      );
    }
    else{
      SaveFile.saveBytes(
        printName: fileName, 
        fileType: 'glb', 
        bytes: Uint8List.fromList(data), 
        path: path
      );
    }
  }

	Future<dynamic> parse(Object3D input, [GLTFOptions? options]) async{
		return parseList([input],options);
	}

	Future<dynamic> parseList(List<Object3D> input, [GLTFOptions? options]) async{
		final writer = GLTFWriter();
		final plugins = <GLTFExtension>[];

		for (int i = 0, il = this.pluginCallbacks.length; i < il; i ++ ) {
			plugins.add( this.pluginCallbacks[ i ]( writer ) );
		}

		writer.setPlugins( plugins );
		return writer.write( input, options ?? GLTFOptions());
	}
}

//------------------------------------------------------------------------------
// finalants
//------------------------------------------------------------------------------

class WEBGLConstants {
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
  NearestFilter: WEBGLConstants.NEAREST,
  NearestMipmapNearestFilter: WEBGLConstants.NEAREST_MIPMAP_NEAREST,
  NearestMipmapLinearFilter: WEBGLConstants.NEAREST_MIPMAP_LINEAR,
  LinearFilter: WEBGLConstants.LINEAR,
  LinearMipmapNearestFilter: WEBGLConstants.LINEAR_MIPMAP_NEAREST,
  LinearMipmapLinearFilter: WEBGLConstants.LINEAR_MIPMAP_LINEAR,

  ClampToEdgeWrapping: WEBGLConstants.CLAMP_TO_EDGE,
  RepeatWrapping: WEBGLConstants.REPEAT,
  MirroredRepeatWrapping: WEBGLConstants.MIRRORED_REPEAT,
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


class GLTFUtils {
  GLTFUtils();

  /// Compare two lists for exact element matching
  bool equalArray(List array1, List array2) {
    // 1. Instantly return false if length sizes do not align
    if (array1.length != array2.length) return false;
    
    // 2. Loop through and evaluate each item sequentially
    for (int i = 0; i < array1.length; i++) {
      if (array1[i] != array2[i]) return false;
    }
    
    // 3. Fallback confirmation if all elements match perfectly
    return true;
  }

  /// Converts a string to an ArrayBuffer (ByteBuffer).
  ByteBuffer stringToArrayBuffer(String text) {
    return Uint8List.fromList(utf8.encode(text)).buffer;
  }

  /// Is identity matrix
  bool isIdentityMatrix(Matrix4 matrix) {
    return equalArray(
      matrix.storage.toList(), 
      [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
    );
  }

  Map<String, List<double>> getMinMax(BufferAttribute attribute, int start, int count) {
    final Map<String, List<double>> output = {
      'min': List.filled(attribute.itemSize, double.infinity),
      'max': List.filled(attribute.itemSize, -double.infinity)
    };

    // Safe upper boundary guard to make sure we never overshoot the attribute array bounds
    int end = math.min(start + count, attribute.count);

    for (int i = start; i < end; i++) {
      for (int a = 0; a < attribute.itemSize; a++) {
        double? value;
        
        if (attribute.itemSize > 4) {
          // No support for interleaved data for itemSize > 4
          value = attribute.array[i * attribute.itemSize + a];
        } else {
          if (a == 0) value = attribute.getX(i)?.toDouble();
          else if (a == 1) value = attribute.getY(i)?.toDouble();
          else if (a == 2) value = attribute.getZ(i)?.toDouble();
          else if (a == 3) value = attribute.getW(i)?.toDouble();

          if (attribute.normalized == true) {
            value = MathUtils.normalize(
              value!, 
              attribute.array.buffer.asFloat32List()
            );
          }
        }

        if (value != null) {
          double doubleVal = value.toDouble();
          output['min']![a] = math.min(output['min']![a], doubleVal);
          output['max']![a] = math.max(output['max']![a], doubleVal);
        }
      }
    }
    return output;
  }

  /// Get the required size + padding for a buffer, rounded to the next 4-byte boundary.
  int getPaddedBufferSize(num bufferSize) {
    return (bufferSize / 4).ceil() * 4;
  }

  /// Returns a buffer aligned to 4-byte boundary.
  ByteBuffer getPaddedArrayBuffer(ByteBuffer arrayBuffer, [int paddingByte = 0]) {
    final int paddedLength = getPaddedBufferSize(arrayBuffer.lengthInBytes);
    
    if (paddedLength != arrayBuffer.lengthInBytes) {
      final Uint8List view = arrayBuffer.asUint8List();
      final Uint8List alignedArray = Uint8List(paddedLength);
      
      // Copy the original data over
      alignedArray.setRange(0, view.length, view);
      
      // If a non-zero padding byte is defined, fill remaining spaces
      if (paddingByte != 0) {
        for (int i = arrayBuffer.lengthInBytes; i < paddedLength; i++) {
          alignedArray[i] = paddingByte;
        }
      }
      return alignedArray.buffer;
    }
    return arrayBuffer;
  }

  /// Cross-platform replacement for getCanvas() and getToBlobPromise().
  /// Completely removes web-only DOM assumptions so the code is safe on iOS, Android, and Desktop.
  Future<Uint8List?> processTexturePayload(Uint8List rawRgbaBytes, int width, int height, String mimeType) async {
    // We bypass Web Canvas and Blobs entirely. Your texture framework handles image extraction natively.
    // This allows you to immediately pass the buffer payload back to your pipeline.
    return rawRgbaBytes;
  }
}

/**
 * Writer
 */
class GLTFWriter {
  List<GLTFExtension> plugins = [];

  GLTFOptions options = GLTFOptions();
  List<Uint8List> buffers = [];

  int byteOffset = 0;
  Map nodeMap = Map();
  List skins = [];

  Map<String,dynamic> extensionsUsed = {};
  Map<String,dynamic> extensionsRequired = {};

  Map uids = Map();
  int uid = 0;

  GLTFUtils utils = GLTFUtils();
  TextureConverter tc = TextureConverter();

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

	void setPlugins(List<GLTFExtension> plugins ) {
		this.plugins = plugins;
	}

  /// Parse scenes and generate GLTF output
  Future<dynamic> write(List<Object3D> input, GLTFOptions options) async {
    if (options.animations.isNotEmpty) {
      // Only TRS properties, and not matrices, may be targeted by animation.
      options.trs = true;
    }
    
    this.options = options;

    // 2. Run structural asset indexing routines
    await this.processInput(input);

    final List<Uint8List> buffers = this.buffers;
    final Map<String, dynamic> json = this.json;
    final Map<String, dynamic> extensionsUsed = this.extensionsUsed;
    final Map<String, dynamic> extensionsRequired = this.extensionsRequired;

    // 3. Flatten chunk array lists into a single consolidated byte buffer
    final BytesBuilder blobBuilder = BytesBuilder();
    for (final buffer in buffers) {
      blobBuilder.add(buffer);
    }
    final Uint8List consolidatedBlob = blobBuilder.takeBytes();

    // 4. Map extensions configuration flags to output JSON root
    final List<String> extensionsUsedList = extensionsUsed.keys.toList();
    final List<String> extensionsRequiredList = extensionsRequired.keys.toList();

    if (extensionsUsedList.isNotEmpty) json['extensionsUsed'] = extensionsUsedList;
    if (extensionsRequiredList.isNotEmpty) json['extensionsRequired'] = extensionsRequiredList;

    // 5. Update overall byteLength layout configuration inside the root JSON reference
    if (json['buffers'] != null && (json['buffers'] as List).isNotEmpty) {
      json['buffers'][0]['byteLength'] = consolidatedBlob.length;
    }

    // 6. Handle Binary Layout Generation (.GLB structure extraction)
    if (options.type == ExportTypes.binary) {
      // Structural Data Alignments targeting explicit 4-byte boundaries
      final ByteBuffer binaryChunk = utils.getPaddedArrayBuffer(consolidatedBlob.buffer);
      final Uint8List binView = binaryChunk.asUint8List();

      // Prepare JSON Chunk text representations
      String jsonString = jsonEncode(json);
      final ByteBuffer jsonChunk = utils.getPaddedArrayBuffer(utils.stringToArrayBuffer(jsonString), 0x20);
      final Uint8List jsonView = jsonChunk.asUint8List();

      final BytesBuilder glbBuilder = BytesBuilder();

      // -- EXPORT HEADER COMPILER (12 Bytes Total) --
      glbBuilder.addUint32(GLB_HEADER_MAGIC);
      glbBuilder.addUint32(GLB_VERSION);
      
      int totalByteLength = GLB_HEADER_BYTES + 
                            GLB_CHUNK_PREFIX_BYTES + jsonView.length + 
                            GLB_CHUNK_PREFIX_BYTES + binView.length;
      glbBuilder.addUint32(totalByteLength);

      // -- CHUNK 0: SCENE DESCRIPTION DETAILS (JSON Payload Block) --
      glbBuilder.addUint32(jsonView.length);
      glbBuilder.addUint32(GLB_CHUNK_TYPE_JSON);
      glbBuilder.add(jsonView);

      // -- CHUNK 1: STRUCTURAL GRAPH DATA (Binary Vertex Properties Array Payload Block) --
      glbBuilder.addUint32(binView.length);
      glbBuilder.addUint32(GLB_CHUNK_TYPE_BIN);
      glbBuilder.add(binView);

      return glbBuilder.takeBytes(); // Directly yields final self-contained Uint8List bytes
    } 
    
    // 7. Handle standard ASCII / String embedded JSON structures (.gltf fallback format rules)
    else {
      if (json['buffers'] != null && (json['buffers'] as List).isNotEmpty) {
        // In Dart, instead of a FileReader DataURL string parse, instantly write inline base64
        final String base64data = 'data:application/octet-stream;base64,${base64Encode(consolidatedBlob)}';
        json['buffers'][0]['uri'] = base64data;
      }
      return json; // Instantly return the structured data Map object directly to the await pipeline
    }
  }

  /// Serializes a userData map from an Object3D or Material into the GLTF object definition map.
  void serializeUserData(dynamic object, Map<String, dynamic> objectDef) {
    // 1. Guard clause: Ensure object has userData and it is not empty
    if (object.userData.keys.isEmpty) return;

    final GLTFOptions configOptions = this.options;
    final Map<String, dynamic> extensionsUsed = this.extensionsUsed;

    try {
      // 2. Safely clone the userData map instead of JSON stringify/parse hacks
      final Map<String, dynamic> userDataClone = Map<String, dynamic>.from(object.userData);

      // 3. Process custom glTF extensions if specified in the configuration options
      if (configOptions.includeCustomExtensions == true && userDataClone.containsKey('gltfExtensions')) {
        if (objectDef['extensions'] == null) {
          objectDef['extensions'] = <String, dynamic>{};
        }

        final dynamic gltfExtensions = userDataClone['gltfExtensions'];
        if (gltfExtensions is Map) {
          gltfExtensions.forEach((extensionName, extensionValue) {
            objectDef['extensions'][extensionName] = extensionValue;
            extensionsUsed[extensionName] = true;
          });
        }

        // Replaces the JavaScript 'delete json.gltfExtensions' keyword cleanly
        userDataClone.remove('gltfExtensions');
      }

      // 4. If there are still properties left in userData, attach them to the 'extras' node
      if (userDataClone.keys.isNotEmpty) {
        objectDef['extras'] = userDataClone;
      }
    } catch (error) {
      console.warning("GLTFExporter: userData of '${object.name}' won't be serialized because of error: $error");
    }
  }

  /// Returns unique identifiers for buffer attributes.
  /// Maps attributes to distinct relative and absolute index allocations.
  int getUID(dynamic attribute, [bool isRelativeCopy = false]) {
    // Ensure the caching system map is fully instantiated on your exporter class level
    // declaration field should be: final Map<dynamic, Map<bool, int>> uids = {};
    final Map localUids = this.uids;

    if (!localUids.containsKey(attribute)) {
      final Map<bool, int> attributeUids = {
        true: this.uid++,
        false: this.uid++,
      };
      localUids[attribute] = attributeUids;
    }

    final Map<bool, int> trackingMap = localUids[attribute]!;
    return trackingMap[isRelativeCopy]!;
  }

	/**
	 * Checks if normal attribute values are normalized.
	 */
	bool isNormalizedNormalAttribute(BufferAttribute normal ) {
		final cache = this.cache;

		if ( cache['attributesNormalized']?.containsValue( normal ) ?? false) return false;

		final v = Vector3();

		for (int i = 0, il = normal.count; i < il; i ++ ) {
			// 0.0005 is from glTF-validator
			if (( v.fromArray( normal.array.buffer.asFloat32List(), i ).length - 1.0 ).abs() > 0.0005 ) return false;
		}

		return true;
	}

	/**
	 * Creates normalized normal buffer attribute.
	 */
	BufferAttribute createNormalizedNormalAttribute(BufferAttribute normal ) {
		final cache = this.cache;

		if ( cache['attributesNormalized']?.containsValue( normal ) == true && cache['attributesNormalized']?[normal] != null){
      return cache['attributesNormalized']?[normal];//CHECK
    }

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
		bool didTransform = false;
		final transformDef = {};

		if ( texture.offset.x != 0 || texture.offset.y != 0 ) {
			transformDef['offset'] = texture.offset.storage.toList();
			didTransform = true;
		}

		if ( texture.rotation != 0 ) {
			transformDef['rotation'] = texture.rotation;
			didTransform = true;
		}

		if ( texture.repeat.x != 1 || texture.repeat.y != 1 ) {
			transformDef['scale'] = texture.repeat.storage.toList();
			didTransform = true;
		}

		if ( didTransform ) {
			mapDef['extensions'] ??= {};
			mapDef['extensions'][ 'KHR_texture_transform' ] = transformDef;
			this.extensionsUsed[ 'KHR_texture_transform' ] = true;
		}
	}

  Future<Texture?> buildMetalRoughTexture(Texture? metalnessMap, Texture? roughnessMap) async {
    if (metalnessMap == roughnessMap) return metalnessMap;

    // 1. Establish structural color space transformation functions
    double Function(double) getEncodingConversion(Texture? map) {
      // In three_js, color spaces are checked against core string/enum constants
      if (map?.colorSpace == 'srgb') {
        return (double c) {
          return (c < 0.04045) ? c * 0.0773993808 : math.pow(c * 0.9478672986 + 0.0521327014, 2.4).toDouble();
        };
      }
      return (double c) => c; // Linear fallback identity
    }

    console.warning('GLTFExporter: Merged metalnessMap and roughnessMap textures.');

    // Note: If you have dynamic MathUtils.decompress routines in your project suite, 
    // you can uncomment these decompression fallback checks.
    if (metalnessMap is CompressedTexture) metalnessMap = tc.decompress(metalnessMap);
    if (roughnessMap is CompressedTexture) roughnessMap = tc.decompress(roughnessMap);

    // 2. Decode the texture elements using your asynchronous ImageExport utility framework
    Uint8List? metalnessBytes;
    Uint8List? roughnessBytes;
    int mWidth = 0, mHeight = 0;
    int rWidth = 0, rHeight = 0;

    if (metalnessMap != null && metalnessMap.image != null) {
      metalnessBytes = await TextureConverter.convertTextureToPNG(metalnessMap, options.maxTextureSize);
      if (metalnessBytes != null) {
        final img.Image? decoded = img.decodeImage(metalnessBytes);
        if (decoded != null) {
          mWidth = decoded.width;
          mHeight = decoded.height;
        }
      }
    }

    if (roughnessMap != null && roughnessMap.image != null) {
      roughnessBytes = await TextureConverter.convertTextureToPNG(roughnessMap, options.maxTextureSize);
      if (roughnessBytes != null) {
        final img.Image? decoded = img.decodeImage(roughnessBytes);
        if (decoded != null) {
          rWidth = decoded.width;
          rHeight = decoded.height;
        }
      }
    }

    // 3. Compute structural output map sizing boundaries
    final int width = math.max<int>(mWidth, rWidth);
    final int height = math.max<int>(mHeight, rHeight);
    
    if (width == 0 || height == 0) return null;

    // 4. Decode backing image objects to perform direct memory pixel data walks
    img.Image? metalImage = metalnessBytes != null ? img.decodeImage(metalnessBytes) : null;
    img.Image? roughImage = roughnessBytes != null ? img.decodeImage(roughnessBytes) : null;

    // If sizes mismatch, resize them to match the target canvas boundary bounds
    if (metalImage != null && (metalImage.width != width || metalImage.height != height)) {
      metalImage = img.copyResize(metalImage, width: width, height: height);
    }
    if (roughImage != null && (roughImage.width != width || roughImage.height != height)) {
      roughImage = img.copyResize(roughImage, width: width, height: height);
    }

    // 5. Initialize the composite glTF ORM target texture array (default fill color: Red=0, Green=255, Blue=255)
    final img.Image composite = img.Image(width: width, height: height, numChannels: 4);
    img.fill(composite, color: img.ColorRgb8(0, 255, 255));

    final double Function(double) convertMetal = getEncodingConversion(metalnessMap);
    final double Function(double) convertRough = getEncodingConversion(roughnessMap);

    // 6. Loop through pixels entirely in-memory to bake the custom channel configurations
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int r = 0;
        int g = 255;
        int b = 255;
        int a = 255;

        if (metalImage != null) {
          final pixel = metalImage.getPixel(x, y);
          // Extract raw blue channel pixel values (index 2 in JS imageData arrays)
          double rawB = pixel.b / 255.0;
          b = (convertMetal(rawB) * 255.0).round().clamp(0, 255);
        }

        if (roughImage != null) {
          final pixel = roughImage.getPixel(x, y);
          // Extract raw green channel pixel values (index 1 in JS imageData arrays)
          double rawG = pixel.g / 255.0;
          g = (convertRough(rawG) * 255.0).round().clamp(0, 255);
        }

        // Write back directly into the composited image object structure
        composite.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }

    // 7. Re-encode the optimized in-memory image array out to standard PNG bytes
    final Uint8List bakedPngBytes = Uint8List.fromList(img.encodePng(composite));

    // 8. Reconstruct and clone the final texture container wrapper object
    final reference = metalnessMap ?? roughnessMap;
    final Texture? texture = reference?.clone();
    
    if (texture != null) {
      // Inject the raw bytes payload straight into a three_js Source layer
      texture.image = ImageElement(data: bakedPngBytes, width: width, height: height);
      texture.colorSpace = 'no-color-space'; // Replaces NoColorSpace
      texture.channel = metalnessMap?.channel ?? roughnessMap?.channel ?? 0;
    }

    if (metalnessMap != null && roughnessMap != null && metalnessMap.channel != roughnessMap.channel) {
      console.warning('GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.');
    }

    return texture;
  }


	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	int processBuffer(ByteBuffer buffer ) {
		final json = this.json;
		final buffers = this.buffers;

		if (json['buffers'] == null) json['buffers'] = [ <String,dynamic>{ 'byteLength': 0 } ];

		// All buffers are merged before export.
		buffers.add( buffer.asUint8List() );

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
			case WEBGLConstants.BYTE:
			case WEBGLConstants.UNSIGNED_BYTE:
				componentSize = 1;
				break;
			case WEBGLConstants.SHORT:
			case WEBGLConstants.UNSIGNED_SHORT:
				componentSize = 2;
				break;
			default:
				componentSize = 4;
		}

		final byteLength = utils.getPaddedBufferSize( count * attribute.itemSize * componentSize );
		final ByteData dataView = ByteData(byteLength);
		int offset = 0;

		for (int i = start; i < start + count; i ++ ) {
			for (int a = 0; a < attribute.itemSize; a ++ ) {

				num? value;

				if ( attribute.itemSize > 4 ) {
					 // no support for interleaved data for itemSize > 4
					value = attribute.array[ i * attribute.itemSize + a ];
				} 
        else {
					if ( a == 0 ) value = attribute.getX( i );
					else if ( a == 1 ) value = attribute.getY( i );
					else if ( a == 2 ) value = attribute.getZ( i );
					else if ( a == 3 ) value = attribute.getW( i );

					if (value != null && attribute.normalized == true ) {
						value = MathUtils.normalize( value, attribute.array );
					}
				}
        if(value != null){
          if ( componentType == WEBGLConstants.FLOAT ) {
            dataView.setFloat32( offset, value.toDouble(), Endian.little );
          } else if ( componentType == WEBGLConstants.INT ) {
            dataView.setInt32( offset, value.toInt(), Endian.little );
          } else if ( componentType == WEBGLConstants.UNSIGNED_INT ) {
            dataView.setUint32( offset, value.toInt(), Endian.little );
          } else if ( componentType == WEBGLConstants.SHORT ) {
            dataView.setInt16( offset, value.toInt(), Endian.little );
          } else if ( componentType == WEBGLConstants.UNSIGNED_SHORT ) {
            dataView.setUint16( offset, value.toInt(), Endian.little );
          } else if ( componentType == WEBGLConstants.BYTE ) {
            dataView.setInt8( offset, value.toInt() );
          } else if ( componentType == WEBGLConstants.UNSIGNED_BYTE ) {
            dataView.setUint8( offset, value.toInt() );
          }
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

		if ( target == WEBGLConstants.ARRAY_BUFFER ) {
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

  /// Process and generate a BufferView from a raw image byte array.
  /// Returns the assigned index integer of the newly appended bufferView.
  int processBufferViewImage(Uint8List imageBytes) {
    final Map<String, dynamic> json = this.json;
    
    if (json['bufferViews'] == null) {
      json['bufferViews'] = <Map<String, dynamic>>[];
    }

    // 1. Pad the byte buffer to conform to the glTF 4-byte structural boundary spec
    final ByteBuffer alignedBuffer = utils.getPaddedArrayBuffer(imageBytes.buffer);
    final Uint8List view = alignedBuffer.asUint8List();

    // 2. Register the raw buffer and compute file layout offsets
    // Assumes writer.processBuffer accepts a ByteBuffer or Uint8List and returns its structural buffer index
    int bufferIndex = this.processBuffer(alignedBuffer); 

    final Map<String, dynamic> bufferViewDef = {
      'buffer': bufferIndex,
      'byteOffset': this.byteOffset,
      'byteLength': view.length
    };

    // 3. Move the global file tracker pointer forward by the newly added size
    this.byteOffset += view.length;

    // 4. Append definition to root list array and return the calculated element index position
    final List bufferViewsList = json['bufferViews'];
    bufferViewsList.add(bufferViewDef);
    
    return bufferViewsList.length - 1;
  }

	/**
	 * Process attribute to generate an accessor
	 * @param  {BufferAttribute} attribute Attribute to process
	 * @param  {THREE.BufferGeometry} geometry (Optional) Geometry used for truncated draw range
	 * @param  {Integer} start (Optional)
	 * @param  {Integer} count (Optional)
	 * @return {Integer|null} Index of the processed accessor on the "accessors" array
	 */
	int? processAccessor(BufferAttribute attribute, [BufferGeometry? geometry, int? start, int? count]) {
		final json = this.json;

		final Map<int,String> types = {
			1: 'SCALAR',
			2: 'VEC2',
			3: 'VEC3',
			4: 'VEC4',
			9: 'MAT3',
			16: 'MAT4'
		};

		int componentType;

		// Detect the component type of the attribute array
		if ( attribute.array is Float32List) {
			componentType = WEBGLConstants.FLOAT;
		} else if ( attribute.array is Int32List ) {
			componentType = WEBGLConstants.INT;
		} else if ( attribute.array is Uint32List ) {
			componentType = WEBGLConstants.UNSIGNED_INT;
		} else if ( attribute.array is Int16List ) {
			componentType = WEBGLConstants.SHORT;
		} else if ( attribute.array is Uint16List ) {
			componentType = WEBGLConstants.UNSIGNED_SHORT;
		} else if ( attribute.array is Int8List ) {
			componentType = WEBGLConstants.BYTE;
		} else if ( attribute.array is Uint8List ) {
			componentType = WEBGLConstants.UNSIGNED_BYTE;
		} else {
			throw( 'THREE.GLTFExporter: Unsupported bufferAttribute component type: ${attribute.array}');
		}

    if ( start == null ){
      start = 0;
    }
		if (count == null || count == double.maxFinite.toInt() ){
      count = attribute.count;
    }

		// Skip creating an accessor if the attribute doesn't have data to export
		if ( count == 0 ) return null;

		final minMax = utils.getMinMax( attribute, start, count );
		int? bufferViewTarget;

		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if ( geometry != null ) {
			bufferViewTarget = attribute == geometry.index ? WEBGLConstants.ELEMENT_ARRAY_BUFFER : WEBGLConstants.ARRAY_BUFFER;
		}

		final bufferView = this.processBufferView( attribute, componentType, start, count, bufferViewTarget );

		final accessorDef = {
			'bufferView': bufferView['id'],
			if(bufferView['byteOffset']!= null)'byteOffset': bufferView['byteOffset'],
			'componentType': componentType,
			'count': count,
			'max': minMax['max'],
			'min': minMax['min'],
			'type': types[ attribute.itemSize ]
		};

    if (attribute.normalized == true) {
      accessorDef['normalized'] = true;
    }

    // Initialize accessors list if it doesn't exist
    json['accessors'] ??= <Map<String, dynamic>>[];
    
    final List accessorsList = json['accessors'];
    accessorsList.add(accessorDef);
    
    // Returns the index of the newly added item (matching JS .push() behavior)
    return accessorsList.length - 1;
	}


  /// Process image and generate its corresponding glTF entries.
  /// Returns the assigned index integer of the newly processed texture.
  Future<int> processImage(dynamic image, int format, bool flipY, [String? mimeType]) async {
    mimeType ??= 'image/png';
    if (image == null) {
      throw Exception('THREE.GLTFExporter: No valid image data found. Unable to process texture.');
    }

    final Map<String, dynamic> cache = this.cache;
    final Map<String, dynamic> json = this.json;
    final GLTFOptions options = this.options;

    // 1. Setup structural image caching maps to avoid re-processing identical textures
    if (cache['images'] == null) {
      cache['images'] = <dynamic, Map<String, int>>{};
    }
    if (!cache['images'].containsKey(image)) {
      cache['images'][image] = <String, int>{};
    }
    
    final Map<String, int> cachedImages = cache['images'][image];
    final String key = '$mimeType:flipY/$flipY';
    
    if (cachedImages.containsKey(key)) {
      return cachedImages[key]!;
    }

    if (json['images'] == null) {
      json['images'] = <Map<String, dynamic>>[];
    }

    final Map<String, dynamic> imageDef = {'mimeType': mimeType};

    // 2. Safely extract raw texture image data bytes using your custom workflow wrapper
    // This gracefully replaces canvas.getContext('2d') draw/scaling logic blocks
    Uint8List? processedImageBytes;
    
    // Create a pseudo-texture container matching your system's texture-to-png extraction layer
    final Texture structuralTexture = Texture(image);
    structuralTexture.flipY = flipY;
    
    Uint8List? rawBytes = await TextureConverter.convertTextureToPNG(structuralTexture, options.maxTextureSize);
    
    if (rawBytes != null) {
      img.Image? decodedImg = img.decodeImage(rawBytes);
      if (decodedImg != null) {
        // Handle strict resolution boundaries specified in options config 
        int maxTextureSize = options.maxTextureSize;
        if (decodedImg.width > maxTextureSize || decodedImg.height > maxTextureSize) {
          int targetWidth = math.min<int>(decodedImg.width, maxTextureSize);
          int targetHeight = math.min<int>(decodedImg.height, maxTextureSize);
          
          console.warning('GLTFExporter: Image size is bigger than maxTextureSize. Resizing image elements.');
          decodedImg = img.copyResize(decodedImg, width: targetWidth, height: targetHeight);
        }
        
        // Perform fallback re-encoding checks depending on target formats
        if (mimeType == 'image/jpeg') {
          processedImageBytes = Uint8List.fromList(img.encodeJpg(decodedImg, quality: 92));
        } else {
          processedImageBytes = Uint8List.fromList(img.encodePng(decodedImg));
        }
      }
    }

    if (processedImageBytes == null) {
      throw Exception('THREE.GLTFExporter: Failed to extract valid texture byte layouts during asset compilation.');
    }

    // 3. Process structural file compilation branches (Binary Layout vs. Standard ASCII String layout)
    if (options.type == ExportTypes.binary) {
      // Process image as an inline binary data segment bufferView
      int bufferViewIndex = this.processBufferViewImage(processedImageBytes);
      imageDef['bufferView'] = bufferViewIndex;
    } else {
      // Encode the binary bytes to an inline base64 string URI
      final String base64data = 'data:$mimeType;base64,${base64Encode(processedImageBytes)}';
      imageDef['uri'] = base64data;
    }

    // 4. Append image configuration definition map to global glTF tree collection
    final List imagesList = json['images'];
    imagesList.add(imageDef);
    
    int index = imagesList.length - 1;
    cachedImages[key] = index;
    
    return index;
  }


	/**
	 * Process sampler
	 * @param  {Texture} map Texture to process
	 * @return {Integer}     Index of the processed texture in the "samplers" array
	 */
	int processSampler(Texture map ) {
		final json = this.json;

		if (json['samplers'] == null) json['samplers'] = [];

		final samplerDef = {
			'magFilter': THREE_TO_WEBGL[ map.magFilter ],
			'minFilter': THREE_TO_WEBGL[ map.minFilter ],
			'wrapS': THREE_TO_WEBGL[ map.wrapS ],
			'wrapT': THREE_TO_WEBGL[ map.wrapT ]
		};

    json['samplers'].add( samplerDef );
    return json['samplers'].length-1;
	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	Future<int> processTexture(Texture map ) async{
		final writer = this;
		final options = writer.options;
		final cache = this.cache;
		final json = this.json;

		if ( cache['textures']?.containsValue( map ) ?? false){
      return cache['textures']?[map];
    }

		if (json['textures'] == null){
      json['textures'] = [];
    }

		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a texture
		if ( map is CompressedTexture ) {
			map = tc.decompress( map, options.maxTextureSize )!;
		}

		String? mimeType = map.userData['mimeType'];

		if ( mimeType == 'image/webp' ){
      mimeType = 'image/png';
    }

		final textureDef = <String,dynamic>{
			'sampler': this.processSampler( map ),
			'source': (await this.processImage( map.image, map.format, map.flipY, mimeType ))
		};

		textureDef['name'] = map.name;

		this._invokeAll((GLTFExtension ext ) async{
			await ext.writeTexture( map, textureDef );
		} );

		json['textures'].add( textureDef);
    final index = json['textures'].length -1;
		cache['textures']?[map] = index;
		return index;
	}

	Future<int?> processMaterial(Material material ) async{
		final cache = this.cache;
		final json = this.json;

		if ( cache['materials']?.containsKey( material ) == true){
      return cache['materials']?[material];
    }

		if ( material is ShaderMaterial ) {
			console.warning( 'GLTFExporter: THREE.ShaderMaterial not supported.' );
			return null;
		}

		if (json['materials'] == null){
      json['materials'] = [];
    }

		// @QUESTION Should we avoid including any attribute that has the default value?
		final Map<String,dynamic> materialDef = {	'pbrMetallicRoughness': {} };

		if ( material is! MeshStandardMaterial && material is! MeshBasicMaterial) {
			console.warning( 'GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.' );
		}

		// pbrMetallicRoughness.baseColorFactor
    final List<double> color = [
      material.color.red.toDouble(), 
      material.color.green.toDouble(), 
      material.color.blue.toDouble(), 
      material.opacity.toDouble() 
    ];

		if ( ! utils.equalArray( color, [ 1, 1, 1, 1 ] ) ) {
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

			final metalRoughTexture = await this.buildMetalRoughTexture( material.metalnessMap, material.roughnessMap );

			final metalRoughMapDef = <String,dynamic>{
				'index': metalRoughTexture == null?null: await this.processTexture( metalRoughTexture ),
				'channel': metalRoughTexture?.channel
			};
			if(metalRoughTexture != null){
        this.applyTextureTransform( metalRoughMapDef, metalRoughTexture );
      }
			materialDef['pbrMetallicRoughness']['metallicRoughnessTexture'] = metalRoughMapDef;
		}

		// pbrMetallicRoughness.baseColorTexture
		if ( material.map != null) {
			final baseColorMapDef = <String,dynamic>{
				'index': await this.processTexture( material.map! ),
				'texCoord': material.map?.channel
			};
			this.applyTextureTransform( baseColorMapDef, material.map! );
			materialDef['pbrMetallicRoughness']['baseColorTexture'] = baseColorMapDef;
		}

		if ( material.emissive != null) {

			final emissive = material.emissive;
			final maxEmissiveComponent = math.max( math.max(emissive!.red, emissive.green), emissive.blue );

			if ( maxEmissiveComponent > 0 ) {
				materialDef['emissiveFactor'] = material.emissive?.storage.toList();
			}

			// emissiveTexture
			if ( material.emissiveMap != null) {
				final emissiveMapDef = <String,dynamic>{
					'index': await this.processTexture( material.emissiveMap! ),
					'texCoord': material.emissiveMap?.channel
				};
				this.applyTextureTransform( emissiveMapDef, material.emissiveMap! );
				materialDef['emissiveTexture'] = emissiveMapDef;
			}
		}

		// normalTexture
		if ( material.normalMap != null) {

			final Map<String,dynamic> normalMapDef = {
				'index': await this.processTexture( material.normalMap! ),
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
				'index': await this.processTexture( material.aoMap! ),
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

		this._invokeAll((GLTFExtension ext ) async{
			await ext.writeMaterial( material, materialDef );
		} );

		json['materials'].add(materialDef);
    final index = json['materials'].length - 1;
		cache['materials']?[index] = material;
		return index;
	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	Future<int?> processMesh(Object3D mesh ) async{
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

		if ( cache['meshes']?.containsKey( meshCacheKey ) ?? false){
      return cache['meshes']?[meshCacheKey];
    }

		final geometry = mesh.geometry;

		int mode;

		// Use the correct mode
		if ( mesh is LineSegments ) {
			mode = WEBGLConstants.LINES;
		} else if ( mesh is LineLoop ) {
			mode = WEBGLConstants.LINE_LOOP;
		} else if ( mesh is Line ) {
			mode = WEBGLConstants.LINE_STRIP;
		} else if ( mesh is Points ) {
			mode = WEBGLConstants.POINTS;
		} else {
			mode = mesh.material?.wireframe == true? WEBGLConstants.LINES : WEBGLConstants.TRIANGLES;
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
		BufferAttribute? modifiedAttribute = null;

		for (String attributeName in geometry!.attributes.keys ) {

			// Ignore morph target attributes, which are exported later.
			if (attributeName.startsWith('morph')) continue;

			final attribute = geometry.attributes[ attributeName ];
			attributeName = nameConversion[ attributeName ] ?? attributeName.toUpperCase();

			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
      final RegExp validVertexAttributes = RegExp(
        r'^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+|_.*)$'
      );

      // 2. Use .hasMatch() instead of .test()
      if (!validVertexAttributes.hasMatch(attributeName)) {
        attributeName = '_$attributeName';
      }

			if ( cache['attributes']?.containsKey( this.getUID( attribute ) ) == true) {
				attributes[ attributeName ] = cache['attributes']?[this.getUID( attribute )];
				continue;
			}

			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			final array = attribute.array;

			if ( attributeName == 'JOINTS_0' &&
				( array is! Uint16List ) &&
				( array is! Uint8List ) ) {
				console.warning( 'GLTFExporter: Attribute "skinIndex" converted to type UNSIGNED_SHORT.' );
				modifiedAttribute = Uint16BufferAttribute( Uint16List( array ), attribute.itemSize, attribute.normalized );
			}
      else if(( array is Uint32List || array is Int32List ) && ! attributeName.startsWith( '_' )){
				console.warning( 'GLTFExporter: Attribute "${ attributeName }" converted to type FLOAT.' );
				modifiedAttribute = GLTFExporterUtils.toTypedBufferAttribute( attribute );
      }

			final accessor = this.processAccessor( modifiedAttribute ?? attribute, geometry );
			if ( accessor != null ) {
				if ( ! attributeName.startsWith( '_' ) ) {
					this.detectMeshQuantization( attributeName, attribute );
				}

				attributes[ attributeName ] = accessor;
				cache['attributes']?[this.getUID( attribute )] = accessor;
			}
		}

		if ( originalNormal != null ){
      geometry.setAttributeFromString( 'normal', originalNormal );
    }

		// Skip if no exportable attributes found
		if (attributes.keys.isEmpty ){
      return null;
    }

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
				bool warned = false;

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

					final attribute = geometry.morphAttributes[ attributeName ]?[ i ];
					final gltfAttributeName = attributeName.toUpperCase();

					// Three.js morph attribute has absolute values while the one of glTF has relative values.
					//
					// glTF 2.0 Specification:
					// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets

					final BufferAttribute baseAttribute = geometry.attributes[ attributeName ];

					if ( cache['attributes']?.containsKey( this.getUID( attribute, true ) ) == true) {
						target[ gltfAttributeName ] = cache['attributes']![this.getUID( attribute, true )];
						continue;
					}

					// Clones attribute not to override
					final relativeAttribute = attribute?.clone();

					if ( ! geometry.morphTargetsRelative ) {
						for (int j = 0, jl = (attribute?.count ?? 0); j < jl; j ++ ) {
							for (int a = 0; a < (attribute?.itemSize ?? 0); a ++ ) {
								if ( a == 0 ) relativeAttribute!.setX( j, attribute!.getX( j )! - baseAttribute.getX( j )! );
								if ( a == 1 ) relativeAttribute!.setY( j, attribute!.getY( j )! - baseAttribute.getY( j )! );
								if ( a == 2 ) relativeAttribute!.setZ( j, attribute!.getZ( j )! - baseAttribute.getZ( j )! );
								if ( a == 3 ) relativeAttribute!.setW( j, (attribute!.getW( j )! - baseAttribute.getW( j )!).toDouble() );
							}
						}
					}

					if(relativeAttribute != null) target[ gltfAttributeName ] = this.processAccessor( relativeAttribute, geometry );
					cache['attributes']?[this.getUID( baseAttribute, true )] = target[ gltfAttributeName ];
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

		if ( isMultiMaterial && geometry.groups.length == 0 ){
      return null;
    }

    bool didForceIndices = false;

		if ( isMultiMaterial && geometry.index == null ) {
			final indices = [];

			for (int i = 0, il = geometry.attributes['position'].count; i < il; i ++ ) {
				indices[ i ] = i;
			}

			geometry.setIndex( indices );
			didForceIndices = true;
		}

		final List<Material> materials = isMultiMaterial ?( mesh.material as GroupMaterial).children : mesh.material == null?[]:[ mesh.material!];
		final groups = isMultiMaterial ? geometry.groups : [ { 'materialIndex': 0, 'start': null, 'count': null } ];

		for (int i = 0, il = groups.length; i < il; i ++ ) {
			final Map<String,dynamic> primitive = {
				'mode': mode,
				'attributes': attributes,
			};

			this.serializeUserData( geometry, primitive );

			if ( targets.length > 0 ) primitive['targets'] = targets;
			if ( geometry.index != null ) {
        int baseUid = this.getUID(geometry.index);
        String cacheKey = baseUid.toString();

        // 2. Safely inspect and append unique material grouping parameters if they exist
        final currentGroup = groups[i];

        if ((currentGroup['start'] != null || currentGroup['count'] != null)) {
          // Extract values, fallback to 0 safely if one parameter is inexplicably missing
          int start = currentGroup['start']?.toInt() ?? 0;
          int count = currentGroup['count']?.toInt() ?? 0;
          
          cacheKey += ':$start:$count';
        }

				if ( cache['attributes']?.containsKey( cacheKey ) == true) {
					primitive['indices'] = cache['attributes']?[cacheKey];
				} 
        else {
					primitive['indices'] = this.processAccessor( geometry.index!, geometry, groups[ i ]['start'], groups[ i ]['count'] );
					cache['attributes']?[cacheKey] = primitive['indices'];
				}

				if ( primitive['indices'] == null ) primitive.remove('indices');
			}

			final material = await this.processMaterial( materials[groups[ i ]['materialIndex']] );
			primitive['material'] = material;
			primitives.add( primitive );
		}

		if ( didForceIndices == true ) {
			geometry.setIndex( null );
		}

		meshDef['primitives'] = primitives;

		if (json['meshes'] == null) json['meshes'] = [];

		this._invokeAll((GLTFExtension ext ) async{
			await ext.writeMesh( mesh, meshDef );
		} );

		json['meshes'].add( meshDef );
    final index = json['meshes'].length - 1;
		cache['meshes']?[meshCacheKey] = index;

		return index;
	}

	/**
	 * If a vertex attribute with a
	 * [non-standard data type](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes-overview)
	 * is used, it is checked whether it is a valid data type according to the
	 * [KHR_mesh_quantization](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md)
	 * extension.
	 * In this case the extension is automatically added to the list of used extensions.
	 */
	void detectMeshQuantization(String attributeName, BufferAttribute attribute ) {
		if ( this.extensionsUsed[ KHR_MESH_QUANTIZATION ] == true) return;

		String? attrType;
    if(attribute.array is Int8List){
      attrType = 'byte';
    }
    else if(attribute.array is Uint8List){
      attrType = 'unsigned byte';
    }
    else if(attribute.array is Int16List){
      attrType = 'short';
    }
    else if(attribute.array is Uint16List){
      attrType = 'unsigned short';
    }
    else{
      return;
    }
    
		if ( attribute.normalized ){
      attrType += ' normalized';
    }

		final attrNamePrefix = attributeName.split( '_')[ 0 ];

		if ( KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ] != null && KHR_mesh_quantization_ExtraAttrTypes[ attrNamePrefix ]!.contains( attrType ) ) {
			this.extensionsUsed[ KHR_MESH_QUANTIZATION ] = true;
			this.extensionsRequired[ KHR_MESH_QUANTIZATION ] = true;
		}
	}

  /// Process camera object and generate its corresponding glTF specification entry.
  /// Returns the assigned index integer of the newly appended camera.
  int processCamera(Camera camera) {
    final Map<String, dynamic> json = this.json;
    
    if (json['cameras'] == null) {
      json['cameras'] = <Map<String, dynamic>>[];
    }

    // 1. Identify camera projection type safely using Dart standard type checking
    final bool isOrtho = camera is OrthographicCamera;
    
    final Map<String, dynamic> cameraDef = {
      'type': isOrtho ? 'orthographic' : 'perspective'
    };

    // 2. Extract dimensions based on Orthographic vs Perspective properties
    if (isOrtho) {
      // Cast explicitly to check orthogonal properties safely
      final OrthographicCamera orthoCam = camera;
      
      cameraDef['orthographic'] = {
        'xmag': orthoCam.right * 2.0,
        'ymag': orthoCam.top * 2.0,
        'zfar': orthoCam.far <= 0.0 ? 0.001 : orthoCam.far,
        'znear': orthoCam.near < 0.0 ? 0.0 : orthoCam.near
      };
    } 
    else {
      // Cast explicitly to check standard perspective properties safely
      final PerspectiveCamera perspCam = camera as PerspectiveCamera;
      
      cameraDef['perspective'] = {
        'aspectRatio': perspCam.aspect,
        'yfov': MathUtils.degToRad(perspCam.fov),
        'zfar': (perspCam.far) <= 0.0 ? 0.001 : perspCam.far,
        'znear': (perspCam.near) < 0.0 ? 0.0 : perspCam.near
      };
    }

    // 3. Fix the original JS bug: Assign the actual camera name instead of its type!
    if (camera.name.isNotEmpty) {
      cameraDef['name'] = camera.name;
    }

    // 4. Append camera definition map to the root glTF array and yield index track position
    final List camerasList = json['cameras'];
    camerasList.add(cameraDef);
    
    return camerasList.length - 1;
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
	int? processAnimation(AnimationClip clip, Object3D root ) {
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
			Object3D? trackNode = PropertyBinding.findNode( root, trackBinding['nodeName'] );
			final trackProperty = PATH_PROPERTIES[ trackBinding['propertyName'] ];

			if ( trackBinding['objectName'] == 'bones' ) {
				if ( trackNode is SkinnedMesh) {
					trackNode = trackNode.skeleton?.getBoneByName( trackBinding['objectIndex'] );
				} 
        else {
					trackNode = null;
				}
			}

			if ( trackNode == null || trackProperty == null) {
				console.warning( 'THREE.GLTFExporter: Could not export animation track "${track.name}".',  );
				return null;
			}

			final inputItemSize = 1;
			double outputItemSize = track.values.length / track.times.length;

			if ( trackProperty == PATH_PROPERTIES['morphTargetInfluences'] ) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}

			String interpolation;

			// @TODO export CubicInterpolant(InterpolateSmooth) as CUBICSPLINE

			// Detecting glTF cubic spline interpolant by checking factory method's special property
			// GLTFCubicSplineInterpolant is a custom interpolant and track doesn't return
			// valid value from .getInterpolation().
			// if ( track.createInterpolant is InterpolantFactoryMethodGLTFCubicSpline == true ) {
			// 	interpolation = 'CUBICSPLINE';

			// 	// itemSize of CUBICSPLINE keyframe is 9
			// 	// (VEC3 * 3: inTangent, splineVertex, and outTangent)
			// 	// but needs to be stored as VEC3 so dividing by 3 here.
			// 	outputItemSize /= 3;
			// } 
      // else 
      if ( track.getInterpolation() == InterpolateDiscrete ) {
				interpolation = 'STEP';
			} 
      else {
				interpolation = 'LINEAR';
			}
      List<int> cleanTimes = track.times.map((e) => e.toInt()).toList();
      List<double> cleanValues = track.values.map((e) => e.toDouble()).toList();

			samplers.add( {
				'input': this.processAccessor( Uint16BufferAttribute.fromList( cleanTimes, inputItemSize ) ),
				'output': this.processAccessor( Float32BufferAttribute.fromList( cleanValues, outputItemSize.toInt() ) ),
				'interpolation': interpolation
			} );

			channels.add( {
				'sampler': samplers.length - 1,
				'target': {
					'node': nodeMap[trackNode],
					'path': trackProperty
				}
			} );

		}

		json['animations'].add( {
			'name': clip.name,
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
		final inverseBindMatrices = Float32List( skeleton.bones.length * 16 );
		final temporaryBoneInverse = Matrix4();

		for (int i = 0; i < skeleton.bones.length; ++ i ) {
			joints.add( nodeMap[skeleton.bones[ i ]]);
			temporaryBoneInverse.setFrom( skeleton.boneInverses[ i ] );
			temporaryBoneInverse.multiply( object.bindMatrix! ).copyIntoArray( inverseBindMatrices.toList(), i * 16 );
		}

		if ( json['skins'] == null ) json['skins'] = [];

		json['skins'].add( {
			inverseBindMatrices: this.processAccessor( Float32BufferAttribute( inverseBindMatrices, 16 ) ),
			joints: joints,
			skeleton: nodeMap[rootJoint]
		} );

		final skinIndex = node['skin'] = json['skins'].length - 1;

		return skinIndex;
	}

  /// Process Object3D node
  /// Returns the assigned index integer of the node in the nodes list.
  Future<int?> processNode(Object3D object) async{
    final Map<String, dynamic> json = this.json;
    final GLTFOptions options = this.options;
    final Map nodeMap = this.nodeMap;

    if (json['nodes'] == null) {
      json['nodes'] = <Map<String, dynamic>>[];
    }

		// if ( object.pivot != null ) {
		// 	return await this._processNodeWithPivotAsync( object );
		// }

    final Map<String, dynamic> nodeDef = {};

    // 1. Process Spatial Transforms (TRS vs Unified Matrix Representation)
    if (options.trs) {
      // Generate standard Lists directly using native three_js methods
      final List<double> rotation = [object.quaternion.x.toDouble(), object.quaternion.y.toDouble(), object.quaternion.z.toDouble(), object.quaternion.w.toDouble()];
      final List<double> position = [object.position.x.toDouble(), object.position.y.toDouble(), object.position.z.toDouble()];
      final List<double> scale = [object.scale.x.toDouble(), object.scale.y.toDouble(), object.scale.z.toDouble()];

      // Add elements only if they deviate from their default identity configurations
      if (!utils.equalArray(rotation, [0.0, 0.0, 0.0, 1.0])) {
        nodeDef['rotation'] = rotation;
      }
      if (!utils.equalArray(position, [0.0, 0.0, 0.0])) {
        nodeDef['translation'] = position;
      }
      if (!utils.equalArray(scale, [1.0, 1.0, 1.0])) {
        nodeDef['scale'] = scale;
      }
    } 
    else {
      if (object.matrixAutoUpdate == true) {
        object.updateMatrix();
      }
      if (utils.isIdentityMatrix(object.matrix) == false) {
        // In three_js, matrix data components are pulled via .elements
        nodeDef['matrix'] = object.matrix.storage;
      }
    }

    // 2. Export string identifiers safely
    if (object.name.isNotEmpty) {
      nodeDef['name'] = object.name;
    }

    this.serializeUserData(object, nodeDef);
    // 3. Evaluate active object types cleanly using native type checks
    if (object is Mesh || object is Line || object is Points) {
      final int? meshIndex = await this.processMesh(object);
      if (meshIndex != null) {
        nodeDef['mesh'] = meshIndex;
      }
    } else if (object is Camera) {
      nodeDef['camera'] = this.processCamera(object);
    }

    if (object is SkinnedMesh) {
      this.skins.add(object);
    }

    // 6. Push node setup configurations straight onto global array tree nodes mapping tracking list
    final List nodesList = json['nodes'];
    nodesList.add(nodeDef);
    
    final int nodeIndex = nodesList.length - 1;
    nodeMap[object] = nodeIndex;

    // 4. Recursively compile nested children graphs
    if (object.children.isNotEmpty) {
      final List<int> childrenIndices = [];
      
      for (int i = 0; i < object.children.length; i++) {
        final Object3D child = object.children[i];
        if (child.visible == true || options.onlyVisible == false) {
          final int? nodeIndex = await this.processNode(child);
          if ( nodeIndex != null ){
            childrenIndices.add(nodeIndex);
          }
        }
      }

      if (childrenIndices.isNotEmpty) {
        nodeDef['children'] = childrenIndices;
      }
    }

    // 5. Invoke custom extensions loops if applicable
    this._invokeAll((GLTFExtension ext) {
      ext.writeNode(object, nodeDef);
    });

    return nodeIndex;
  }

	/// Process Scene
	Future<void> processScene(Scene scene ) async{
		final json = this.json;
		final options = this.options;

		if (json['scenes'] == null) {
			json['scenes'] = [];
			json['scene'] = 0;
		}

		final Map<String,dynamic> sceneDef = {};

		if ( scene.name != '' ) sceneDef['name'] = scene.name;
		json['scenes'].add( sceneDef );
		final nodes = [];

		for (int i = 0, l = scene.children.length; i < l; i ++ ) {
			final child = scene.children[ i ];

			if ( child.visible || options.onlyVisible == false ) {
				final int? nodeIndex = await this.processNode( child );
				if ( nodeIndex != null ){
          nodes.add( nodeIndex );
        }
			}
		}

		if ( nodes.length > 0 ) sceneDef['nodes'] = nodes;
		this.serializeUserData( scene, sceneDef );
	}

	/// Creates a Scene to hold a list of objects and parse it
	Future<void> processObjects(List<Object3D> objects ) async{
		final scene = Scene();
		scene.name = 'AuxScene';

		for (int i = 0; i < objects.length; i ++ ) {
			scene.children.add( objects[ i ] );
		}

		await this.processScene( scene );
	}

	Future<void> processInput(List<Object3D> input ) async{
		final options = this.options;

		this._invokeAll((GLTFExtension ext ) {
			ext.beforeParse( input );
		} );

		final List<Object3D> objectsWithoutScene = [];

		for (int i = 0; i < input.length; i ++ ) {
			if (input[ i ] is Scene ) {
				await processScene( input[ i ] as Scene);
			} 
      else {
				objectsWithoutScene.add( input[ i ] );
			}
		}

		if ( objectsWithoutScene.isNotEmpty ){
      await this.processObjects( objectsWithoutScene );
    }

		for (int i = 0; i < this.skins.length; ++ i ) {
			this.processSkin( this.skins[ i ] );
		}

		for (int i = 0; i < options.animations.length; ++ i ) {
			this.processAnimation( options.animations[ i ], input[ 0 ] );
		}

		this._invokeAll((GLTFExtension ext ) {
			ext.afterParse( input );
		} );
	}

	void _invokeAll( func ) {
		for (int i = 0, il = this.plugins.length; i < il; i ++ ) {
			func( this.plugins[ i ] );
		}
	}
}

abstract class GLTFExtension {
  late String name;
  dynamic writer;
  void writeNode(Object3D o, Map nodeDef){}
  void afterParse(List<Object3D> input){}
  void beforeParse(List<Object3D> input){}
  Future<void> writeMaterial(Material material, Map materialDef ) async{}
  Future<void> writeMesh(Object3D mesh, Map node) async{}
  Future<void> writeTexture(Texture map, Map node) async{}
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

  @override
	void writeNode(Object3D light, Map nodeDef ) {
		if (light is! Light || (light is! DirectionalLight && light is! PointLight && light is! SpotLight )) {
			console.warning( 'THREE.GLTFExporter: Only directional, point, and spot lights are supported. $light',  );
			return;
		}

		final writer = this.writer;
		final json = writer.json;
		final extensionsUsed = writer.extensionsUsed;

		final lightDef = {};
    lightDef['name'] = light.name;

		lightDef['color'] = light.color?.toNumArray([0,0,0]);
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

		if (extensionsUsed[ this.name ] == null) {
			json['extensions'] = json['extensions'] ?? {};
			json['extensions'][ this.name ] = { 'lights': [] };
			extensionsUsed[ this.name ] = true;
		}

		final List lights = json['extensions'][ this.name ]['lights'];
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
    if (material is! MeshBasicMaterial ) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		materialDef['extensions'] ??= {};
		materialDef['extensions'][ this.name ] = {};

		extensionsUsed[ this.name ] = true;

		materialDef['pbrMetallicRoughness']['metallicFactor'] = 0.0;
		materialDef['pbrMetallicRoughness']['roughnessFactor'] = 0.9;
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
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
				'index': await writer.processTexture( material.clearcoatRoughnessMap ),
				'texCoord': material.clearcoatRoughnessMap?.channel
			};
			writer.applyTextureTransform( clearcoatRoughnessMapDef, material.clearcoatRoughnessMap );
			extensionDef['clearcoatRoughnessTexture'] = clearcoatRoughnessMapDef;
		}

		if ( material.clearcoatNormalMap != null) {
			final clearcoatNormalMapDef = {
				'index': await writer.processTexture( material.clearcoatNormalMap ),
				'texCoord': material.clearcoatNormalMap?.channel
			};
			writer.applyTextureTransform( clearcoatNormalMapDef, material.clearcoatNormalMap );
			extensionDef['clearcoatNormalTexture'] = clearcoatNormalMapDef;
		}

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial || material.iridescence == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['iridescenceFactor'] = material.iridescence;

		if ( material.iridescenceMap != null) {
			final iridescenceMapDef = {
				'index': await writer.processTexture( material.iridescenceMap ),
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
				'index': await writer.processTexture( material.iridescenceThicknessMap ),
				'texCoord': material.iridescenceThicknessMap?.channel
			};
			writer.applyTextureTransform( iridescenceThicknessMapDef, material.iridescenceThicknessMap );
			extensionDef['iridescenceThicknessTexture'] = iridescenceThicknessMapDef;
		}

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial || material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['transmissionFactor'] = material.transmission;

		if ( material.transmissionMap != null) {
			final transmissionMapDef = {
				'index': await writer.processTexture( material.transmissionMap ),
				'texCoord': material.transmissionMap?.channel
			};
			writer.applyTextureTransform( transmissionMapDef, material.transmissionMap );
			extensionDef['transmissionTexture'] = transmissionMapDef;
		}

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial ||  material.transmission == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['thicknessFactor'] = material.thickness;

		if ( material.thicknessMap != null) {

			final thicknessMapDef = {
				'index': await writer.processTexture( material.thicknessMap ),
				'texCoord': material.thicknessMap?.channel
			};
			writer.applyTextureTransform( thicknessMapDef, material.thicknessMap );
			extensionDef['thicknessTexture'] = thicknessMapDef;

		}

		extensionDef['attenuationDistance'] = material.attenuationDistance;
		extensionDef['attenuationColor'] = material.attenuationColor?.toNumArray([]);

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial || material.ior == 1.5 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['ior'] = material.ior;

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial ||  ( material.specularIntensity == 1.0 &&
		      (material.specularColor?.equals( DEFAULT_SPECULAR_COLOR ) ?? false) &&
		     material.specularIntensityMap == null && material.specularColor != null) ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.specularIntensityMap != null) {
			final specularIntensityMapDef = {
				'index': await writer.processTexture( material.specularIntensityMap ),
				'texCoord': material.specularIntensityMap?.channel
			};
			writer.applyTextureTransform( specularIntensityMapDef, material.specularIntensityMap );
			extensionDef['specularTexture'] = specularIntensityMapDef;
		}

		if ( material.specularColorMap != null) {
			final specularColorMapDef = {
				'index': await writer.processTexture( material.specularColorMap ),
				'texCoord': material.specularColorMap?.channel
			};
			writer.applyTextureTransform( specularColorMapDef, material.specularColorMap );
			extensionDef['specularColorTexture'] = specularColorMapDef;
		}

		extensionDef['specularFactor'] = material.specularIntensity;
		extensionDef['specularColorFactor'] = material.specularColor?.toNumArray([]);

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial || material.sheen == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.sheenRoughnessMap != null) {
			final sheenRoughnessMapDef = {
				'index': await writer.processTexture( material.sheenRoughnessMap ),
				'texCoord': material.sheenRoughnessMap?.channel
			};
			writer.applyTextureTransform( sheenRoughnessMapDef, material.sheenRoughnessMap );
			extensionDef['sheenRoughnessTexture'] = sheenRoughnessMapDef;
		}

		if ( material.sheenColorMap != null) {
			final sheenColorMapDef = {
				'index': await writer.processTexture( material.sheenColorMap ),
				'texCoord': material.sheenColorMap?.channel
			};
			writer.applyTextureTransform( sheenColorMapDef, material.sheenColorMap );
			extensionDef['sheenColorTexture'] = sheenColorMapDef;
		}

		extensionDef['sheenRoughnessFactor'] = material.sheenRoughness;
		extensionDef['sheenColorFactor'] = material.sheenColor?.toNumArray([]);

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshPhysicalMaterial || material.anisotropy == 0.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		if ( material.anisotropyMap != null) {
			final anisotropyMapDef = { 'index': await writer.processTexture( material.anisotropyMap ) };
			writer.applyTextureTransform( anisotropyMapDef, material.anisotropyMap );
			extensionDef['anisotropyTexture'] = anisotropyMapDef;
		}

		extensionDef['anisotropyStrength'] = material.anisotropy;
		extensionDef['anisotropyRotation'] = material.anisotropyRotation;

		materialDef['extensions'] ??= {};
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

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshStandardMaterial || material.emissiveIntensity == 1.0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['emissiveStrength'] = material.emissiveIntensity;

		materialDef['extensions'] ??= {};
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

  @override
	void writeNode(Object3D object, Map nodeDef ) {
    if(object is! InstancedMesh) return;
		final writer = this.writer;
		final mesh = object;

		final translationAttr = Float32List( mesh.count! * 3 );
		final rotationAttr = Float32List( mesh.count! * 4 );
		final scaleAttr = Float32List( mesh.count! * 3 );

		final matrix = Matrix4();
		final position = Vector3();
		final quaternion = Quaternion();
		final scale = Vector3();

		for (int i = 0; i < (mesh.count ?? 0); i ++ ) {
			mesh.getMatrixAt( i, matrix );
			matrix.decompose( position, quaternion, scale );

			position.copyIntoArray( translationAttr.toList(), i * 3 );
			quaternion.toArray( rotationAttr.toList(), i * 4 );
			scale.copyIntoArray( scaleAttr.toList(), i * 3 );
		}

		final attributes = {
			'TRANSLATION': writer.processAccessor( Float32BufferAttribute( translationAttr, 3 ) ),
			'ROTATION': writer.processAccessor( Float32BufferAttribute( rotationAttr, 4 ) ),
			'SCALE': writer.processAccessor( Float32BufferAttribute( scaleAttr, 3 ) ),
		};

		if ( mesh.instanceColor != null){
			attributes['_COLOR_0'] = writer.processAccessor( mesh.instanceColor );
    }

		nodeDef['extensions'] ??= {};
		nodeDef['extensions'][ this.name ] = {'attributes': attributes };

		writer.extensionsUsed[ this.name ] = true;
		writer.extensionsRequired[ this.name ] = true;
	}
}

/**
 * Static utility functions
 */
class GLTFExporterUtils{

	static int insertKeyframe(KeyframeTrack track, time ) {
		final tolerance = 0.001; // 1ms
		final valueSize = track.getValueSize();

		final times = List<num>.filled( track.times.length + 1, 0);
		final values = List<num>.filled( track.values.length + valueSize, 0 );
		final interpolant = track.createInterpolant?.call( List<num>.filled( valueSize, 0 ) );

		late int index;

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
        if (track.times[i] < time && track.times[i + 1] > time) {
          final List<num> newTimes = [];
          newTimes.addAll(track.times.sublist(0, i + 1));
          newTimes.add(time.toDouble());
          newTimes.addAll(track.times.sublist(i + 1));

          final List<num> newValues = [];
          final int startOffset = (i + 1) * valueSize;

          newValues.addAll(track.values.sublist(0, startOffset));
          
          final List<double> interpolated = interpolant.evaluate(time).cast<double>();
          newValues.addAll(interpolated);
          newValues.addAll(track.values.sublist(startOffset));

          times.set(newTimes); 
          values.set(newValues);
          index = i + 1;
          break;
        }
			}
		}

		track.times = times;
		track.values = values;

		return index;
	}

	static mergeMorphTargetTracks(AnimationClip clip, root ) {
		final List<KeyframeTrack> tracks = [];
		final mergedTracks = {};
		final sourceTracks = clip.tracks;

		for (int i = 0; i < sourceTracks.length; ++ i ) {
			KeyframeTrack sourceTrack = sourceTracks[ i ];
			final sourceTrackBinding = PropertyBinding.parseTrackName( sourceTrack.name );
			final sourceTrackNode = PropertyBinding.findNode( root, sourceTrackBinding['nodeName'] );

			if ( sourceTrackBinding['propertyName'] != 'morphTargetInfluences' || sourceTrackBinding['propertyIndex'] == null ) {
				// Tracks that don't affect morph targets, or that affect all morph targets together, can be left as-is.
				tracks.add( sourceTrack );
				continue;
			}

			if ( sourceTrack.createInterpolant != sourceTrack.interpolantFactoryMethodDiscrete
				&& sourceTrack.createInterpolant != sourceTrack.interpolantFactoryMethodLinear ) {

				// if ( sourceTrack.createInterpolant is InterpolantFactoryMethodGLTFCubicSpline ) {
				// 	// This should never happen, because glTF morph target animations
				// 	// affect all targets already.
				// 	throw( 'THREE.GLTFExporter: Cannot merge tracks with glTF CUBICSPLINE interpolation.' );
				// }

				console.warning( 'THREE.GLTFExporter: Morph target interpolation mode not yet supported. Using LINEAR instead.' );

				sourceTrack = sourceTrack.clone();
				sourceTrack.setInterpolation( InterpolateLinear );
			}

			final targetCount = sourceTrackNode?.morphTargetInfluences.length;
			final int? targetIndex = sourceTrackNode?.morphTargetDictionary?[ sourceTrackBinding['propertyIndex'] ];

			if ( targetIndex == null ) {
				throw('GLTFExporter: Morph target name not found: ' + sourceTrackBinding['propertyIndex'] );
			}

			KeyframeTrack mergedTrack;

			// If this is the first time we've seen this object, create a new
			// track to store merged keyframe data for each morph target.
			if ( mergedTracks[ sourceTrackNode?.uuid ] == null ) {
				mergedTrack = sourceTrack.clone();

				final values = List<num>.filled((targetCount ?? 0) * mergedTrack.times.length,0);

				for (int j = 0; j < mergedTrack.times.length; j ++ ) {
					values[ j * (targetCount ?? 0) + targetIndex ] = mergedTrack.values[ j ];
				}

				// We need to take into consideration the intended target node
				// of our original un-merged morphTarget animation.
				mergedTrack.name = ( sourceTrackBinding['nodeName'] ?? '' ) + '.morphTargetInfluences';
				mergedTrack.values = values;

				mergedTracks[ sourceTrackNode?.uuid ] = mergedTrack;
				tracks.add( mergedTrack );

				continue;
			}

			final sourceInterpolant = sourceTrack.createInterpolant?.call([0]);//sourceTrack.valueBufferType( 1 )

			mergedTrack = mergedTracks[ sourceTrackNode?.uuid ];

			// For every existing keyframe of the merged track, write a (possibly
			// interpolated) value from the source track.
			for (int j = 0; j < mergedTrack.times.length; j ++ ) {
				mergedTrack.values[ j * (targetCount ?? 0) + targetIndex ] = sourceInterpolant.evaluate( mergedTrack.times[ j ] );
			}

			// For every existing keyframe of the source track, write a (possibly
			// new) keyframe to the merged track. Values from the previous loop may
			// be written again, but keyframes are de-duplicated.
			for (int j = 0; j < sourceTrack.times.length; j ++ ) {
				final keyframeIndex = insertKeyframe( mergedTrack, sourceTrack.times[ j ] );
				mergedTrack.values[ keyframeIndex * (targetCount ?? 0) + targetIndex ] = sourceTrack.values[ j ];
			}
		}

		clip.tracks = tracks;

		return clip;
	}

	static toTypedBufferAttribute(BufferAttribute srcAttribute ) {
		final dstAttribute = Float32BufferAttribute( Float32List( srcAttribute.count * srcAttribute.itemSize ), srcAttribute.itemSize, false );

		if ( ! srcAttribute.normalized && srcAttribute is! InterleavedBufferAttribute ) {
			dstAttribute.array.set( srcAttribute.array );
			return dstAttribute;
		}

		for ( int i = 0, il = srcAttribute.count; i < il; i ++ ) {
			for ( int j = 0; j < srcAttribute.itemSize; j ++ ) {
				(dstAttribute as InterleavedBufferAttribute).setComponent( i, j, (srcAttribute as InterleavedBufferAttribute).getComponent( i, j ) );
			}
		}

		return dstAttribute;
	}
}

class GLTFMaterialsBumpExtension extends GLTFExtension{

	GLTFMaterialsBumpExtension( super.writer ) {
		this.writer = writer;
		this.name = 'EXT_materials_bump';
	}

	Future<void> writeMaterial(Material material, Map materialDef ) async{
		if (material is! MeshStandardMaterial || (
		       material.bumpScale == 1 &&
		     material.bumpMap == null) ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = <String,dynamic>{};

		if ( material.bumpMap != null) {

			final bumpMapDef = <String, dynamic>{
				'index': await writer.processTexture( material.bumpMap ),
				'texCoord': material.bumpMap?.channel
			};
			writer.applyTextureTransform( bumpMapDef, material.bumpMap );
			extensionDef['bumpTexture'] = bumpMapDef;
		}

		extensionDef['bumpFactor'] = material.bumpScale;

		materialDef['extensions'] ??= {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}

class GLTFMaterialsDispersionExtension extends GLTFExtension{

	GLTFMaterialsDispersionExtension( super.writer ) {
		this.writer = writer;
		this.name = 'KHR_materials_dispersion';
	}

	Future<void> writeMaterial(Material material, Map materialDef ) async{

		if ( material is! MeshPhysicalMaterial || material.dispersion == 0 ) return;

		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;

		final extensionDef = {};

		extensionDef['dispersion'] = material.dispersion;

		materialDef['extensions'] ??= {};
		materialDef['extensions'][ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;
	}
}