/// Reusable descriptor for `GPURenderPassTimestampWrites`, the
/// `timestampWrites` field of `GPURenderPassDescriptor`. The same shape is
/// also accepted as `GPUComputePassTimestampWrites`.
class GPURenderPassTimestampWrites {
  /// The query set the timestamps are written to (maps to a native GpuQuerySet instance).
  dynamic querySet;

  /// The index in the query set the beginning timestamp is written to.
  int? beginningOfPassWriteIndex;

  /// The index in the query set the ending timestamp is written to.
  int? endOfPassWriteIndex;

  /// Constructs a new GPU render pass timestamp descriptor with explicit defaults.
  GPURenderPassTimestampWrites() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.querySet = null;
    this.beginningOfPassWriteIndex = null;
    this.endOfPassWriteIndex = null;
  }
}
