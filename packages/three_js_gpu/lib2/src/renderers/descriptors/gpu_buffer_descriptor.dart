/// Reusable descriptor layout configuration for `GPUDevice.createBuffer()`.
class GPUBufferDescriptor {
  /// The label of the buffer.
  String label = '';

  /// The size of the buffer in bytes.
  int size = 0;

  /// The allowed usages for the buffer.
  int usage = 0;

  /// Whether the buffer is in the mapped state at creation.
  bool mappedAtCreation = false;

  /// Constructs a new GPU buffer descriptor with explicit defaults.
  GPUBufferDescriptor() {
    this.reset();
  }

  /// Resets the descriptor to its default state.
  void reset() {
    this.label = '';
    this.size = 0;
    this.usage = 0;
    this.mappedAtCreation = false;
  }
}
