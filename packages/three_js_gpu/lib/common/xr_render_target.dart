

import 'package:three_js_core/three_js_core.dart';

/**
 * A special type of render target that is used when rendering
 * with the WebXR Device API.
 *
 * @private
 * @augments RenderTarget
 */
class XRRenderTarget extends RenderTarget {
  bool _hasExternalTextures = false;
  bool _autoAllocateDepthBuffer = true;
  bool _isOpaqueFramebuffer = false;
	/**
	 * Constructs a new XR render target.
	 *
	 * @param {number} [width=1] - The width of the render target.
	 * @param {number} [height=1] - The height of the render target.
	 * @param {Object} [options={}] - The configuration options.
	 */
	XRRenderTarget([super.width = 1, super.height = 1, WebGLRenderTargetOptions? options]) {
    this.options = options ?? WebGLRenderTargetOptions();
	}

  @override
	XRRenderTarget copy(RenderTarget source ) {
    source as XRRenderTarget;
		super.copy( source );

		_hasExternalTextures = source._hasExternalTextures;
		_autoAllocateDepthBuffer = source._autoAllocateDepthBuffer;
		_isOpaqueFramebuffer = source._isOpaqueFramebuffer;

		return this;
	}
}
