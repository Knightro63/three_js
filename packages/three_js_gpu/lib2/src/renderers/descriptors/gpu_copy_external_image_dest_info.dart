import './gpu_texel_copy_texture_info.dart';

/// Reusable descriptor for `GPUCopyExternalImageDestInfo`, the destination
/// argument to `GPUQueue.copyExternalImageToTexture()`.
class GPUCopyExternalImageDestInfo extends GPUTexelCopyTextureInfo {
  /// The predefined color space the destination texture is interpreted in.
  String colorSpace = 'srgb';

  /// Whether the destination texture has premultiplied alpha.
  bool premultipliedAlpha = false;

  /// Constructs a new GPU copy external image destination info block with explicit defaults.
  GPUCopyExternalImageDestInfo() : super();

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  @override
  void reset() {
    super.reset(); // Chain resource cleanup back to the base texel info map layers
    this.colorSpace = 'srgb';
    this.premultipliedAlpha = false;
  }
}
