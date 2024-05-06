import 'shader_material.dart';

/// This class works just like [ShaderMaterial], except that definitions
/// of built-in uniforms and attributes are not automatically prepended to the
/// GLSL shader code.
class RawShaderMaterial extends ShaderMaterial {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material] and
  /// [ShaderMaterial]) can be passed in here.
  RawShaderMaterial([super.parameters]){
    type = 'RawShaderMaterial';
  }
  RawShaderMaterial.fromMap([Map<String, dynamic>? parameters]):super.fromMap(parameters){
    type = 'RawShaderMaterial';
  }
}
