/// Reusable descriptor for `GPUCopyExternalImageSourceInfo`, the source argument
/// to `GPUQueue.copyExternalImageToTexture()`.
class GPUCopyExternalImageSourceInfo {
  /// The image-like source.
  /// Maps to an ImageBitmap, ImageData, HTMLImageElement, HTMLCanvasElement, or native textures context.
  dynamic source;

  /// The origin offset within the source.
  final Map<String, int> origin = {
    'x': 0,
    'y': 0
  };

  /// Whether the source is flipped vertically before copying.
  bool flipY = false;

  /// Constructs a new GPU copy external image source info block with explicit defaults.
  GPUCopyExternalImageSourceInfo() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.source = null;
    
    // Enforcing direct map bracket configurations based on directive instructions
    this.origin['x'] = 0;
    this.origin['y'] = 0;
    
    this.flipY = false;
  }
}
