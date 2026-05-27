/// Reusable descriptor configuration layout for `GPUDevice.createBindGroup()`.
class GPUBindGroupDescriptor {
  /// The label of the bind group.
  String label = '';

  /// The bind group layout the bind group conforms to.
  /// Maps to a native GpuBindGroupLayout instance, or null.
  dynamic layout;

  /// The bind group entries payload tracking arrays.
  final List<Map<String, dynamic>> entries = [];

  /// Constructs a new GPU bind group descriptor with explicit defaults.
  GPUBindGroupDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state. 
  /// The internal `entries` array is emptied without releasing its backing storage.
  void reset() {
    this.label = '';
    this.layout = null;
    
    // Replaces JavaScript array length reset trick (entries.length = 0)
    this.entries.clear(); 
  }
}
