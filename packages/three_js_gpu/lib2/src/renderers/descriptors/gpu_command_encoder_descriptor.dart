/// Reusable descriptor for `GPUDevice.createCommandEncoder()`.
class GPUCommandEncoderDescriptor {
  /// The label of the command encoder.
  String label = '';

  /// Constructs a new GPU command encoder descriptor with explicit defaults.
  GPUCommandEncoderDescriptor() {
    this.reset();
  }

  /// Resets the descriptor to its default state.
  void reset() {
    this.label = '';
  }
}
