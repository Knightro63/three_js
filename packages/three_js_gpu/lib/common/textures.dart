import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/backend.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/info.dart';
import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_gpu/common/storage_texture.dart';
import 'package:three_js_math/three_js_math.dart';

final _size = /*@__PURE__*/ Vector3.fromJson();

/**
 * This module manages the textures of the renderer.
 *
 * @private
 * @augments DataMap
 */
class Textures extends DataMap {
  Renderer renderer; 
  Backend backend; 
  Info info;

	Textures(this.renderer, this.backend, this.info ):super();

	/**
	 * Updates the given render target. Based on the given render target configuration,
	 * it updates the texture states representing the attachments of the framebuffer.
	 *
	 * @param {RenderTarget} renderTarget - The render target to update.
	 * @param {number} [activeMipmapLevel=0] - The active mipmap level.
	 */
	updateRenderTarget(RenderTarget renderTarget, [int activeMipmapLevel = 0 ]) {

		final renderTargetData = this.get( renderTarget );

		final sampleCount = renderTarget.samples == 0 ? 1 : renderTarget.samples;
		final depthTextureMips = renderTargetData.depthTextureMips ?? ( renderTargetData.depthTextureMips = {} );

		final textures = renderTarget.textures;

		final size = this.getSize( textures[ 0 ] );

		final mipWidth = size.width >> activeMipmapLevel;
		final mipHeight = size.height >> activeMipmapLevel;

		DepthTexture? depthTexture = renderTarget.depthTexture ?? depthTextureMips[ activeMipmapLevel ];
		final useDepthTexture = renderTarget.depthBuffer == true || renderTarget.stencilBuffer == true;

		var textureNeedsUpdate = false;

		if ( depthTexture == null && useDepthTexture ) {
			depthTexture = DepthTexture(mipWidth,mipHeight);

			depthTexture.format = renderTarget.stencilBuffer ? DepthStencilFormat : DepthFormat;
			depthTexture.type = renderTarget.stencilBuffer ? UnsignedInt248Type : UnsignedIntType; // FloatType
			depthTexture.image.width = mipWidth;
			depthTexture.image.height = mipHeight;
			depthTexture.image.depth = size.depth;
			depthTexture is ArrayTexture = renderTarget.multiview == true && size.depth > 1;

			depthTextureMips[ activeMipmapLevel ] = depthTexture;
		}

		if ( renderTargetData.width != size.width || size.height != renderTargetData.height ) {
			textureNeedsUpdate = true;

			if ( depthTexture != null) {
				depthTexture.needsUpdate = true;
				depthTexture.image.width = mipWidth;
				depthTexture.image.height = mipHeight;
				depthTexture.image.depth = depthTexture is ArrayTexture ? depthTexture.image.depth : 1;
			}
		}

		renderTargetData.width = size.width;
		renderTargetData.height = size.height;
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
				this.updateTexture( texture, options );
			}

			if ( depthTexture != null) {
				this.updateTexture( depthTexture, options );
			}
		}

		// dispose handler

		if ( renderTargetData.initialized != true ) {
			renderTargetData.initialized = true;

			// dispose

			final onDispose = (){
				renderTarget.removeEventListener( 'dispose', onDispose );

				for ( var i = 0; i < textures.length; i ++ ) {
					this._destroyTexture( textures[ i ] );
				}

				if ( depthTexture != null) {
					this._destroyTexture( depthTexture );
				}

				this.delete( renderTarget );
			};

			renderTarget.addEventListener( 'dispose', onDispose );

		}

	}

	/**
	 * Updates the given texture. Depending on the texture state, this method
	 * triggers the upload of texture data to the GPU memory. If the texture data are
	 * not yet ready for the upload, it uses default texture data for as a placeholder.
	 *
	 * @param {Texture} texture - The texture to update.
	 * @param {Object} [options={}] - The options.
	 */
	updateTexture(Texture texture, [Map<String,dynamic>? options]) {
    options ??= {};

		final textureData = this.get( texture );
		if ( textureData.initialized == true && textureData.version == texture.version ) return;

		final isRenderTarget = texture.isRenderTargetTexture || texture.isDepthTexture || texture is FramebufferTexture;
		final backend = this.backend;

		if ( isRenderTarget && textureData.initialized == true ) {
			backend.destroySampler( texture );
			backend.destroyTexture( texture );
		}

		//

		if ( texture is FramebufferTexture ) {
			final renderTarget = this.renderer.getRenderTarget();

			if ( renderTarget != null) {
				texture.type = renderTarget.texture.type;
			} 
      else {
				texture.type = UnsignedByteType;
			}
		}

		//

		final width = this.getSize( texture ).width;
    final height = this.getSize( texture ).height;
    final depth = this.getSize( texture ).depth;

		options['width'] = width;
		options['height'] = height;
		options['depth'] = depth;
		options['needsMipmaps'] = this.needsMipmaps( texture );
		options['levels'] = options['needsMipmaps'] == true? this.getMipLevels( texture, width, height ) : 1;

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
					if ( options['needsMipmaps'] && texture.mipmaps.length == 0 ) backend.generateMipmaps( texture );
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
			this.info.memory.textures ++;

			// dispose
			final onDispose = (){
				texture.removeEventListener( 'dispose', onDispose );
				this._destroyTexture( texture );
			};

			texture.addEventListener( 'dispose', onDispose );
		}

		//

		textureData.version = texture.version;
	}

	/**
	 * Computes the size of the given texture and writes the result
	 * into the target vector. This vector is also returned by the
	 * method.
	 *
	 * If no texture data are available for the compute yet, the method
	 * returns default size values.
	 *
	 * @param {Texture} texture - The texture to compute the size for.
	 * @param {Vector3} target - The target vector.
	 * @return {Vector3} The target vector.
	 */
	getSize( texture, target = _size ) {
		var image = texture.images ? texture.images[ 0 ] : texture.image;

		if ( image ) {
			if ( image.image != null ) image = image.image;
			if ( image is HTMLVideoElement ) {
				target.width = image.videoWidth ?? 1;
				target.height = image.videoHeight ?? 1;
				target.depth = 1;
			} 
      else if ( image is VideoFrame ) {
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

	/**
	 * Computes the number of mipmap levels for the given texture.
	 *
	 * @param {Texture} texture - The texture.
	 * @param {number} width - The texture's width.
	 * @param {number} height - The texture's height.
	 * @return {number} The number of mipmap levels.
	 */
	getMipLevels(Texture texture, width, height ) {
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
		if ( this.has( texture ) == true ) {
			this.backend.destroySampler( texture );
			this.backend.destroyTexture( texture );

			this.delete( texture );

			this.info.memory['textures'] = this.info.memory['textures']!-1;
		}
	}
}
