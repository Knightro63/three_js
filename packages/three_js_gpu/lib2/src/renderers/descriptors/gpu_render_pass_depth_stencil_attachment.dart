import 'package:gpux/gpux.dart';

/// Reusable descriptor for `GPURenderPassDepthStencilAttachment`, the
/// `depthStencilAttachment` field of `GPURenderPassDescriptor`.
class GPURenderPassDepthStencilAttachment {
  /// The depth/stencil texture view the pass renders into (maps to a native GpuTextureView instance).
  dynamic view;

  /// The load operation applied to the depth aspect at the start of the pass.
  GpuLoadOp? depthLoadOp;

  /// The store operation applied to the depth aspect at the end of the pass.
  GpuStoreOp? depthStoreOp;

  /// The clear value used when `depthLoadOp` is `GpuLoadOp.clear`.
  double? depthClearValue;

  /// Whether the depth aspect is read-only.
  bool depthReadOnly = false;

  /// The load operation applied to the stencil aspect at the start of the pass.
  GpuLoadOp? stencilLoadOp;

  /// The store operation applied to the stencil aspect at the end of the pass.
  GpuStoreOp? stencilStoreOp;

  /// The clear value used when `stencilLoadOp` is `GpuLoadOp.clear`.
  int stencilClearValue = 0;

  /// Whether the stencil aspect is read-only.
  bool stencilReadOnly = false;

  /// Constructs a new GPU render pass depth-stencil attachment descriptor with explicit defaults.
  GPURenderPassDepthStencilAttachment() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.view = null;
    this.depthLoadOp = null;
    this.depthStoreOp = null;
    this.depthClearValue = null;
    this.depthReadOnly = false;
    this.stencilLoadOp = null;
    this.stencilStoreOp = null;
    this.stencilClearValue = 0;
    this.stencilReadOnly = false;
  }
}
