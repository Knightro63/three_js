import './gpu_render_pass_timestamp_writes.dart';

/// Reusable descriptor layout configuration for `GPUCommandEncoder.beginComputePass()`.
class GPUComputePassDescriptor {
  /// The label of the compute pass.
  String label = '';

  /// Defines which timestamp values are written and where.
  /// Reuses the unified shape shared with GPURenderPassTimestampWrites.
  GPURenderPassTimestampWrites? timestampWrites;

  /// Constructs a new GPU compute pass descriptor with explicit defaults.
  GPUComputePassDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.timestampWrites = null;
  }
}
