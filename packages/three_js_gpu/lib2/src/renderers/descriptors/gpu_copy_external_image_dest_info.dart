import "gpu_texel_copy_texture_info.dart";

/**
 * Reusable descriptor for `GPUCopyExternalImageDestInfo`, the destination
 * argument to `GPUQueue.copyExternalImageToTexture()`.
 *
 * @private
 * @augments GPUTexelCopyTextureInfo
 */
class GPUCopyExternalImageDestInfo extends GPUTexelCopyTextureInfo {
  String colorSpace = 'srgb';
  bool premultipliedAlpha = false;

	GPUCopyExternalImageDestInfo():super();

	/**
	 * Resets the descriptor to its default state.
	 */
  @override
	void reset() {
		super.reset();
		this.colorSpace = 'srgb';
		this.premultipliedAlpha = false;
	}
}