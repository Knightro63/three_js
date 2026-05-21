import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths

/// WebGPU shader module implementation.
/// T029: Shader compilation and validation.
///
/// Compiles WGSL shaders to GPU bytecode.
class WebGPUShaderModule {
  final GpuDevice device;
  final ShaderModuleDescriptor descriptor;

  GpuShaderModule? _module;

  WebGPUShaderModule({
    required this.device,
    required this.descriptor,
  });

  /// Compiles the WGSL shader code.
  void compile() {
    try {
      final labelString = descriptor.label ?? "unnamed";
      print("INFO: Compiling shader: $labelString (${descriptor.stage.name})");
      print("INFO: WGSL source ($labelString):\n${descriptor.code}");
      print("INFO: Creating shader module...");

      // Replaces unsafe dynamic JS literals with a safe, strongly-typed gpux instantiation
      _module = device.createShaderModule(
        descriptor.code,
        label: descriptor.label ?? '',
      );

      print("INFO: Shader module created successfully");
      print("INFO: Shader compiled successfully: $labelString");
    } catch (e) {
      print("ERROR: Shader module creation exception: ${e.toString()}");
      rethrow; // Bounces the error upward safely without breaking state tracking
    }
  }

  /// Validates the shader without altering the active instance module configuration state.
  /// @return true if shader is structurally valid WGSL.
  bool validate() {
    try {
      // Attempt temporary compilation via the hardware layer to catch lexer issues
      device.createShaderModule(descriptor.code);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the compiled shader module hardware reference.
  GpuShaderModule? getModule() => _module;

  /// Gets the logical pipeline shader execution stage.
  ShaderStage getStage() => descriptor.stage;

  /// Disposes the shader module references from execution bounds.
  void dispose() {
    _module = null;
  }
}

/// Structural description parameter layout container matching original signature
class ShaderModuleDescriptor {
  final String? label;
  final String code;
  final ShaderStage stage;

  const ShaderModuleDescriptor({
    this.label,
    required this.code,
    required this.stage,
  });
}

/// Shader stage identifiers 
enum ShaderStage {
  vertex,
  fragment,
  compute,
}
