import 'package:three_js_core/three_js_core.dart'; // Adjust imports to match your MaterialShader libraries

/// WGSL shader library for the basic WebGPU material routed through the shared shader registry.
class BasicShaders {
  // Enforce non-instantiability to match Kotlin's object semantic
  BasicShaders._();

  /// Lazily evaluated compilation result block.
  /// Dart's native 'late final' behaves identically to Kotlin's 'by lazy',
  /// evaluating the compilation chain exactly once upon first-read access.
  static late final ShaderCompilationResult _shaderSource = 
      MaterialShaderGenerator.compile(MaterialShaderLibrary.basic());

  /// Retrieves the processed WGSL vertex shader source string.
  static String get vertexShader => _shaderSource.vertexSource;

  /// Retrieves the processed WGSL fragment shader source string.
  static String get fragmentShader => _shaderSource.fragmentSource;
}
