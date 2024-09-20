import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * Loader for KTX 2.0 GPU Texture containers.
 *
 * KTX 2.0 is a container format for various GPU texture formats. The loader
 * supports Basis Universal GPU textures, which can be quickly transcoded to
 * a wide variety of GPU texture compression formats, as well as some
 * uncompressed DataTexture and Data3DTexture formats.
 *
 * References:
 * - KTX: http://github.khronos.org/KTX-Specification/
 * - DFD: https://www.khronos.org/registry/DataFormat/specs/1.3/dataformat.1.3.html#basicdescriptor
 */

final _taskCache = WeakMap();

int _activeLoaders = 0;
let _zstd;

class KTX2Loader extends Loader {
  String transcoderPath = '';
  Map<String,dynamic> workerConfig = {};
  String workerSourceURL = '';
  WorkerPool workerPool = new WorkerPool();

	KTX2Loader([LoadingManager? manager]):super( manager ) {
		this.transcoderBinary = null;
		this.transcoderPending = null;

		if ( typeof MSC_TRANSCODER != 'undefined' ) {
			console.warning(
				'THREE.KTX2Loader: Please update to latest "basis_transcoder".'
				+ ' "msc_basis_transcoder" is no longer supported in three.js r125+.'
			);
		}
	}

	KTX2Loader setTranscoderPath(String path ) {
		this.transcoderPath = path;
		return this;
	}

	KTX2Loader setWorkerLimit( num ) {
		this.workerPool.setWorkerLimit( num );
		return this;
	}

	Future<KTX2Loader> detectSupportAsync(Renderer renderer ) async{
		this.workerConfig = {
			'astcSupported': await renderer.hasFeatureAsync( 'texture-compression-astc' ),
			'etc1Supported': await renderer.hasFeatureAsync( 'texture-compression-etc1' ),
			'etc2Supported': await renderer.hasFeatureAsync( 'texture-compression-etc2' ),
			'dxtSupported': await renderer.hasFeatureAsync( 'texture-compression-bc' ),
			'bptcSupported': await renderer.hasFeatureAsync( 'texture-compression-bptc' ),
			'pvrtcSupported': await renderer.hasFeatureAsync( 'texture-compression-pvrtc' )
		};

		return this;
	}

	KTX2Loader detectSupport(WebGLRenderer renderer ) {
		if ( renderer is WebGPURenderer) {
			this.workerConfig = {
				'astcSupported': renderer.hasFeature( 'texture-compression-astc' ),
				'etc1Supported': renderer.hasFeature( 'texture-compression-etc1' ),
				'etc2Supported': renderer.hasFeature( 'texture-compression-etc2' ),
				'dxtSupported': renderer.hasFeature( 'texture-compression-bc' ),
				'bptcSupported': renderer.hasFeature( 'texture-compression-bptc' ),
				'pvrtcSupported': renderer.hasFeature( 'texture-compression-pvrtc' )
			};
		} 
    else {
			this.workerConfig = {
				'astcSupported': renderer.extensions.has( 'WEBGL_compressed_texture_astc' ),
				'etc1Supported': renderer.extensions.has( 'WEBGL_compressed_texture_etc1' ),
				'etc2Supported': renderer.extensions.has( 'WEBGL_compressed_texture_etc' ),
				'dxtSupported': renderer.extensions.has( 'WEBGL_compressed_texture_s3tc' ),
				'bptcSupported': renderer.extensions.has( 'EXT_texture_compression_bptc' ),
				'pvrtcSupported': renderer.extensions.has( 'WEBGL_compressed_texture_pvrtc' )
					|| renderer.extensions.has( 'WEBKIT_WEBGL_compressed_texture_pvrtc' )
			};
		}

		return this;
	}

	init() {

		if ( ! this.transcoderPending ) {

			// Load transcoder wrapper.
			final jsLoader = new FileLoader( this.manager );
			jsLoader.setPath( this.transcoderPath );
			jsLoader.setWithCredentials( this.withCredentials );
			final jsContent = jsLoader.fromAsset( 'basis_transcoder.js' );

			// Load transcoder WASM binary.
			final binaryLoader = new FileLoader( this.manager );
			binaryLoader.setPath( this.transcoderPath );
			binaryLoader.setResponseType( 'arraybuffer' );
			binaryLoader.setWithCredentials( this.withCredentials );
			final binaryContent = binaryLoader.fromAsset( 'basis_transcoder.wasm' );

			this.transcoderPending = Promise.all( [ jsContent, binaryContent ] )
				.then( ( [ jsContent, binaryContent ] ){

					final fn = KTX2Loader.BasisWorker.toString();

					final body = [
						'/* constants */',
						'let _EngineFormat = ' + JSON.stringify( EngineFormat ),
						'let _TranscoderFormat = ' + JSON.stringify( TranscoderFormat ),
						'let _BasisFormat = ' + JSON.stringify( BasisFormat ),
						'/* basis_transcoder.js */',
						jsContent,
						'/* worker */',
						fn.substring( fn.indexOf( '{' ) + 1, fn.lastIndexOf( '}' ) )
					].join( '\n' );

					this.workerSourceURL = URL.createObjectURL( new Blob( [ body ] ) );
					this.transcoderBinary = binaryContent;

					this.workerPool.setWorkerCreator( (){
						final worker = new Worker( this.workerSourceURL );
						final transcoderBinary = this.transcoderBinary.slice( 0 );
						worker.postMessage( { 'type': 'init', 'config': this.workerConfig, transcoderBinary }, [ transcoderBinary ] );
						return worker;
					} );
				} );

			if ( _activeLoaders > 0 ) {

				// Each instance loads a transcoder and allocates workers, increasing network and memory cost.

				console.warning(
					'THREE.KTX2Loader: Multiple active KTX2 loaders may cause performance issues.'
					+ ' Use a single KTX2Loader instance, or call .dispose() on old instances.'
				);
			}

			_activeLoaders ++;
		}

		return this.transcoderPending;
	}

	load( url, onLoad, onProgress, onError ) {

		if ( this.workerConfig == null ) {
			throw( 'THREE.KTX2Loader: Missing initialization with `.detectSupport( renderer )`.' );
		}

		final loader = new FileLoader( this.manager );

		loader.setResponseType( 'arraybuffer' );
		loader.setWithCredentials( this.withCredentials );

		loader.load( url, ( buffer ) => {

			// Check for an existing task using this buffer. A transferred buffer cannot be transferred
			// again from this thread.
			if ( _taskCache.has( buffer ) ) {

				final cachedTask = _taskCache.get( buffer );

				return cachedTask.promise.then( onLoad ).catch( onError );

			}

			this._createTexture( buffer )
				.then( ( texture ) => onLoad ? onLoad( texture ) : null )
				.catch( onError );

		}, onProgress, onError );

	}

	_createTextureFrom( transcodeResult, container ) {

		final { faces, width, height, format, type, error, dfdFlags } = transcodeResult;

		if ( type == 'error' ) return Promise.reject( error );

		let texture;

		if ( container.faceCount == 6 ) {

			texture = new CompressedCubeTexture( faces, format, UnsignedByteType );

		} else {

			final mipmaps = faces[ 0 ].mipmaps;

			texture = container.layerCount > 1
				? new CompressedArrayTexture( mipmaps, width, height, container.layerCount, format, UnsignedByteType )
				: new CompressedTexture( mipmaps, width, height, format, UnsignedByteType );

		}

		texture.minFilter = faces[ 0 ].mipmaps.length == 1 ? LinearFilter : LinearMipmapLinearFilter;
		texture.magFilter = LinearFilter;
		texture.generateMipmaps = false;

		texture.needsUpdate = true;
		texture.colorSpace = parseColorSpace( container );
		texture.premultiplyAlpha = !! ( dfdFlags & KHR_DF_FLAG_ALPHA_PREMULTIPLIED );

		return texture;

	}

	/**
	 * @param {ArrayBuffer} buffer
	 * @param {object?} config
	 * @return {Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture>}
	 */
	 _createTexture( buffer, [Map? config]) async {
    config ??= {};
		final container = read( new Uint8List( buffer ) );

		if ( container.vkFormat != VK_FORMAT_UNDEFINED ) {
			return createRawTexture( container );
		}

		//
		final taskConfig = config;
		final texturePending = this.init().then( (){
			return this.workerPool.postMessage( { 'type': 'transcode', buffer, 'taskConfig': taskConfig }, [ buffer ] );
		} ).then( ( e ) => this._createTextureFrom( e.data, container ) );

		// Cache the task result.
		_taskCache.set( buffer, { 'promise': texturePending } );

		return texturePending;

	}

	void dispose() {
		this.workerPool.dispose();
		if ( this.workerSourceURL ) URL.revokeObjectURL( this.workerSourceURL );
		_activeLoaders --;
	}

  /* WEB WORKER */

  static BasisWorker() {
    let config;
    let transcoderPending;
    let BasisModule;

    self.addEventListener( 'message', ( e ) {

      final message = e.data;

      switch ( message.type ) {

        case 'init':
          config = message.config;
          init( message.transcoderBinary );
          break;

        case 'transcode':
          transcoderPending.then((){
            try {
              final { faces, buffers, width, height, hasAlpha, format, dfdFlags } = transcode( message.buffer );
              self.postMessage( { 'type': 'transcode', 'id': message.id, faces, width, height, hasAlpha, format, dfdFlags }, buffers );
            } catch ( error ) {
              console.error( error );
              self.postMessage( { 'type': 'error', 'id': message.id, 'error': error.message } );
            }
          } );
          break;
      }
    } );

    init( wasmBinary ) {

      transcoderPending = new Promise( ( resolve ) => {
        BasisModule = { wasmBinary, onRuntimeInitialized: resolve };
        BASIS( BasisModule ); // eslint-disable-line no-undef
      } ).then( (){
        BasisModule.initializeBasis();

        if ( BasisModule.KTX2File == null ) {
          console.warning( 'THREE.KTX2Loader: Please update Basis Universal transcoder.' );
        }
      } );
    }

    transcode( buffer ) {
      final ktx2File = BasisModule.KTX2File( new Uint8List( buffer ) );

      cleanup() {
        ktx2File.close();
        ktx2File.delete();
      }

      if ( ! ktx2File.isValid() ) {
        cleanup();
        throw( 'THREE.KTX2Loader:	Invalid or unsupported .ktx2 file' );
      }

      final basisFormat = ktx2File.isUASTC() ? BasisFormat.UASTC_4x4 : BasisFormat.ETC1S;
      final width = ktx2File.getWidth();
      final height = ktx2File.getHeight();
      final layerCount = ktx2File.getLayers() ?? 1;
      final levelCount = ktx2File.getLevels();
      final faceCount = ktx2File.getFaces();
      final hasAlpha = ktx2File.getHasAlpha();
      final dfdFlags = ktx2File.getDFDFlags();

      final temp = getTranscoderFormat( basisFormat, width, height, hasAlpha );
      final transcoderFormat = temp;
      final engineFormat = temp;

      if ( ! width || ! height || ! levelCount ) {
        cleanup();
        throw( 'THREE.KTX2Loader:	Invalid texture' );
      }

      if ( ! ktx2File.startTranscoding() ) {
        cleanup();
        throw( 'THREE.KTX2Loader: .startTranscoding failed' );
      }

      final faces = [];
      final buffers = [];

      for ( int face = 0; face < faceCount; face ++ ) {
        final mipmaps = [];

        for (int mip = 0; mip < levelCount; mip ++ ) {
          final layerMips = [];

          int mipWidth, mipHeight;

          for (int layer = 0; layer < layerCount; layer ++ ) {
            final levelInfo = ktx2File.getImageLevelInfo( mip, layer, face );

            if ( face == 0 && mip == 0 && layer == 0 && ( levelInfo.origWidth % 4 != 0 || levelInfo.origHeight % 4 != 0 ) ) {
              console.warning( 'THREE.KTX2Loader: ETC1S and UASTC textures should use multiple-of-four dimensions.' );
            }

            if ( levelCount > 1 ) {
              mipWidth = levelInfo.origWidth;
              mipHeight = levelInfo.origHeight;
            } 
            else {
              // Handles non-multiple-of-four dimensions in textures without mipmaps. Textures with
              // mipmaps must use multiple-of-four dimensions, for some texture formats and APIs.
              // See mrdoob/three.js#25908.
              mipWidth = levelInfo.width;
              mipHeight = levelInfo.height;
            }

            final dst = Uint8List( ktx2File.getImageTranscodedSizeInBytes( mip, layer, 0, transcoderFormat ) );
            final status = ktx2File.transcodeImage( dst, mip, layer, face, transcoderFormat, 0, - 1, - 1 );

            if ( ! status ) {
              cleanup();
              throw( 'THREE.KTX2Loader: .transcodeImage failed.' );
            }

            layerMips.add( dst );
          }

          final mipData = concat( layerMips );

          mipmaps.add( { 'data': mipData, 'width': mipWidth, 'height': mipHeight } );
          buffers.add( mipData.buffer );
        }

        faces.add({ mipmaps, width, height, 'format': engineFormat});

      }

      cleanup();

      return { faces, buffers, width, height, hasAlpha, 'format': engineFormat, dfdFlags };
    }

    //

    // Optimal choice of a transcoder target format depends on the Basis format (ETC1S or UASTC),
    // device capabilities, and texture dimensions. The list below ranks the formats separately
    // for ETC1S and UASTC.
    //
    // In some cases, transcoding UASTC to RGBA32 might be preferred for higher quality (at
    // significant memory cost) compared to ETC1/2, BC1/3, and PVRTC. The transcoder currently
    // chooses RGBA32 only as a last resort and does not expose that option to the caller.
    final FORMAT_OPTIONS = [
      {
        'if': 'astcSupported',
        'basisFormat': [ BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.ASTC_4x4, TranscoderFormat.ASTC_4x4 ],
        'engineFormat': [ EngineFormat.RGBA_ASTC_4x4_Format, EngineFormat.RGBA_ASTC_4x4_Format ],
        'priorityETC1S': double.infinity,
        'priorityUASTC': 1,
        'needsPowerOfTwo': false,
      },
      {
        'if': 'bptcSupported',
        'basisFormat': [ BasisFormat.ETC1S, BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.BC7_M5, TranscoderFormat.BC7_M5 ],
        'engineFormat': [ EngineFormat.RGBA_BPTC_Format, EngineFormat.RGBA_BPTC_Format ],
        'priorityETC1S': 3,
        'priorityUASTC': 2,
        'needsPowerOfTwo': false,
      },
      {
        'if': 'dxtSupported',
        'basisFormat': [ BasisFormat.ETC1S, BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.BC1, TranscoderFormat.BC3 ],
        'engineFormat': [ EngineFormat.RGBA_S3TC_DXT1_Format, EngineFormat.RGBA_S3TC_DXT5_Format ],
        'priorityETC1S': 4,
        'priorityUASTC': 5,
        'needsPowerOfTwo': false,
      },
      {
        'if': 'etc2Supported',
        'basisFormat': [ BasisFormat.ETC1S, BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.ETC1, TranscoderFormat.ETC2 ],
        'engineFormat': [ EngineFormat.RGB_ETC2_Format, EngineFormat.RGBA_ETC2_EAC_Format ],
        'priorityETC1S': 1,
        'priorityUASTC': 3,
        'needsPowerOfTwo': false,
      },
      {
        'if': 'etc1Supported',
        'basisFormat': [ BasisFormat.ETC1S, BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.ETC1 ],
        'engineFormat': [ EngineFormat.RGB_ETC1_Format ],
        'priorityETC1S': 2,
        'priorityUASTC': 4,
        'needsPowerOfTwo': false,
      },
      {
        'if': 'pvrtcSupported',
        'basisFormat': [ BasisFormat.ETC1S, BasisFormat.UASTC_4x4 ],
        'transcoderFormat': [ TranscoderFormat.PVRTC1_4_RGB, TranscoderFormat.PVRTC1_4_RGBA ],
        'engineFormat': [ EngineFormat.RGB_PVRTC_4BPPV1_Format, EngineFormat.RGBA_PVRTC_4BPPV1_Format ],
        'priorityETC1S': 5,
        'priorityUASTC': 6,
        'needsPowerOfTwo': true,
      },
    ];

    final ETC1S_OPTIONS = FORMAT_OPTIONS.sort( ( a, b ) {
      return (a['priorityETC1S'] as int) - (b['priorityETC1S'] as int);
    } );
    final UASTC_OPTIONS = FORMAT_OPTIONS.sort( ( a, b ) {
      return (a['priorityUASTC'] as int) - (b['priorityUASTC'] as int);
    } );

    getTranscoderFormat( basisFormat, width, height, hasAlpha ) {
      let transcoderFormat;
      let engineFormat;

      final options = basisFormat == BasisFormat.ETC1S ? ETC1S_OPTIONS : UASTC_OPTIONS;
      for (int i = 0; i < options.length; i ++ ) {
        final opt = options[i];

        if ( ! config[ opt['if'] ] ) continue;
        if ( ! opt['basisFormat'].includes( basisFormat ) ) continue;
        if ( hasAlpha && opt['transcoderFormat'].length < 2 ) continue;
        if ( opt['needsPowerOfTwo'] && ! ( isPowerOfTwo( width ) && isPowerOfTwo( height ) ) ) continue;

        transcoderFormat = opt['transcoderFormat'][ hasAlpha ? 1 : 0 ];
        engineFormat = opt['engineFormat'][ hasAlpha ? 1 : 0 ];

        return { transcoderFormat, engineFormat };

      }

      console.warning( 'THREE.KTX2Loader: No suitable compressed texture format found. Decoding to RGBA32.' );

      transcoderFormat = TranscoderFormat.RGBA32;
      engineFormat = EngineFormat.RGBAFormat;

      return { transcoderFormat, engineFormat };

    }
  }
  
  static bool isPowerOfTwo(int value ) {
    if ( value <= 2 ) return true;
    return ( value & ( value - 1 ) ) == 0 && value != 0;
  }

  /** Concatenates N byte arrays. */
  static Uint8List concat(List<Uint8List> arrays ) {
    if ( arrays.length == 1 ) return arrays[ 0 ];

    int totalByteLength = 0;

    for (int i = 0; i < arrays.length; i ++ ) {
      final array = arrays[ i ];
      totalByteLength += array.byteLength;
    }

    final result = new Uint8List( totalByteLength );

    int byteOffset = 0;

    for (int i = 0; i < arrays.length; i ++ ) {
      final array = arrays[ i ];
      result.set( array, byteOffset );

      byteOffset += array.byteLength;
    }

    return result;
  }
  //
  // Parsing for non-Basis textures. These textures are may have supercompression
  // like Zstd, but they do not require transcoding.

  final List<int> UNCOMPRESSED_FORMATS = List.from( [ RGBAFormat, RGFormat, RedFormat ] );

  final FORMAT_MAP = {
    [ VK_FORMAT_R32G32B32A32_SFLOAT ]: RGBAFormat,
    [ VK_FORMAT_R16G16B16A16_SFLOAT ]: RGBAFormat,
    [ VK_FORMAT_R8G8B8A8_UNORM ]: RGBAFormat,
    [ VK_FORMAT_R8G8B8A8_SRGB ]: RGBAFormat,

    [ VK_FORMAT_R32G32_SFLOAT ]: RGFormat,
    [ VK_FORMAT_R16G16_SFLOAT ]: RGFormat,
    [ VK_FORMAT_R8G8_UNORM ]: RGFormat,
    [ VK_FORMAT_R8G8_SRGB ]: RGFormat,

    [ VK_FORMAT_R32_SFLOAT ]: RedFormat,
    [ VK_FORMAT_R16_SFLOAT ]: RedFormat,
    [ VK_FORMAT_R8_SRGB ]: RedFormat,
    [ VK_FORMAT_R8_UNORM ]: RedFormat,

    [ VK_FORMAT_ASTC_6x6_SRGB_BLOCK ]: RGBA_ASTC_6x6_Format,
    [ VK_FORMAT_ASTC_6x6_UNORM_BLOCK ]: RGBA_ASTC_6x6_Format,
  };

  final TYPE_MAP = {
    [ VK_FORMAT_R32G32B32A32_SFLOAT ]: FloatType,
    [ VK_FORMAT_R16G16B16A16_SFLOAT ]: HalfFloatType,
    [ VK_FORMAT_R8G8B8A8_UNORM ]: UnsignedByteType,
    [ VK_FORMAT_R8G8B8A8_SRGB ]: UnsignedByteType,

    [ VK_FORMAT_R32G32_SFLOAT ]: FloatType,
    [ VK_FORMAT_R16G16_SFLOAT ]: HalfFloatType,
    [ VK_FORMAT_R8G8_UNORM ]: UnsignedByteType,
    [ VK_FORMAT_R8G8_SRGB ]: UnsignedByteType,

    [ VK_FORMAT_R32_SFLOAT ]: FloatType,
    [ VK_FORMAT_R16_SFLOAT ]: HalfFloatType,
    [ VK_FORMAT_R8_SRGB ]: UnsignedByteType,
    [ VK_FORMAT_R8_UNORM ]: UnsignedByteType,

    [ VK_FORMAT_ASTC_6x6_SRGB_BLOCK ]: UnsignedByteType,
    [ VK_FORMAT_ASTC_6x6_UNORM_BLOCK ]: UnsignedByteType,
  };

   createRawTexture( container ) async{
    final { vkFormat } = container;

    if ( FORMAT_MAP[ vkFormat ] == null ) {
      throw( 'THREE.KTX2Loader: Unsupported vkFormat.' );
    }

    //

    let zstd;

    if ( container.supercompressionScheme == KHR_SUPERCOMPRESSION_ZSTD ) {

      if ( ! _zstd ) {
        _zstd = new Promise(( resolve )async{

          final zstd = new ZSTDDecoder();
          await zstd.init();
          resolve( zstd );
        });
      }

      zstd = await _zstd;
    }

    //

    final mipmaps = [];


    for ( int levelIndex = 0; levelIndex < container.levels.length; levelIndex ++ ) {
      final levelWidth = math.max<int>( 1, container.pixelWidth >> levelIndex );
      final levelHeight = math.max<int>( 1, container.pixelHeight >> levelIndex );
      final levelDepth = container.pixelDepth ? math.max<int>( 1, container.pixelDepth >> levelIndex ) : 0;

      final level = container.levels[ levelIndex ];

      let levelData;

      if ( container.supercompressionScheme == KHR_SUPERCOMPRESSION_NONE ) {
        levelData = level.levelData;
      } else if ( container.supercompressionScheme == KHR_SUPERCOMPRESSION_ZSTD ) {
        levelData = zstd.decode( level.levelData, level.uncompressedByteLength );
      } else {
        throw( 'THREE.KTX2Loader: Unsupported supercompressionScheme.' );
      }

      let data;

      if ( TYPE_MAP[ vkFormat ] == FloatType ) {
        data = new Float32List(
          levelData.buffer,
          levelData.byteOffset,
          levelData.byteLength / Float32List.bytesPerElement
        );
      } else if ( TYPE_MAP[ vkFormat ] == HalfFloatType ) {
        data = new Uint16List(
          levelData.buffer,
          levelData.byteOffset,
          levelData.byteLength / Uint16List.bytesPerElement
        );
      } else {
        data = levelData;
      }

      mipmaps.add( {
        'data': data,
        'width': levelWidth,
        'height': levelHeight,
        'depth': levelDepth,
      } );
    }

    Texture texture;

    if ( UNCOMPRESSED_FORMATS.has( FORMAT_MAP[ vkFormat ] ) ) {
      texture = container.pixelDepth == 0
        ? new DataTexture( mipmaps[ 0 ].data, container.pixelWidth, container.pixelHeight )
        : new Data3DTexture( mipmaps[ 0 ].data, container.pixelWidth, container.pixelHeight, container.pixelDepth );
    } 
    else {
      if ( container.pixelDepth > 0 ) throw( 'THREE.KTX2Loader: Unsupported pixelDepth.' );
      texture = new CompressedTexture( mipmaps, container.pixelWidth, container.pixelHeight );
    }

    texture.mipmaps = mipmaps;
    texture.type = TYPE_MAP[ vkFormat ];
    texture.format = FORMAT_MAP[ vkFormat ];
    texture.colorSpace = parseColorSpace( container );
    texture.needsUpdate = true;

    return Promise.resolve( texture );
  }

  String parseColorSpace( container ) {
    final dfd = container.dataFormatDescriptor[ 0 ];

    if ( dfd.colorPrimaries == KHR_DF_PRIMARIES_BT709 ) {
      return dfd.transferFunction == KHR_DF_TRANSFER_SRGB ? SRGBColorSpace : LinearSRGBColorSpace;
    } else if ( dfd.colorPrimaries == KHR_DF_PRIMARIES_DISPLAYP3 ) {
      return dfd.transferFunction == KHR_DF_TRANSFER_SRGB ? DisplayP3ColorSpace : LinearDisplayP3ColorSpace;
    } else if ( dfd.colorPrimaries == KHR_DF_PRIMARIES_UNSPECIFIED ) {
      return NoColorSpace;
    } else {
      console.warning( 'THREE.KTX2Loader: Unsupported color primaries, "${ dfd.colorPrimaries }"' );
      return NoColorSpace;
    }
  }
}

class EngineFormat{
  static int RGBAFormat = RGBAFormat;
  static int RGBA_ASTC_4x4_Format =  RGBA_ASTC_4x4_Format;
  static int RGBA_BPTC_Format = RGBA_BPTC_Format;
  static int RGBA_ETC2_EAC_Format = RGBA_ETC2_EAC_Format;
  static int RGBA_PVRTC_4BPPV1_Format = RGBA_PVRTC_4BPPV1_Format;
  static int RGBA_S3TC_DXT5_Format = RGBA_S3TC_DXT5_Format;
  static int RGB_ETC1_Format = RGB_ETC1_Format;
  static int RGB_ETC2_Format = RGB_ETC2_Format;
  static int RGB_PVRTC_4BPPV1_Format = RGB_PVRTC_4BPPV1_Format;
  static int RGBA_S3TC_DXT1_Format = RGBA_S3TC_DXT1_Format;
}

enum BasisFormat{
  ETC1S,
  UASTC_4x4,
}

enum TranscoderFormat{
  ETC1,
  ETC2,
  BC1,
  BC3,
  BC4,
  BC5,
  BC7_M6_OPAQUE_ONLY,
  BC7_M5,
  PVRTC1_4_RGB,
  PVRTC1_4_RGBA,
  ASTC_4x4,
  ATC_RGB,
  ATC_RGBA_INTERPOLATED_ALPHA,
  RGBA32,
  RGB565,
  BGR565,
  RGBA4444,
}