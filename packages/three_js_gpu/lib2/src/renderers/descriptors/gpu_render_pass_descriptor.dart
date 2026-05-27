import './gpu_render_pass_timestamp_writes.dart';

/// Reusable descriptor configuration layout for `GPUCommandEncoder.beginRenderPass()`.
class GPURenderPassDescriptor {
  /// The label of the render pass.
  String label = '';

  /// The color attachments of the render pass.
  final List<dynamic> colorAttachments = [];

  /// The depth-stencil attachment of the render pass.
  dynamic depthStencilAttachment;

  /// The query set used for occlusion queries during the pass.
  dynamic occlusionQuerySet;

  /// Defines which timestamp values are written and where.
  GPURenderPassTimestampWrites? timestampWrites;

  /// The maximum number of draw calls that can be issued during the pass.
  int maxDrawCount = 50000000;

  /// Constructs a new GPU render pass descriptor with explicit defaults.
  GPURenderPassDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state. 
  /// The internal `colorAttachments` array is emptied without releasing its backing storage.
  void reset() {
    this.label = '';
    
    // Replaces JavaScript array length reset trick (colorAttachments.length = 0)
    this.colorAttachments.clear(); 
    
    this.depthStencilAttachment = null;
    this.occlusionQuerySet = null;
    this.timestampWrites = null;
    this.maxDrawCount = 50000000;
  }
}
