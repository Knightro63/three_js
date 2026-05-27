import 'package:gpux/gpux.dart';

/// Reusable descriptor configuration layout for `GPUTexture.createView()`.
class GPUTextureViewDescriptor {
  /// The label of the texture view.
  String label = '';

  /// The format of the texture view.
  GpuTextureFormat? format;

  /// The dimension of the texture view.
  GpuTextureViewDimension? dimension;

  /// The allowed usages for the texture view.
  int usage = 0;

  /// Which aspect of the texture is referenced.
  String aspect = 'all';

  /// The first mip level accessible to the texture view.
  int baseMipLevel = 0;

  /// The number of mip levels accessible to the texture view.
  int? mipLevelCount;

  /// The first array layer accessible to the texture view.
  int baseArrayLayer = 0;

  /// The number of array layers accessible to the texture view.
  int? arrayLayerCount;

  /// The component swizzle to apply when sampling the texture view.
  /// Requires the `'texture-component-swizzle'` feature; ignored otherwise.
  String swizzle = 'rgba';

  /// Constructs a new GPU texture view descriptor with explicit defaults.
  GPUTextureViewDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.format = null;
    this.dimension = null;
    this.usage = 0;
    this.aspect = 'all';
    this.baseMipLevel = 0;
    this.mipLevelCount = null;
    this.baseArrayLayer = 0;
    this.arrayLayerCount = null;
    this.swizzle = 'rgba';
  }
}
