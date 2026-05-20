import 'package:three_js_math/three_js_math.dart';

/**
 * Reusable descriptor for `GPUTexelCopyTextureInfo`, the texture side of
 * `GPUCommandEncoder.copyTextureToTexture()`, `copyTextureToBuffer()` and
 * `GPUQueue.writeTexture()`.
 *
 * @private
 */
class GPUTexelCopyTextureInfo {
  GPUTexture? texture = null;
  int mipLevel = 0;
  final Vector3 origin = Vector3();
  String aspect = 'all';

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.texture = null;
		this.mipLevel = 0;
		this.origin.x = 0;
		this.origin.y = 0;
		this.origin.z = 0;
		this.aspect = 'all';
	}
}
