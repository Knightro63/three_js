import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/clipping_context.dart';
import 'package:three_js_math/three_js_math.dart';

int _id = 0;

/**
 * Any render or compute command is executed in a specific context that defines
 * the state of the renderer and its backend. Typical examples for such context
 * data are the current clear values or data from the active framebuffer. This
 * module is used to represent these contexts as objects.
 *
 * @private
 */
class RenderContext {
  late int id;
  bool color = true;
  bool clearColor = true;

	Map<String,dynamic> clearColorValue = { 'r': 0, 'g': 0, 'b': 0, 'a': 1 };


	bool depth = true;
	bool clearDepth = true;
	double clearDepthValue = 1;
	bool stencil = false;
	bool clearStencil = true;
	double clearStencilValue = 1;
	bool viewport = false;
	Vector4 viewportValue = new Vector4();
	bool scissor = false;
	Vector4 scissorValue = new Vector4();

	RenderTarget? renderTarget = null;
	List<Texture>? textures;
	DepthTexture? depthTexture;
	int activeCubeFace = 0;
	int activeMipmapLevel = 0;
	int sampleCount = 1;

	int width = 0;
	int height = 0;
	int occlusionQueryCount = 0;
	ClippingContext? clippingContext;
	bool isRenderContext = true;

	/**
	 * Constructs a new render context.
	 */
	RenderContext() {
		this.id = _id ++;
	}

	/**
	 * Returns the cache key of this render context.
	 *
	 * @return {number} The cache key.
	 */
	int getCacheKey() {
		return _getCacheKey( this );
	}
}

/**
 * Computes a cache key for the given render context. This key
 * should identify the render target state so it is possible to
 * configure the correct attachments in the respective backend.
 *
 * @param {RenderContext} renderContext - The render context.
 * @return {number} The cache key.
 */
int _getCacheKey( renderContext ) {
  final textures = renderContext.textures;
	final activeCubeFace = renderContext.activeCubeFace;

	final values = [ activeCubeFace ];

	for ( final texture in textures ) {
		values.add( texture.id );
	}

	return hashArray( values );
}
