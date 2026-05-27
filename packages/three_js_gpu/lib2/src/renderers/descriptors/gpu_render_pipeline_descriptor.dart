import './gpu_sampler_descriptor.dart';

/// Reusable descriptor for `GPUDevice.createRenderPipeline()` and
/// `createRenderPipelineAsync()`.
class GPURenderPipelineDescriptor {
  /// The label of the render pipeline.
  String label = '';

  /// The pipeline layout the pipeline conforms to, or `'auto'`.
  /// Maps to a native GpuPipelineLayout object instance, a String ('auto'), or null.
  dynamic layout;

  /// The programmable vertex stage details map.
  Map<String, dynamic>? vertex;

  /// The primitive-assembly state configurations.
  final Map<String, dynamic> primitive = {};

  /// The depth/stencil state, omitted when the pipeline has no depth or stencil aspect.
  Map<String, dynamic>? depthStencil;

  /// The multisample state configuration object.
  final GPUMultisampleState multisample = GPUMultisampleState();

  /// The programmable fragment stage. Omitted for vertex-only pipelines.
  Map<String, dynamic>? fragment;

  /// Constructs a new GPU render pipeline descriptor with explicit defaults.
  GPURenderPipelineDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.layout = null;
    this.vertex = null;
    
    this.primitive.clear();
    this.depthStencil = null;
    this.multisample.reset();
    this.fragment = null;
  }
}

