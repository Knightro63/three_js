import 'package:gpux/gpux.dart';

/// Reusable descriptor configuration layout for `GPUDevice.createTexture()`.
class GPUTextureDescriptor {
  /// The label of the texture.
  String label = '';

  /// The size of the texture defining width, height, and depth metrics.
  final Map<String, int> size = {
    'width': 0,
    'height': 1,
    'depthOrArrayLayers': 1
  };

  /// The number of mip levels the texture will contain.
  int mipLevelCount = 1;

  /// The sample count of the texture.
  int sampleCount = 1;

  /// The dimension of the set of texel coordinates.
  GpuTextureDimension dimension = GpuTextureDimension.d2;

  /// The format of the texture.
  GpuTextureFormat? format;

  /// The allowed usages for the texture.
  int? usage;

  /// The formats that views of this texture may use.
  final List<GpuTextureFormat> viewFormats = [];

  /// The view dimension to use when binding the texture (compatibility mode).
  GpuTextureViewDimension? textureBindingViewDimension;

  /// Constructs a new GPU texture configuration descriptor with explicit defaults.
  GPUTextureDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    
    this.size['width'] = 0;
    this.size['height'] = 1;
    this.size['depthOrArrayLayers'] = 1;
    
    this.mipLevelCount = 1;
    this.sampleCount = 1;
    this.dimension = GpuTextureDimension.d2;
    this.format = null;
    this.usage = null;
    
    this.viewFormats.clear(); // Replaces JavaScript array length reset trick
    this.textureBindingViewDimension = null;
  }
}
