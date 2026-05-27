/// Reusable descriptor configuration layout for `GPUTexelCopyTextureInfo`, the texture side of
/// `GPUCommandEncoder.copyTextureToTexture()`, `copyTextureToBuffer()` and
/// `GPUQueue.writeTexture()`.
class GPUTexelCopyTextureInfo {
  /// The target texture reference layer (maps to a native GpuTexture instance).
  dynamic texture;

  /// The mipmap level of the texture.
  int mipLevel = 0;

  /// The origin offset within the texture.
  final Map<String, int> origin = {
    'x': 0,
    'y': 0,
    'z': 0
  };

  /// Which aspect of the texture is referenced.
  String aspect = 'all';

  /// Constructs a new GPU texel copy info structural block with explicit defaults.
  GPUTexelCopyTextureInfo() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.texture = null;
    this.mipLevel = 0;
    
    // Enforcing direct map bracket configurations based on directive instructions
    this.origin['x'] = 0;
    this.origin['y'] = 0;
    this.origin['z'] = 0;
    
    this.aspect = 'all';
  }
}
