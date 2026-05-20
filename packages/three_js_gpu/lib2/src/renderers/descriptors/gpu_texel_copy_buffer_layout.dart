/**
 * Reusable descriptor for `GPUTexelCopyBufferLayout`, the data-layout argument
 * to `GPUQueue.writeTexture()`.
 *
 * @private
 */
class GPUTexelCopyBufferLayout {
  /**
   * The byte offset within the source data where the texel data begins.
   *
   * @type {number}
   * @default 0
   */
  int offset = 0;

  /**
   * The stride, in bytes, between rows of texel blocks.
   *
   * @type {number|undefined}
   */
  int? bytesPerRow;

  /**
   * The number of texel block rows per single image of the texture.
   *
   * @type {number|undefined}
   */
  int? rowsPerImage;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.offset = 0;
		this.bytesPerRow = null;
		this.rowsPerImage = null;
	}
}
