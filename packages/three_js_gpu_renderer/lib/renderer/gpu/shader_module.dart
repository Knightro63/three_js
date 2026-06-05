import 'package:gpux/gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart'; // Adjust based on your exact gpux library paths

/// Gpu shader module implementation.
/// T029: Shader compilation and validation.
///
/// Compiles WGSL shaders to GPU bytecode.
class GpuShaderModule {
  final gpux.GpuDevice device;
  final ShaderModuleDescriptor descriptor;

  gpux.GpuShaderModule? _module;

  GpuShaderModule({
    required this.device,
    required this.descriptor,
  });

  /// Compiles the WGSL shader code.
  void compile() {
    try {
      final labelString = descriptor.label ?? "unnamed";
      console.info("INFO: Compiling shader: $labelString (${descriptor.stage.name})");
      console.info("INFO: WGSL source ($labelString):\n${descriptor.code}");
      console.info("INFO: Creating shader module...");

      // Replaces unsafe dynamic JS literals with a safe, strongly-typed gpux instantiation
      _module = device.createShaderModule(
        descriptor.code,
        label: descriptor.label ?? '',
      );

      console.info("INFO: Shader module created successfully");
      console.info("INFO: Shader compiled successfully: $labelString");
    } catch (e) {
      console.error("ERROR: Shader module creation exception: ${e.toString()}");
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
  gpux.GpuShaderModule? getModule() => _module;

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
