/// Reusable descriptor for `GPUTexelCopyBufferLayout`, the data-layout argument
/// to `GPUQueue.writeTexture()`.
class GPUTexelCopyBufferLayout {
  /// The byte offset within the source data where the texel data begins.
  int offset = 0;

  /// The stride, in bytes, between rows of texel blocks.
  int? bytesPerRow;

  /// The number of texel block rows per single image of the texture.
  int? rowsPerImage;

  /// Constructs a new GPU texel copy buffer layout with explicit defaults.
  GPUTexelCopyBufferLayout() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.offset = 0;
    this.bytesPerRow = null;
    this.rowsPerImage = null;
  }
}
