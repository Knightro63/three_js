import 'package:three_js_core/three_js_core.dart';

/// A special type of render target that is used when rendering
/// with the WebXR Device API.
class XRRenderTarget extends RenderTarget {
  bool _hasExternalTextures = false;
  bool _autoAllocateDepthBuffer = true;
  bool _isOpaqueFramebuffer = false;

	/// Constructs a new XR render target.
	XRRenderTarget([super.width = 1, super.height = 1, RenderTargetOptions? options]) {
    this.options = options ?? RenderTargetOptions();
	}

  @override
	XRRenderTarget copy(BaseRenderTarget source ) {
    source as XRRenderTarget;
		super.copy( source );

		_hasExternalTextures = source._hasExternalTextures;
		_autoAllocateDepthBuffer = source._autoAllocateDepthBuffer;
		_isOpaqueFramebuffer = source._isOpaqueFramebuffer;

		return this;
	}
}
