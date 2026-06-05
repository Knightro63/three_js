import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:gpux/gpux.dart';

import '../common/storage_texture.dart';
import '../gpu_backend.dart';
import 'web_gpu_texture_pass_utils.dart';

const _compareToWebGPU = {
	[ NeverCompare ]: 'never',
	[ LessCompare ]: 'less',
	[ EqualCompare ]: 'equal',
	[ LessEqualCompare ]: 'less-equal',
	[ GreaterCompare ]: 'greater',
	[ GreaterEqualCompare ]: 'greater-equal',
	[ AlwaysCompare ]: 'always',
	[ NotEqualCompare ]: 'not-equal'
};

const _flipMap = [ 0, 1, 3, 2, 4, 5 ];

/// A WebGPU backend utility module for managing textures.
///
/// @private
class WebGpuTextureUtils {
  WebGPUBackend backend;
  WebGPUTexturePassUtils? _passUtils;
  Map<String, Texture> defaultTexture = {};
  Map<String, CubeTexture> defaultCubeTexture = {};
  VideoFrame? defaultVideoFrame;
  GpuTexture? colorBuffer;
  DepthTexture depthTexture = DepthTexture();

	/// Constructs a new utility object.
	///
	/// @param {WebGPUBackend} backend - The WebGPU backend.
	WebGpuTextureUtils( this.backend ) {

		/// A reference to the WebGPU backend.
		///
		/// @type {WebGPUBackend}
		this.backend = backend;

		/// A reference to the pass utils.
		///
		/// @type {?WebGpuTexturePassUtils}
		/// @default null
		this._passUtils = null;

		/// A dictionary for managing default textures. The key
		/// is the texture format, the value the texture object.
		///
		/// @type {Object<string,Texture>}
		this.defaultTexture = {};

		/// A dictionary for managing default cube textures. The key
		/// is the texture format, the value the texture object.
		///
		/// @type {Object<string,CubeTexture>}
		this.defaultCubeTexture = {};

		/// A default video frame.
		///
		/// @type {?VideoFrame}
		/// @default null
		this.defaultVideoFrame = null;

		/// Represents the color attachment of the default framebuffer.
		///
		/// @type {?GpuTexture}
		/// @default null
		this.colorBuffer = null;

		/// Represents the depth attachment of the default framebuffer.
		///
		/// @type {DepthTexture}
		this.depthTexture = new DepthTexture();
		this.depthTexture.name = 'depthBuffer';

	}

	/// Creates a GPU sampler for the given texture.
	///
	/// @param {Texture} texture - The texture to create the sampler for.
	void createSampler(Texture texture ) {
		final backend = this.backend;
		final device = backend.device;

		final textureGPU = backend.get( texture );

		final samplerDescriptorGPU = {
			'addressModeU': this._convertAddressMode( texture.wrapS ),
			'addressModeV': this._convertAddressMode( texture.wrapT ),
			'addressModeW': this._convertAddressMode( texture.wrapR ),
			'magFilter': this._convertFilterMode( texture.magFilter ),
			'minFilter': this._convertFilterMode( texture.minFilter ),
			'mipmapFilter': this._convertFilterMode( texture.minFilter ),
			'maxAnisotropy': 1
		};

		// anisotropy can only be used when all filter modes are set to linear.
		if ( samplerDescriptorGPU['magFilter'] == GpuFilterMode.linear && samplerDescriptorGPU['minFilter'] == GpuFilterMode.linear && samplerDescriptorGPU['mipmapFilter'] == GpuFilterMode.linear ) {
			samplerDescriptorGPU['maxAnisotropy'] = texture.anisotropy;
		}

		if ( texture.isDepthTexture && texture.compareFunction != null ) {
			samplerDescriptorGPU['compare'] = _compareToWebGPU[ texture.compareFunction ];
		}

		textureGPU.sampler = device.createSampler( samplerDescriptorGPU );
	}

	/**
	 * Creates a default texture for the given texture that can be used
	 * as a placeholder until the actual texture is ready for usage.
	 *
	 * @param {Texture} texture - The texture to create a default texture for.
	 */
	void createDefaultTexture(Texture texture ) {
		GpuTexture? textureGPU;
		final format = getFormat( texture );

		if ( texture is CubeTexture ) {
			textureGPU = this._getDefaultCubeTextureGPU( format );
		} 
    else {
			textureGPU = this._getDefaultTextureGPU( format );
		}

		this.backend.get( texture ).texture = textureGPU;
	}

	/**
	 * Defines a texture on the GPU for the given texture object.
	 *
	 * @param {Texture} texture - The texture.
	 * @param {Object} [options={}] - Optional configuration parameter.
	 */
	void createTexture(Texture texture, [Map<String,dynamic>? options]) {
    options ??= {};
		final backend = this.backend;
		final textureData = backend.get( texture );

		if ( textureData.initialized ) {
			throw( 'WebGpuTextureUtils: Texture already initialized.' );
		}

		options['needsMipmaps'] ??= false;
		options['levels'] ??= 1;
		options['depth'] ??= 1;

		final width = options['width'];
    final height = options['height'];
    final depth = options['depth'];
    final levels = options['levels'];

		if ( texture is FramebufferTexture ) {
			if ( options['renderTarget'] != null) {
				options['format'] = this.backend.utils.getCurrentColorFormat( options['renderTarget'] );
			} 
      else {
				options['format'] = this.backend.utils.getPreferredCanvasFormat();
			}
		}

		final dimension = this._getDimension( texture );
		final format = texture.internalFormat ?? options['format'] ?? getFormat( texture, backend.device );

		textureData.format = format;
    final gtsd = backend.utils.getTextureSampleData( texture );
		final samples = gtsd.samples;
    final primarySamples = gtsd.primarySamples;
    final isMSAA = gtsd.isMSAA;

		int usage = GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst | GpuTextureUsage.copySrc;

		if ( texture is StorageTexture == true ) {
			usage |= GpuTextureUsage.storageBinding;
		}

		if ( texture is CompressedTexture != true && texture is CompressedArrayTexture != true ) {
			usage |= GpuTextureUsage.renderAttachment;
		}

		final textureDescriptorGPU = {
			'label': texture.name,
			'size': {
				'width': width,
				'height': height,
				'depthOrArrayLayers': depth,
			},
			'mipLevelCount': levels,
			'sampleCount': primarySamples,
			'dimension': dimension,
			'format': format,
			'usage': usage
		};

		// texture creation

		if ( format == null ) {
			console.warning( 'WebGPURenderer: Texture format not supported.' );

			this.createDefaultTexture( texture );
			return;
		}

		if ( texture is CubeTexture ) {
			textureDescriptorGPU['textureBindingViewDimension'] = GpuTextureViewDimension.cube;
		}

		textureData.texture = backend.device.createTexture( textureDescriptorGPU );

		if ( isMSAA ) {
			final msaaTextureDescriptorGPU = Object.assign( {}, textureDescriptorGPU );

			msaaTextureDescriptorGPU.label = msaaTextureDescriptorGPU.label + '-msaa';
			msaaTextureDescriptorGPU.sampleCount = samples;

			textureData.msaaTexture = backend.device.createTexture( msaaTextureDescriptorGPU );
		}

		textureData.initialized = true;
		textureData.textureDescriptorGPU = textureDescriptorGPU;
	}

	/**
	 * Destroys the GPU data for the given texture object.
	 *
	 * @param {Texture} texture - The texture.
	 */
	void destroyTexture(Texture texture, [bool isDefaultTexture = false]) {
		final backend = this.backend;
		final textureData = backend.get( texture );

		if ( textureData.texture != null ) textureData.texture.destroy();
		if ( textureData.msaaTexture != null ) textureData.msaaTexture.destroy();

    backend.remove(texture);
	}

	/**
	 * Destroys the GPU sampler for the given texture.
	 *
	 * @param {Texture} texture - The texture to destroy the sampler for.
	 */
	void destroySampler(Texture texture ) {
		final backend = this.backend;
		final textureData = backend.get( texture );

		textureData?.remove('sampler');
	}

	/**
	 * Generates mipmaps for the given texture.
	 *
	 * @param {Texture} texture - The texture.
	 */
	void generateMipmaps(Texture texture ) {
		final textureData = this.backend.get( texture )!;

		if ( texture is CubeTexture ) {
			for ( int i = 0; i < 6; i ++ ) {
				this._generateMipmaps( textureData['texture'], textureData['textureDescriptorGPU'], baseArrayLayer: i );
			}
		} 
    else {
			final depth = texture.image.depth ?? 1;

			for (int i = 0; i < depth; i ++ ) {
				this._generateMipmaps( textureData['texture'], textureData['textureDescriptorGPU'], baseArrayLayer: i );
			}
		}
	}

	/**
	 * Returns the color buffer representing the color
	 * attachment of the default framebuffer.
	 *
	 * @return {GpuTexture} The color buffer.
	 */
	GpuTexture? getColorBuffer() {
		this.colorBuffer?.destroy();
		final backend = this.backend;
		final width = backend.getDrawingBufferSize().width;
    final height = backend.getDrawingBufferSize().height;

		this.colorBuffer = backend.device.createTexture( {
			'label': 'colorBuffer',
			'size': {
				'width': width,
				'height': height,
				'depthOrArrayLayers': 1
			},
			'sampleCount': backend.utils.getSampleCount( backend.renderer.samples ),
			'format': backend.utils.getPreferredCanvasFormat(),
			'usage': GpuTextureUsage.renderAttachment | GpuTextureUsage.copySrc
		} );

		return this.colorBuffer;
	}

	/**
	 * Returns the depth buffer representing the depth
	 * attachment of the default framebuffer.
	 *
	 * @param {boolean} [depth=true] - Whether depth is enabled or not.
	 * @param {boolean} [stencil=false] -  Whether stencil is enabled or not.
	 * @return {GpuTexture} The depth buffer.
	 */
	GpuTexture getDepthBuffer( [bool depth = true, bool stencil = false] ) {
		final backend = this.backend;
		final width = backend.getDrawingBufferSize().width;
    final height = backend.getDrawingBufferSize().height;

		final depthTexture = this.depthTexture;
		final depthTextureGPU = backend.get( depthTexture ).texture;

		late int format, type;

		if ( stencil ) {
			format = DepthStencilFormat;
			type = UnsignedInt248Type;
		} 
    else if ( depth ) {
			format = DepthFormat;
			type = UnsignedIntType;
		}

		if ( depthTextureGPU != null ) {
			if ( depthTexture.image.width == width && depthTexture.image.height == height && depthTexture.format == format && depthTexture.type == type ) {
				return depthTextureGPU;
			}

			this.destroyTexture( depthTexture );
		}

		depthTexture.name = 'depthBuffer';
		depthTexture.format = format;
		depthTexture.type = type;
		depthTexture.image.width = width;
		depthTexture.image.height = height;

		this.createTexture( depthTexture, {'width': width, 'height': height } );

		return backend.get( depthTexture ).texture;
	}

	/**
	 * Uploads the updated texture data to the GPU.
	 *
	 * @param {Texture} texture - The texture.
	 * @param {Object} [options={}] - Optional configuration parameter.
	 */
	void updateTexture(Texture texture, [Map<String,dynamic>? options] ) {
    options ??= {};
		final textureData = this.backend.get( texture );
		final textureDescriptorGPU = textureData['textureDescriptorGPU'];

		if ( texture.isRenderTargetTexture || ( textureDescriptorGPU == null /* unsupported texture format */ ) )
			return;

		// transfer texture data
		if ( texture is DataTexture ) {
			this._copyBufferToTexture( options['image'], textureData.texture, textureDescriptorGPU, 0, texture.flipY );
		} 
    else if ( texture is ArrayTexture || texture is DataArrayTexture || texture is Data3DTexture ) {
			for ( int i = 0; i < options['image'].depth; i ++ ) {
				this._copyBufferToTexture( options['image'], textureData.texture, textureDescriptorGPU, i, texture.flipY, i );
			}
		} 
    else if ( texture.isCompressedTexture || texture is CompressedArrayTexture ) {
			this._copyCompressedBufferToTexture( texture.mipmaps, textureData.texture, textureDescriptorGPU );
		} 
    else if ( texture is CubeTexture ) {
			this._copyCubeMapToTexture( options['images'], textureData.texture, textureDescriptorGPU, texture.flipY, texture.premultiplyAlpha );
		} 
    else {
			this._copyImageToTexture( options['image'], textureData.texture, textureDescriptorGPU, 0, texture.flipY, texture.premultiplyAlpha );
		}

		//
		textureData.version = texture.version;
		texture.onUpdate?.call( texture );
	}

	///
	/// Returns texture data as a typed array.
	///
	/// @async
	/// @param {Texture} texture - The texture to copy.
	/// @param {number} x - The x coordinate of the copy origin.
	/// @param {number} y - The y coordinate of the copy origin.
	/// @param {number} width - The width of the copy.
	/// @param {number} height - The height of the copy.
	/// @param {number} faceIndex - The face index.
	/// @return {Promise<TypedArray>} A Promise that resolves with a typed array when the copy operation has finished.
	///
	Future<TypedData> copyTextureToBuffer( Texture texture, double x, double y, double width, double height, int faceIndex ) async {
		final device = this.backend.device;
		final textureData = this.backend.get( texture );
		final textureGPU = textureData.texture;
		final format = textureData.textureDescriptorGPU.format;
		final bytesPerTexel = this._getBytesPerTexel( format );

		double bytesPerRow = width * bytesPerTexel;
		bytesPerRow = ( bytesPerRow / 256 ).ceil() * 256; // Align to 256 bytes

		final readBuffer = device.createBuffer(
			{
				'size': width * height * bytesPerTexel,
				'usage': GpuBufferUsage.copyDst | GpuBufferUsage.mapRead
			}
		);

		final encoder = device.createCommandEncoder();

		encoder.copyTextureToBuffer(
			{
				'texture': textureGPU,
				'origin': { 'x': x, 'y': y, 'z': faceIndex },
			},
			{
				'buffer': readBuffer,
				'bytesPerRow': bytesPerRow
			},
			{
				'width': width,
				'height': height
			}
		);

		final typedArrayType = this._getTypedArrayType( format );
		device.queue.submit( [ encoder.finish() ] );

		await readBuffer.mapAsync( GpuMapMode.read );
		final buffer = readBuffer.getMappedRange();
		return new typedArrayType( buffer );
	}

	///
	/// Returns the default GPU texture for the given format.
	///
	/// @private
	/// @param {string} format - The GPU format.
	/// @return {GpuTexture} The GPU texture.
	///
	GpuTexture _getDefaultTextureGPU( String format ) {

		Texture? defaultTexture = this.defaultTexture[ format ];

		if ( defaultTexture == null ) {

			final texture = Texture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture( texture, { width: 1, height: 1, format } );

			this.defaultTexture[ format ] = defaultTexture = texture;

		}

		return this.backend.get( defaultTexture ).texture;

	}

	///
	/// Returns the default GPU cube texture for the given format.
	///
	/// @private
	/// @param {string} format - The GPU format.
	/// @return {GpuTexture} The GPU texture.
	///
	GpuTexture _getDefaultCubeTextureGPU( GpuTextureFormat? format ) {
		Texture? defaultCubeTexture = this.defaultTexture[ format ];

		if ( defaultCubeTexture == null ) {
			final texture = CubeTexture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture( texture, { 'width': 1, 'height': 1, 'depth': 6 } );
			this.defaultCubeTexture[ format ] = defaultCubeTexture = texture;
		}

		return this.backend.get( defaultCubeTexture ).texture;
	}

	///
	/// Uploads cube texture image data to the GPU memory.
	///
	/// @private
	/// @param {Array} images - The cube image data.
	/// @param {GpuTexture} textureGPU - The GPU texture.
	/// @param {Object} textureDescriptorGPU - The GPU texture descriptor.
	/// @param {boolean} flipY - Whether to flip texture data along their vertical axis or not.
	/// @param {boolean} premultiplyAlpha - Whether the texture should have its RGB channels premultiplied by the alpha channel or not.
	///
	void _copyCubeMapToTexture( List images, GpuTexture textureGPU, Object textureDescriptorGPU, bool flipY, bool premultiplyAlpha ) {
		for ( int i = 0; i < 6; i ++ ) {
			final image = images[ i ];
			final flipIndex = flipY == true ? _flipMap[ i ] : i;

			if ( image.isDataTexture ) {
				this._copyBufferToTexture( image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY );
			} 
      else {
				this._copyImageToTexture( image, textureGPU, textureDescriptorGPU, flipIndex, flipY, premultiplyAlpha );
			}
		}
	}

	///
	/// Uploads texture image data to the GPU memory.
	///
	/// @private
	/// @param {HTMLImageElement|ImageBitmap|HTMLCanvasElement} image - The image data.
	/// @param {GpuTexture} textureGPU - The GPU texture.
	/// @param {Object} textureDescriptorGPU - The GPU texture descriptor.
	/// @param {number} originDepth - The origin depth.
	/// @param {boolean} flipY - Whether to flip texture data along their vertical axis or not.
	/// @param {boolean} premultiplyAlpha - Whether the texture should have its RGB channels premultiplied by the alpha channel or not.
	///
	void _copyImageToTexture( image, GpuTexture textureGPU, Object textureDescriptorGPU, int originDepth, bool flipY, bool premultiplyAlpha ) {
		final device = this.backend.device;

		device.queue.copyExternalImageToTexture(
			{
				'source': image,
				'flipY': flipY
			}, {
				'texture': textureGPU,
				'mipLevel': 0,
				'origin': { 'x': 0, 'y': 0, 'z': originDepth },
				'premultipliedAlpha': premultiplyAlpha
			}, {
				'width': textureDescriptorGPU.size.width,
				'height': textureDescriptorGPU.size.height,
				'depthOrArrayLayers': 1
			}
		);

	}

	///
	/// Returns the pass utils singleton.
	///
	/// @private
	/// @return {WebGpuTexturePassUtils} The utils instance.
	///
	WebGpuTexturePassUtils _getPassUtils() {
		WebGpuTexturePassUtils? passUtils = this._passUtils;

		if ( passUtils == null ) {
			this._passUtils = passUtils = WebGpuTexturePassUtils( this.backend.device );
		}

		return passUtils;
	}

	///
	/// Generates mipmaps for the given GPU texture.
	///
	/// @private
	/// @param {GpuTexture} textureGPU - The GPU texture object.
	/// @param {Object} textureDescriptorGPU - The texture descriptor.
	/// @param {number} [baseArrayLayer=0] - The index of the first array layer accessible to the texture view.
	///
	void _generateMipmaps( GpuTexture textureGPU, Object textureDescriptorGPU, { int baseArrayLayer = 0 } ) {

		this._getPassUtils().generateMipmaps( textureGPU, textureDescriptorGPU, baseArrayLayer );

	}

	///
	/// Flip the contents of the given GPU texture along its vertical axis.
	///
	/// @private
	/// @param {GpuTexture} textureGPU - The GPU texture object.
	/// @param {Object} textureDescriptorGPU - The texture descriptor.
	/// @param {number} [originDepth=0] - The origin depth.
	///
	void _flipY( GpuTexture textureGPU, Object textureDescriptorGPU, { int originDepth = 0 } ) {

		this._getPassUtils().flipY( textureGPU, textureDescriptorGPU, originDepth );

	}

	///
	/// Uploads texture buffer data to the GPU memory.
	///
	/// @private
	/// @param {Object} image - An object defining the image buffer data.
	/// @param {GpuTexture} textureGPU - The GPU texture.
	/// @param {Object} textureDescriptorGPU - The GPU texture descriptor.
	/// @param {number} originDepth - The origin depth.
	/// @param {boolean} flipY - Whether to flip texture data along their vertical axis or not.
	/// @param {number} [depth=0] - TODO.
	///
	void _copyBufferToTexture(Map image, GpuTexture textureGPU, Object textureDescriptorGPU, int originDepth, bool flipY, { int depth = 0 } ) {

		// @TODO: Consider to use GPUCommandEncoder.copyBufferToTexture()
		// @TODO: Consider to support valid buffer layouts with other formats like RGB

		final device = this.backend.device;

		final data = image.data;

		final bytesPerTexel = this._getBytesPerTexel( textureDescriptorGPU.format );
		final bytesPerRow = image.width * bytesPerTexel;

		device.queue.writeTexture(
			{
				'texture': textureGPU,
				'mipLevel': 0,
				'origin': { 'x': 0, 'y': 0, 'z': originDepth }
			},
			data,
			{
				'offset': image.width * image.height * bytesPerTexel * depth,
				'bytesPerRow': bytesPerRow
			},
			{
				'width': image.width,
				'height': image.height,
				'depthOrArrayLayers': 1
			} );

		if ( flipY == true ) {

			this._flipY( textureGPU, textureDescriptorGPU, originDepth );

		}

	}

	///
	/// Uploads compressed texture data to the GPU memory.
	///
	/// @private
	/// @param {Array<Object>} mipmaps - An array with mipmap data.
	/// @param {GpuTexture} textureGPU - The GPU texture.
	/// @param {Object} textureDescriptorGPU - The GPU texture descriptor.
	///
	void _copyCompressedBufferToTexture( List<Object> mipmaps, GpuTexture textureGPU, Object textureDescriptorGPU ) {
		// @TODO: Consider to use GPUCommandEncoder.copyBufferToTexture()
		final device = this.backend.device;

		final blockData = this._getBlockData( textureDescriptorGPU.format );
		final isArrayTexture = textureDescriptorGPU.size.depthOrArrayLayers > 1;

		for ( int i = 0; i < mipmaps.length; i ++ ) {
			final mipmap = mipmaps[ i ];

			final width = mipmap.width;
			final height = mipmap.height;
			final depth = isArrayTexture ? textureDescriptorGPU.size.depthOrArrayLayers : 1;

			final bytesPerRow = ( width / blockData.width ).ceil() * blockData.byteLength;
			final bytesPerImage = bytesPerRow * ( height / blockData.height ).ceil();

			for ( int j = 0; j < depth; j ++ ) {
				device.queue.writeTexture(
					{
						'texture': textureGPU,
						'mipLevel': i,
						'origin': { 'x': 0, 'y': 0, 'z': j }
					},
					mipmap.data,
					{
						'offset': j * bytesPerImage,
						'bytesPerRow': bytesPerRow,
						'rowsPerImage': ( height / blockData.height ).ceil()
					},
					{
						'width': ( width / blockData.width ).ceil() * blockData.width,
						'height': ( height / blockData.height ).ceil() * blockData.height,
						'depthOrArrayLayers': 1
					}
				);
			}
		}
	}

	///
	/// This method is only relevant for compressed texture formats. It returns a block
	/// data descriptor for the given GPU compressed texture format.
	///
	/// @private
	/// @param {string} format - The GPU compressed texture format.
	/// @return {Object} The block data descriptor.
	///
  Map<String, int>? _getBlockData(GpuTextureFormat format) {
    // DXT1
    if (format == GpuTextureFormat.bc1RgbaUnorm || format == GpuTextureFormat.bc1RgbaUnormSrgb) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    // DXT3
    if (format == GpuTextureFormat.bc2RgbaUnorm || format == GpuTextureFormat.bc2RgbaUnormSrgb) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    // DXT5
    if (format == GpuTextureFormat.bc3RgbaUnorm || format == GpuTextureFormat.bc3RgbaUnormSrgb) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    // RGTC1
    if (format == GpuTextureFormat.bc4RUnorm || format == GpuTextureFormat.bc4RSnorm) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    // RGTC2
    if (format == GpuTextureFormat.bc5RgUnorm || format == GpuTextureFormat.bc5RgSnorm) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    // BPTC (float)
    if (format == GpuTextureFormat.bc6hRgbUFloat || format == GpuTextureFormat.bc6hRgbFloat) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    // BPTC (unorm)
    if (format == GpuTextureFormat.bc7RgbaUnorm || format == GpuTextureFormat.bc7RgbaUnormSrgb) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    
    // ETC2
    if (format == GpuTextureFormat.etc2Rgb8Unorm || format == GpuTextureFormat.etc2Rgb8UnormSrgb) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.etc2Rgb8a1Unorm || format == GpuTextureFormat.etc2Rgb8a1UnormSrgb) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.etc2Rgba8Unorm || format == GpuTextureFormat.etc2Rgba8UnormSrgb) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    
    // EAC
    if (format == GpuTextureFormat.eacR11Unorm) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.eacR11Snorm) {
      return {'byteLength': 8, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.eacRg11Unorm) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.eacRg11Snorm) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    
    // ASTC
    if (format == GpuTextureFormat.astc4x4Unorm || format == GpuTextureFormat.astc4x4UnormSrgb) {
      return {'byteLength': 16, 'width': 4, 'height': 4};
    }
    if (format == GpuTextureFormat.astc5x4Unorm || format == GpuTextureFormat.astc5x4UnormSrgb) {
      return {'byteLength': 16, 'width': 5, 'height': 4};
    }
    if (format == GpuTextureFormat.astc5x5Unorm || format == GpuTextureFormat.astc5x5UnormSrgb) {
      return {'byteLength': 16, 'width': 5, 'height': 5};
    }
    if (format == GpuTextureFormat.astc6x5Unorm || format == GpuTextureFormat.astc6x5UnormSrgb) {
      return {'byteLength': 16, 'width': 6, 'height': 5};
    }
    if (format == GpuTextureFormat.astc6x6Unorm || format == GpuTextureFormat.astc6x6UnormSrgb) {
      return {'byteLength': 16, 'width': 6, 'height': 6};
    }
    if (format == GpuTextureFormat.astc8x5Unorm || format == GpuTextureFormat.astc8x5UnormSrgb) {
      return {'byteLength': 16, 'width': 8, 'height': 5};
    }
    if (format == GpuTextureFormat.astc8x6Unorm || format == GpuTextureFormat.astc8x6UnormSrgb) {
      return {'byteLength': 16, 'width': 8, 'height': 6};
    }
    if (format == GpuTextureFormat.astc8x8Unorm || format == GpuTextureFormat.astc8x8UnormSrgb) {
      return {'byteLength': 16, 'width': 8, 'height': 8};
    }
    if (format == GpuTextureFormat.astc10x5Unorm || format == GpuTextureFormat.astc10x5UnormSrgb) {
      return {'byteLength': 16, 'width': 10, 'height': 5};
    }
    if (format == GpuTextureFormat.astc10x6Unorm || format == GpuTextureFormat.astc10x6UnormSrgb) {
      return {'byteLength': 16, 'width': 10, 'height': 6};
    }
    if (format == GpuTextureFormat.astc10x8Unorm || format == GpuTextureFormat.astc10x8UnormSrgb) {
      return {'byteLength': 16, 'width': 10, 'height': 8};
    }
    if (format == GpuTextureFormat.astc10x10Unorm || format == GpuTextureFormat.astc10x10UnormSrgb) {
      return {'byteLength': 16, 'width': 10, 'height': 10};
    }
    if (format == GpuTextureFormat.astc12x10Unorm || format == GpuTextureFormat.astc12x10UnormSrgb) {
      return {'byteLength': 16, 'width': 12, 'height': 10};
    }
    if (format == GpuTextureFormat.astc12x12Unorm || format == GpuTextureFormat.astc12x12UnormSrgb) {
      return {'byteLength': 16, 'width': 12, 'height': 12};
    }

    // Fallback return match signature contract
    console.error('WebGPURenderer: Format is not a compressed block texture format layout. $format');
    return null;
  }


	///
	/// Converts the three.js uv wrapping constants to GPU address mode constants.
	///
	/// @private
	/// @param {number} value - The three.js constant defining a uv wrapping mode.
	/// @return {string} The GPU address mode.
	///
	GpuAddressMode _convertAddressMode( int value ) {
		GpuAddressMode addressMode = GpuAddressMode.clampToEdge;

		if ( value == RepeatWrapping ) {
			addressMode = GpuAddressMode.repeat;
		} 
    else if ( value == MirroredRepeatWrapping ) {
			addressMode = GpuAddressMode.mirrorRepeat;
		}

		return addressMode;
	}

	///
	/// Converts the three.js filter constants to GPU filter constants.
	///
	/// @private
	/// @param {number} value - The three.js constant defining a filter mode.
	/// @return {string} The GPU filter mode.
	///
	GpuFilterMode _convertFilterMode( int value ) {
		GpuFilterMode filterMode = GpuFilterMode.linear;

		if ( value == NearestFilter || value == NearestMipmapNearestFilter || value == NearestMipmapLinearFilter ) {
			filterMode = GpuFilterMode.nearest;
		}

		return filterMode;
	}

	///
	/// Returns the bytes-per-texel value for the given GPU texture format.
	///
	/// @private
	/// @param {string} format - The GPU texture format.
	/// @return {number} The bytes-per-texel.
	///
  int _getBytesPerTexel(GpuTextureFormat format) {
    // 8-bit formats
    if (format == GpuTextureFormat.r8Unorm ||
        format == GpuTextureFormat.r8Snorm ||
        format == GpuTextureFormat.r8Uint ||
        format == GpuTextureFormat.r8Sint) {
      return 1;
    }

    // 16-bit formats
    if (format == GpuTextureFormat.r16Uint ||
        format == GpuTextureFormat.r16Sint ||
        format == GpuTextureFormat.r16Float ||
        format == GpuTextureFormat.rg8Unorm ||
        format == GpuTextureFormat.rg8Snorm ||
        format == GpuTextureFormat.rg8Uint ||
        format == GpuTextureFormat.rg8Sint) {
      return 2;
    }

    // 32-bit formats
    if (format == GpuTextureFormat.r32Uint ||
        format == GpuTextureFormat.r32Sint ||
        format == GpuTextureFormat.r32Float ||
        format == GpuTextureFormat.rg16Uint ||
        format == GpuTextureFormat.rg16Sint ||
        format == GpuTextureFormat.rg16Float ||
        format == GpuTextureFormat.rgba8Unorm ||
        format == GpuTextureFormat.rgba8UnormSrgb ||
        format == GpuTextureFormat.rgba8Snorm ||
        format == GpuTextureFormat.rgba8Uint ||
        format == GpuTextureFormat.rgba8Sint ||
        format == GpuTextureFormat.bgra8Unorm ||
        format == GpuTextureFormat.bgra8UnormSrgb ||
        // Packed 32-bit formats
        format == GpuTextureFormat.rgb9e5UFloat ||
        format == GpuTextureFormat.rgb10a2Unorm ||
        format == GpuTextureFormat.rg11b10UFloat ||
        format == GpuTextureFormat.depth32Float ||
        format == GpuTextureFormat.depth24Plus ||
        format == GpuTextureFormat.depth24PlusStencil8 ||
        format == GpuTextureFormat.depth32FloatStencil8) {
      return 4;
    }

    // 64-bit formats
    if (format == GpuTextureFormat.rg32Uint ||
        format == GpuTextureFormat.rg32Sint ||
        format == GpuTextureFormat.rg32Float ||
        format == GpuTextureFormat.rgba16Uint ||
        format == GpuTextureFormat.rgba16Sint ||
        format == GpuTextureFormat.rgba16Float) {
      return 8;
    }

    // 128-bit formats
    if (format == GpuTextureFormat.rgba32Uint ||
        format == GpuTextureFormat.rgba32Sint ||
        format == GpuTextureFormat.rgba32Float) {
      return 16;
    }

    // Fallback signature mapping to satisfy the compiler
    console.error('WebGPURenderer: Unsupported texel format layout context. $format');
    return 0;
  }


	///
	/// Returns the corresponding typed array type for the given GPU texture format.
	///
	/// @private
	/// @param {string} format - The GPU texture format.
	/// @return {TypedArray.constructor} The typed array type.
	///
  Type _getTypedArrayType(GpuTextureFormat format) {
    if (format == GpuTextureFormat.r8Uint) return Uint8List;
    if (format == GpuTextureFormat.r8Sint) return Int8List;
    if (format == GpuTextureFormat.r8Unorm) return Uint8List;
    if (format == GpuTextureFormat.rgba8Snorm) return Int8List; // Kept your format case flags
    
    if (format == GpuTextureFormat.rg8Uint) return Uint8List;
    if (format == GpuTextureFormat.rg8Sint) return Int8List;
    if (format == GpuTextureFormat.rg8Unorm) return Uint8List;
    if (format == GpuTextureFormat.rg8Snorm) return Int8List;
    
    if (format == GpuTextureFormat.rgba8Uint) return Uint8List;
    if (format == GpuTextureFormat.rgba8Sint) return Int8List;
    if (format == GpuTextureFormat.rgba8Unorm) return Uint8List;
    if (format == GpuTextureFormat.rgba8Snorm) return Int8List;
    
    if (format == GpuTextureFormat.r16Uint) return Uint16List;
    if (format == GpuTextureFormat.r16Sint) return Int16List;
    if (format == GpuTextureFormat.rg16Uint) return Uint16List;
    if (format == GpuTextureFormat.rg16Sint) return Int16List;
    if (format == GpuTextureFormat.rgba16Uint) return Uint16List;
    if (format == GpuTextureFormat.rgba16Sint) return Int16List;
    
    if (format == GpuTextureFormat.r16Float) return Uint16List;
    if (format == GpuTextureFormat.rg16Float) return Uint16List;
    if (format == GpuTextureFormat.rgba16Float) return Uint16List;
    
    if (format == GpuTextureFormat.r32Uint) return Uint32List;
    if (format == GpuTextureFormat.r32Sint) return Int32List;
    if (format == GpuTextureFormat.r32Float) return Float32List;
    
    if (format == GpuTextureFormat.rg32Uint) return Uint32List;
    if (format == GpuTextureFormat.rg32Sint) return Int32List;
    if (format == GpuTextureFormat.rg32Float) return Float32List;
    
    if (format == GpuTextureFormat.rgba32Uint) return Uint32List;
    if (format == GpuTextureFormat.rgba32Sint) return Int32List;
    if (format == GpuTextureFormat.rgba32Float) return Float32List;
    
    if (format == GpuTextureFormat.bgra8Unorm) return Uint8List;
    if (format == GpuTextureFormat.bgra8UnormSrgb) return Uint8List;
    
    if (format == GpuTextureFormat.rgb10a2Unorm) return Uint32List;
    if (format == GpuTextureFormat.rgb9e5UFloat) return Uint32List; // Verified case match
    if (format == GpuTextureFormat.rg11b10UFloat) return Uint32List;
    
    if (format == GpuTextureFormat.depth32Float) return Float32List;
    if (format == GpuTextureFormat.depth24Plus) return Uint32List;
    if (format == GpuTextureFormat.depth24PlusStencil8) return Uint32List;
    if (format == GpuTextureFormat.depth32FloatStencil8) return Float32List;

    // Fallback pattern to keep Dart's compiler happy
    console.error('WebGPURenderer: Unknown type format for typed array helper. $format');
    return Uint8List; 
  }


  /**
   * Returns the GPU dimensions for the given texture.
   *
   * @private
   * @param {Texture} texture - The texture.
   * @return {string} The GPU dimension.
   */
  GpuTextureDimension _getDimension(Texture texture ) {
    GpuTextureDimension dimension;

    if ( texture is 3DTexture || texture is Data3DTexture ) {
      dimension = GpuTextureDimension.d3;
    } 
    else {
      dimension = GpuTextureDimension.d2;
    }
    return dimension;
  }
}

///
/// Returns the GPU format for the given texture.
///
/// @param {Texture} texture - The texture.
/// @param {?GPUDevice} [device=null] - The GPU device which is used for feature detection.
/// It is not necessary to apply the device for most formats.
/// @return {string} The GPU format.
///
GpuTextureFormat? getFormat(Texture texture, {GpuDevice? device}) {
  final format = texture.format;
  final type = texture.type;
  final colorSpace = texture.colorSpace;
  final transfer = ColorManagement.getTransfer(colorSpace);
  GpuTextureFormat? formatGPU;

  if (texture.isCompressedTexture == true || texture is CompressedArrayTexture) {
    switch (format) {
      case RGBA_S3TC_DXT1_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.bc1RgbaUnormSrgb : GpuTextureFormat.bc1RgbaUnorm;
        break;
      case RGBA_S3TC_DXT3_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.bc2RgbaUnormSrgb : GpuTextureFormat.bc2RgbaUnorm;
        break;
      case RGBA_S3TC_DXT5_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.bc3RgbaUnormSrgb : GpuTextureFormat.bc3RgbaUnorm;
        break;
      case RGB_ETC2_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.etc2Rgb8UnormSrgb : GpuTextureFormat.etc2Rgb8Unorm;
        break;
      case RGBA_ETC2_EAC_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.etc2Rgba8UnormSrgb : GpuTextureFormat.etc2Rgba8Unorm;
        break;
      case RGBA_ASTC_4x4_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc4x4UnormSrgb : GpuTextureFormat.astc4x4Unorm;
        break;
      case RGBA_ASTC_5x4_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc5x4UnormSrgb : GpuTextureFormat.astc5x4Unorm;
        break;
      case RGBA_ASTC_5x5_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc5x5UnormSrgb : GpuTextureFormat.astc5x5Unorm;
        break;
      case RGBA_ASTC_6x5_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc6x5UnormSrgb : GpuTextureFormat.astc6x5Unorm;
        break;
      case RGBA_ASTC_6x6_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc6x6UnormSrgb : GpuTextureFormat.astc6x6Unorm;
        break;
      case RGBA_ASTC_8x5_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc8x5UnormSrgb : GpuTextureFormat.astc8x5Unorm;
        break;
      case RGBA_ASTC_8x6_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc8x6UnormSrgb : GpuTextureFormat.astc8x6Unorm;
        break;
      case RGBA_ASTC_8x8_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc8x8UnormSrgb : GpuTextureFormat.astc8x8Unorm;
        break;
      case RGBA_ASTC_10x5_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc10x5UnormSrgb : GpuTextureFormat.astc10x5Unorm;
        break;
      case RGBA_ASTC_10x6_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc10x6UnormSrgb : GpuTextureFormat.astc10x6Unorm;
        break;
      case RGBA_ASTC_10x8_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc10x8UnormSrgb : GpuTextureFormat.astc10x8Unorm;
        break;
      case RGBA_ASTC_10x10_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc10x10UnormSrgb : GpuTextureFormat.astc10x10Unorm;
        break;
      case RGBA_ASTC_12x10_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc12x10UnormSrgb : GpuTextureFormat.astc12x10Unorm;
        break;
      case RGBA_ASTC_12x12_Format:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.astc12x12UnormSrgb : GpuTextureFormat.astc12x12Unorm;
        break;
      case RGBAFormat:
        formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.rgba8UnormSrgb : GpuTextureFormat.rgba8Unorm;
        break;
      default:
        console.error('WebGPURenderer: Unsupported texture format. $format');
    }
  } else {
    switch (format) {
      case RGBAFormat:
        switch (type) {
          case ByteType:
            formatGPU = GpuTextureFormat.rgba8Snorm;
            break;
          case ShortType:
            formatGPU = GpuTextureFormat.rgba16Sint;
            break;
          case UnsignedShortType:
            formatGPU = GpuTextureFormat.rgba16Uint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.rgba32Uint;
            break;
          case IntType:
            formatGPU = GpuTextureFormat.rgba32Sint;
            break;
          case UnsignedByteType:
            formatGPU = (transfer == SRGBTransfer) ? GpuTextureFormat.rgba8UnormSrgb : GpuTextureFormat.rgba8Unorm;
            break;
          case HalfFloatType:
            formatGPU = GpuTextureFormat.rgba16Float;
            break;
          case FloatType:
            formatGPU = GpuTextureFormat.rgba32Float;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RGBAFormat. $type');
        }
        break;
      case RGBFormat:
        switch (type) {
          case UnsignedInt5999Type:
            formatGPU = GpuTextureFormat.rgb9e5UFloat;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RGBFormat. $type');
        }
        break;
      case RedFormat:
        switch (type) {
          case ByteType:
            formatGPU = GpuTextureFormat.r8Snorm;
            break;
          case ShortType:
            formatGPU = GpuTextureFormat.r16Sint;
            break;
          case UnsignedShortType:
            formatGPU = GpuTextureFormat.r16Uint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.r32Uint;
            break;
          case IntType:
            formatGPU = GpuTextureFormat.r32Sint;
            break;
          case UnsignedByteType:
            formatGPU = GpuTextureFormat.r8Unorm;
            break;
          case HalfFloatType:
            formatGPU = GpuTextureFormat.r16Float;
            break;
          case FloatType:
            formatGPU = GpuTextureFormat.r32Float;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RedFormat. $type');
        }
        break;
      case RGFormat:
        switch (type) {
          case ByteType:
            formatGPU = GpuTextureFormat.rg8Snorm;
            break;
          case ShortType:
            formatGPU = GpuTextureFormat.rg16Sint;
            break;
          case UnsignedShortType:
            formatGPU = GpuTextureFormat.rg16Uint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.rg32Uint;
            break;
          case IntType:
            formatGPU = GpuTextureFormat.rg32Sint;
            break;
          case UnsignedByteType:
            formatGPU = GpuTextureFormat.rg8Unorm;
            break;
          case HalfFloatType:
            formatGPU = GpuTextureFormat.rg16Float;
            break;
          case FloatType:
            formatGPU = GpuTextureFormat.rg32Float;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RGFormat. $type');
        }
        break;
      case DepthFormat:
        switch (type) {
          case UnsignedShortType:
            formatGPU = GpuTextureFormat.depth16Unorm;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.depth24Plus;
            break;
          case FloatType:
            formatGPU = GpuTextureFormat.depth32Float;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with DepthFormat. $type');
        }
        break;
      case DepthStencilFormat:
        switch (type) {
          case UnsignedInt248Type:
            formatGPU = GpuTextureFormat.depth24PlusStencil8;
            break;
          case FloatType:
            if (device != null && device.features.contains(GpuFeatureName.depth32FloatStencil8) == false) {
              console.error('WebGPURenderer: Depth textures with DepthStencilFormat + FloatType can only be used with the "depth32float-stencil8" GPU feature.');
            }
            formatGPU = GpuTextureFormat.depth32FloatStencil8;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with DepthStencilFormat. $type');
        }
        break;
      case RedIntegerFormat:
        switch (type) {
          case IntType:
            formatGPU = GpuTextureFormat.r32Sint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.r32Uint;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RedIntegerFormat. $type');
        }
        break;
      case RGIntegerFormat:
        switch (type) {
          case IntType:
            formatGPU = GpuTextureFormat.rg32Sint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.rg32Uint;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RGIntegerFormat. $type');
        }
        break;
      case RGBAIntegerFormat:
        switch (type) {
          case IntType:
            formatGPU = GpuTextureFormat.rgba32Sint;
            break;
          case UnsignedIntType:
            formatGPU = GpuTextureFormat.rgba32Uint;
            break;
          default:
            console.error('WebGPURenderer: Unsupported texture type with RGBAIntegerFormat. $type');
        }
        break;
      default:
        console.error('WebGPURenderer: Unsupported texture format. $format');
    }
  }
  return formatGPU;
}
