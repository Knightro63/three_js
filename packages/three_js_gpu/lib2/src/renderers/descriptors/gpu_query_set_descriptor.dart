import 'package:gpux/gpux.dart';

/// Reusable descriptor layout configuration for `GPUDevice.createQuerySet()`.
class GPUQuerySetDescriptor {
  /// The label of the query set.
  String label = '';

  /// The type of queries managed by the set.
  GpuQueryType? type;

  /// The number of queries managed by the set.
  int count = 0;

  /// Constructs a new GPU query set descriptor with explicit defaults.
  GPUQuerySetDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.type = null;
    this.count = 0;
  }
}
