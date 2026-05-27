/// Reusable descriptor for `GPUDevice.createShaderModule()`.
class GPUShaderModuleDescriptor {
  /// The label of the shader module.
  String label = '';

  /// The WGSL source code of the shader module.
  String code = '';

  /// Compilation hints that may help the implementation produce optimized code.
  final List<Map<String, dynamic>> compilationHints = [];

  /// Constructs a new GPU shader module descriptor with explicit defaults.
  GPUShaderModuleDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.code = '';
    
    // Replaces JavaScript array length reset trick (compilationHints.length = 0)
    this.compilationHints.clear(); 
  }
}
