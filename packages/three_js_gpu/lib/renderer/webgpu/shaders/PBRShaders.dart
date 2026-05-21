import 'package:three_js_core/three_js_core.dart'; // Adjust imports to match your MaterialShader location

/// WGSL shader library for Physically-Based Rendering (PBR/Standard) materials.
class PBRShaders {
  // Enforce non-instantiability to match Kotlin's object semantic
  PBRShaders._();

  /// Lazily evaluated compilation block for the MeshStandard/PBR pipeline.
  /// Evaluates only once when the standard shader is first requested.
  static late final ShaderCompilationResult _shaderSource = 
      MaterialShaderGenerator.compile(MaterialShaderLibrary.meshStandard());

  /// Retrieves the processed WGSL vertex shader source string.
  static String get vertexShader => _shaderSource.vertexSource;

  /// Retrieves the processed WGSL fragment shader source string.
  static String get fragmentShader => _shaderSource.fragmentSource;
}
