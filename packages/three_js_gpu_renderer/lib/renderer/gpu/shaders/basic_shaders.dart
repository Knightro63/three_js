import '../../../shader/material_shader_library.dart';

/// WGSL shader library for the basic material routed through the shared shader registry.
class BasicShaders {
  // Enforce non-instantiability to match Kotlin's object semantic
  BasicShaders._();

  /// Lazily evaluated compilation result block.
  /// Dart's native 'late final' behaves identically to Kotlin's 'by lazy',
  /// evaluating the compilation chain exactly once upon first-read access.
  static late final MaterialShaderSource _shaderSource = MaterialShaderGenerator.compile(MaterialShaderLibrary.convert('basic'));

  /// Retrieves the processed WGSL vertex shader source string.
  static String get vertexShader => _shaderSource.vertexSource;

  /// Retrieves the processed WGSL fragment shader source string.
  static String get fragmentShader => _shaderSource.fragmentSource;
}
