/// Reusable nested state for `GPURenderPipelineDescriptor.multisample`.
class GPUMultisampleState {
  /// The number of samples per pixel.
  int count = 1;

  /// A bitmask determining which samples are written to.
  int mask = 0xFFFFFFFF;

  /// Whether a fragment's alpha channel is used to generate a sample coverage mask.
  bool alphaToCoverageEnabled = false;

  /// Constructs a new GPU multisample state layout with explicit defaults.
  GPUMultisampleState() {
    this.reset();
  }

  /// Resets the sub-state to its default values.
  void reset() {
    this.count = 1;
    this.mask = 0xFFFFFFFF; // Preserves full 32-bit unsigned default mask boundaries
    this.alphaToCoverageEnabled = false;
  }
}
