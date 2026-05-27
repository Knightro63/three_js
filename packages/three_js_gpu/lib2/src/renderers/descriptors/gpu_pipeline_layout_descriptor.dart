/// Reusable descriptor configuration layout for `GPUDevice.createPipelineLayout()`.
class GPUPipelineLayoutDescriptor {
  /// The label of the pipeline layout.
  String label = '';

  /// The set of bind group layouts the pipeline layout describes.
  /// Maps to an array list of native GpuBindGroupLayout instances, or null.
  List<dynamic>? bindGroupLayouts;

  /// Constructs a new GPU pipeline layout descriptor with explicit defaults.
  GPUPipelineLayoutDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.bindGroupLayouts = null;
  }
}
