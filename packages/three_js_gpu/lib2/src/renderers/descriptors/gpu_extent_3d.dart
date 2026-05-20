/**
 * Reusable descriptor for `GPUExtent3D` in its dictionary form, used by
 * `GPUQueue.writeTexture()`, `GPUQueue.copyExternalImageToTexture()` and
 * the various `GPUCommandEncoder` copy methods.
 *
 * @private
 */
class GPUExtent3D {
  double width = 0;
  double height = 1;
  int depthOrArrayLayers = 1;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.width = 0;
		this.height = 1;
		this.depthOrArrayLayers = 1;
	}
}
