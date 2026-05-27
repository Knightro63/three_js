/// Reusable descriptor for `GPUDevice.createComputePipeline()`.
class GPUComputePipelineDescriptor {
  /// The label of the compute pipeline.
  String label = '';

  /// The pipeline layout the pipeline conforms to, or `'auto'`.
  /// Maps to a native GpuPipelineLayout object instance, a String ('auto'), or null.
  dynamic layout;

  /// The programmable compute stage configurations.
  Map<String, dynamic>? compute;

  /// Constructs a new GPU compute pipeline descriptor with explicit defaults.
  GPUComputePipelineDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.layout = null;
    this.compute = null;
  }
}
