/// Reusable descriptor for `GPUExtent3D` in its dictionary form, used by
/// `GPUQueue.writeTexture()`, `GPUQueue.copyExternalImageToTexture()` and
/// the various `GPUCommandEncoder` copy methods.
class GPUExtent3D {
  /// The width of the extent.
  int width = 0;

  /// The height of the extent.
  int height = 1;

  /// The depth (for 3D textures) or number of array layers.
  int depthOrArrayLayers = 1;

  /// Constructs a new GPU extent 3D descriptor with explicit defaults.
  GPUExtent3D() {
    this.reset();
  }

  /// Resets the descriptor to its default state.
  void reset() {
    this.width = 0;
    this.height = 1;
    this.depthOrArrayLayers = 1;
  }
}
