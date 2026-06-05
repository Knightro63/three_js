import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk flatShading = ShaderChunk(
  name: 'common.flat_shading',
  source: '''
  fn evaluateNormal(worldNormal: vec3<f32>, worldPosition: vec3<f32>) -> vec3<f32> {
      var N = normalize(worldNormal);
      let isFlatShadingActive = uniforms.pbrParams.z;
      
      if (isFlatShadingActive > 0.5) {
          // Reconstruct the true flat face normal using partial derivatives
          N = -normalize(cross(dpdx(worldPosition), dpdy(worldPosition)));
      }
      
      return N;
  }
  ''',
);
