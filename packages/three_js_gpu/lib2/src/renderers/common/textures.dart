import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'backend.dart';
import 'data_map.dart';
import 'info.dart';
import 'storage_texture.dart';
import 'package:three_js_math/three_js_math.dart';

final _size = Vector3.fromJson();

class Textures extends DataMap {
  Renderer renderer; 
  Backend backend; 
  Info info;

	Textures(this.renderer, this.backend, this.info ):super();

	/// Updates the given render target. Based on the given render target configuration,
	/// it updates the texture states representing the attachments of the framebuffer.
	void updateRenderTarget(RenderTarget renderTarget, [int activeMipmapLevel = 0 ]) {

		final renderTargetData = get( renderTarget );

		final sampleCount = renderTarget.samples == 0 ? 1 : renderTarget.samples;
		final depthTextureMips = renderTargetData.depthTextureMips ?? ( renderTargetData.depthTextureMips = {} );

		final textures = renderTarget.textures;

		final size = getSize( textures[ 0 ] );

		final mipWidth = size.x.toInt() >> activeMipmapLevel;
		final mipHeight = size.y.toInt() >> activeMipmapLevel;

		DepthTexture? depthTexture = renderTarget.depthTexture ?? depthTextureMips[ activeMipmapLevel ];
		final useDepthTexture = renderTarget.depthBuffer == true || renderTarget.stencilBuffer == true;

		var textureNeedsUpdate = false;

		if ( depthTexture == null && useDepthTexture ) {
			depthTexture = DepthTexture(mipWidth,mipHeight);

			depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
			depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType; // FloatType
			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;
			depthTexture.image.depth = size.z;
			depthTexture is ArrayTexture = renderTarget.multiview == true && size.z > 1;

			depthTextureMips[ activeMipmapLevel ] = depthTexture;
		}

		if ( renderTargetData.width != size.x || size.y != renderTargetData.height ) {
			textureNeedsUpdate = true;

			if ( depthTexture != null) {
				depthTexture.needsUpdate = true;
				depthTexture.image.width = mipWidth;
				depthTexture.image.height = mipHeight;
				depthTexture.image.depth = depthTexture is ArrayTexture ? depthTexture.image.depth : 1;
			}
		}

		renderTargetData.width = size.x;
		renderTargetData.height = size.y;
		renderTargetData.textures = textures;
		renderTargetData.depthTexture = depthTexture ?? null;
		renderTargetData.depth = renderTarget.depthBuffer;
		renderTargetData.stencil = renderTarget.stencilBuffer;
		renderTargetData.renderTarget = renderTarget;

		if ( renderTargetData.sampleCount != sampleCount ) {
			textureNeedsUpdate = true;

			if ( depthTexture != null) {
				depthTexture.needsUpdate = true;
			}
			renderTargetData.sampleCount = sampleCount;
		}

		//

		final options = { 'sampleCount': sampleCount };

		// XR render targets require no texture updates

		if ( renderTarget.isXRRenderTarget != true ) {
			for ( var i = 0; i < textures.length; i ++ ) {
				final texture = textures[ i ];
				if ( textureNeedsUpdate ) texture.needsUpdate = true;
				updateTexture( texture, options );
			}

			if ( depthTexture != null) {
				updateTexture( depthTexture, options );
			}
		}

		// dispose handler

		if ( renderTargetData.initialized != true ) {
			renderTargetData.initialized = true;

			// dispose

		  onDispose(){
				renderTarget.removeEventListener( 'dispose', onDispose );

				for ( var i = 0; i < textures.length; i ++ ) {
					_destroyTexture( textures[ i ] );
				}

				if ( depthTexture != null) {
					_destroyTexture( depthTexture );
				}

				delete( renderTarget );
			}

			renderTarget.addEventListener( 'dispose', onDispose );

		}
	}

	/// Updates the given texture. Depending on the texture state, this method
	/// triggers the upload of texture data to the GPU memory. If the texture data are
	/// not yet ready for the upload, it uses default texture data for as a placeholder.
	void updateTexture(Texture texture, [Map<String,dynamic>? options]) {
    options ??= {};

		final textureData = get( texture );
		if ( textureData.initialized == true && textureData.version == texture.version ) return;

		final isRenderTarget = texture.isRenderTargetTexture || texture.isDepthTexture || texture is FramebufferTexture;
		final backend = this.backend;

		if ( isRenderTarget && textureData.initialized == true ) {
			backend.destroySampler( texture );
			backend.destroyTexture( texture );
		}

		//

		if ( texture is FramebufferTexture ) {
			final renderTarget = renderer.getRenderTarget();

			if ( renderTarget != null) {
				texture.type = renderTarget.texture.type;
			} 
      else {
				texture.type = UnsignedByteType;
			}
		}

		//

		final width = getSize( texture ).x;
    final height = getSize( texture ).y;
    final depth = getSize( texture ).z;

		options['width'] = width;
		options['height'] = height;
		options['depth'] = depth;
		options['needsMipmaps'] = needsMipmaps( texture );
		options['levels'] = options['needsMipmaps'] == true? getMipLevels( texture, width, height ) : 1;

		if ( isRenderTarget || texture is StorageTexture) {
			backend.createSampler( texture );
			backend.createTexture( texture, options);

			textureData.generation = texture.version;
		} 
    else {
			final needsCreate = textureData.initialized != true;

			if ( needsCreate ) backend.createSampler( texture );
			if ( texture.version > 0 ) {

				final image = texture.image;

				if ( image == null ) {
					console.warning( 'THREE.Renderer: Texture marked for update but image is null.' );
				} else if ( image.complete == false ) {
					console.warning( 'THREE.Renderer: Texture marked for update but image is incomplete.' );
				} else {

					if ( texture.images ) {
						final images = [];

						for ( final image in texture.images ) {
							images.add( image );
						}

						options['images'] = images;
					} else {
						options['image'] = image;
					}

					if ( textureData.isDefaultTexture == null || textureData.isDefaultTexture == true ) {

						backend.createTexture( texture, options );

						textureData.isDefaultTexture = false;
						textureData.generation = texture.version;

					}

					if ( texture.source.dataReady == true ) backend.updateTexture( texture, options );
					if ( options['needsMipmaps'] && texture.mipmaps.isEmpty) backend.generateMipmaps( texture );
				}
			} else {
				backend.createDefaultTexture( texture );
				textureData.isDefaultTexture = true;
				textureData.generation = texture.version;
			}
		}

		// dispose handler

		if ( textureData.initialized != true ) {
			textureData.initialized = true;
			textureData.generation = texture.version;

			//
			info.memory['textures'] = info.memory['textures']! + 1;

			// dispose
			onDispose(){
				texture.removeEventListener( 'dispose', onDispose );
				_destroyTexture( texture );
			}

			texture.addEventListener( 'dispose', onDispose );
		}

		textureData.version = texture.version;
	}

	/// Computes the size of the given texture and writes the result
	/// into the target vector. This vector is also returned by the
	/// method.
	///
	/// If no texture data are available for the compute yet, the method
	/// returns default size values.
	Vector3 getSize(Texture texture, [Vector3? target]) {
    target ??= _size;
		var image = texture.images ? texture.images[ 0 ] : texture.image;

		if ( image ) {
			if ( image.image != null ) image = image.image;
			if ( image is VideoFrame ) {
				target.width = image.displayWidth ?? 1;
				target.height = image.displayHeight ?? 1;
				target.depth = 1;
			} 
      else {
				target.width = image.width ?? 1;
				target.height = image.height ?? 1;
				target.depth = texture.isCubeTexture ? 6 : ( image.depth ?? 1 );
			}
		} 
    else {
			target.width = target.height = target.depth = 1;
		}

		return target;
	}

	/// Computes the number of mipmap levels for the given texture.
	int getMipLevels(Texture texture, double width, double height ) {
		var mipLevelCount;

		if ( texture.isCompressedTexture ) {
			if ( texture.mipmaps != null) {
				mipLevelCount = texture.mipmaps.length;
			} 
      else {
				mipLevelCount = 1;
			}

		} else {
			mipLevelCount = ( MathUtils.log2( math.max( width, height ) ) ).floor() + 1;
		}

		return mipLevelCount;
	}

	bool needsMipmaps(Texture texture ) {
		return texture is CompressedTexture || texture.generateMipmaps;
	}

	void _destroyTexture(Texture texture ) {
		if ( has( texture ) == true ) {
			backend.destroySampler( texture );
			backend.destroyTexture( texture );

			delete( texture );

			info.memory['textures'] = info.memory['textures']!-1;
		}
	}
}
