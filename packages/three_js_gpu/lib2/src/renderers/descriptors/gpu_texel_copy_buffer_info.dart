/**
 * Reusable descriptor for `GPUTexelCopyBufferInfo`, the buffer side of
 * `GPUCommandEncoder.copyTextureToBuffer()` and `copyBufferToTexture()`.
 *
 * @private
 */
class GPUTexelCopyBufferInfo {
  /**
   * The target buffer.
   *
   * @type {?GPUBuffer}
   * @default null
   */
  GPUBuffer? buffer;

  /**
   * The byte offset within the buffer where the texel data begins.
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
		this.buffer = null;
		this.offset = 0;
		this.bytesPerRow = null;
		this.rowsPerImage = null;
	}
}
