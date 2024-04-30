import 'shader_material.dart';

class RawShaderMaterial extends ShaderMaterial {
  RawShaderMaterial([super.parameters]){
    type = 'RawShaderMaterial';
  }
  RawShaderMaterial.fromMap([Map<String, dynamic>? parameters]):super.fromMap(parameters){
    type = 'RawShaderMaterial';
  }
}
