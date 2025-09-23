import 'package:three_js_math/three_js_math.dart';

final distortionShader = {
  'uniforms': <String,dynamic>{
    "tDiffuse": <String,dynamic>{ 'value': null },
    'k1': { 'value': 0.20 }, // Adjust for desired distortion
    'k2': { 'value': 0.02 }, // Adjust for desired distortion
    'lensSize': {'value': Vector2(0.9,0.9)},
    'cornerRadius': { 'value': 0.25 },
    'eyeTextureOffsetX': {'value': 0},
    'eyeTextureOffsetY': {'value': 0},
    'type': {'value': 1}
  },
  'vertexShader': '''
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  ''',
  'fragmentShader':'''
    uniform sampler2D tDiffuse;
    uniform float k1;
    uniform float k2;
    uniform int type;
    uniform float eyeTextureOffsetX;
    uniform float eyeTextureOffsetY;
    uniform vec2 lensSize; // Width and height of the lens area (e.g., vec2(0.8, 0.9))
    uniform float cornerRadius; // The radius of the corners (e.g., 0.1)
    varying vec2 vUv;

    float sdRoundedBox( in vec2 p, in vec2 b, in float r ) {
      vec2 q = abs(p)-b+r;
      return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
    }

    void main() {
      // Center UVs for the current eye's texture region and map to [-1, 1] range
      vec2 uv;
      //uv.x = (vUv.x - 0.25 -eyeTextureOffsetX) * 4.0 - 1.0;
      uv.x = vUv.x * 2.0 - 1.0 - eyeTextureOffsetX;
      uv.y = vUv.y * 2.0 - 1.0 - eyeTextureOffsetY;

      // Clipping logic for rounded rectangle using signed distance
      float mask = sdRoundedBox(uv, lensSize, cornerRadius);

      if (mask > 0.0 && type == 0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
      }
      else{
        float r2 = dot(uv, uv);
        if(type == 1){
          /// Barrel distortion
          uv = uv * (1.0 + k1 * r2 + k2 * r2 * r2);
          vec2 distorted_uv = 0.5 * (uv + 1.0);
          if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
          } else {
            gl_FragColor = texture2D(tDiffuse, distorted_uv);
          }
        }else{
          /// Pincushion distortion
          float r4 = r2 * r2;
          vec2 distorted_uv = ((uv / (1.0 + k1 * r2 + k2 * r4)) + 1.0) / 2.0;
          gl_FragColor = texture2D(tDiffuse, distorted_uv);
        }
      }
    }
  '''
};