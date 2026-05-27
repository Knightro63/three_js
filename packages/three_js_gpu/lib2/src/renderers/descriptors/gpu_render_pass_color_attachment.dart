import 'package:gpux/gpux.dart';

/// Reusable descriptor for `GPURenderPassColorAttachment`, the type of each
/// entry in `GPURenderPassDescriptor.colorAttachments`.
class GPURenderPassColorAttachment {
  /// The texture view the pass renders into (maps to a native GpuTextureView instance).
  dynamic view;

  /// The depth slice the pass renders into.
  int? depthSlice;

  /// The texture view that receives the resolved output of multisampled rendering.
  dynamic resolveTarget;

  /// The clear value used when `loadOp` is `GpuLoadOp.clear`.
  Map<String, double>? clearValue;

  /// The load operation performed at the start of the pass.
  GpuLoadOp? loadOp;

  /// The store operation performed at the end of the pass.
  GpuStoreOp? storeOp;

  /// Constructs a new GPU render pass color attachment descriptor with explicit defaults.
  GPURenderPassColorAttachment() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.view = null;
    this.depthSlice = null;
    this.resolveTarget = null;
    this.clearValue = null;
    this.loadOp = null;
    this.storeOp = null;
  }
}
