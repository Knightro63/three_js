import 'package:three_js_math/three_js_math.dart';

/**
 * Reusable descriptor for `GPUCopyExternalImageSourceInfo`, the source argument
 * to `GPUQueue.copyExternalImageToTexture()`.
 *
 * @private
 */
class GPUCopyExternalImageSourceInfo {
  /**
   * The image-like source.
   *
   * @type {?(ImageBitmap|ImageData|HTMLImageElement|HTMLVideoElement|VideoFrame|HTMLCanvasElement|OffscreenCanvas)}
   * @default null
   */
  dynamic source = null;
  Vector2 origin = Vector2();
  bool flipY = false;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.source = null;
		this.origin.x = 0;
		this.origin.y = 0;
		this.flipY = false;
	}
}
