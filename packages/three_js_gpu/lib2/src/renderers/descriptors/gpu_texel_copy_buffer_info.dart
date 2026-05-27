/// Reusable descriptor for `GPUTexelCopyBufferInfo`, the buffer side of
/// `GPUCommandEncoder.copyTextureToBuffer()` and `copyBufferToTexture()`.
class GPUTexelCopyBufferInfo {
  /// The target buffer (maps to a native GpuBuffer instance).
  dynamic buffer;

  /// The byte offset within the buffer where the texel data begins.
  int offset = 0;

  /// The stride, in bytes, between rows of texel blocks.
  int? bytesPerRow;

  /// The number of texel block rows per single image of the texture.
  int? rowsPerImage;

  /// Constructs a new GPU texel copy buffer info block with explicit defaults.
  GPUTexelCopyBufferInfo() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.buffer = null;
    this.offset = 0;
    this.bytesPerRow = null;
    this.rowsPerImage = null;
  }
}
