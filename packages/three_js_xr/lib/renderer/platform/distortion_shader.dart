import 'package:three_js_math/three_js_math.dart';

final distortionShader = {
  'uniforms': <String,dynamic>{
    "tDiffuse": <String,dynamic>{ 'value': null },
    'resolution': { 'value': Vector2() }, // Adjust for desired distortion
    'k1': { 'value': 0.024 }, // Adjust for desired distortion
    'k2': { 'value': 0.022 }, // Adjust for desired distortion
    'lensSize': {'value': Vector2(1,1)},
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

// final distortionShader = {
//   'uniforms': <String, dynamic>{
//     "tDiffuse": {'value': null},
//     'resolution': {'value': Vector2()},
//     'k1': {'value': 0.024}, 
//     'k2': {'value': 0.022}, 
//     'lensSize': {'value': Vector2(0.8, 0.9)}, // Adjusted default bounds for split eye clip
//     'cornerRadius': {'value': 0.25},
//     'type': {'value': 1} // 1 = Barrel, 2 = Pincushion
//   },
//   'vertexShader': '''
//     varying vec2 vUv;
//     void main() {
//       vUv = uv;
//       gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
//     }
//   ''',
//   'fragmentShader': '''
//     uniform sampler2D tDiffuse;
//     uniform float k1;
//     uniform float k2;
//     uniform int type;
//     uniform vec2 lensSize; 
//     uniform float cornerRadius; 
//     varying vec2 vUv;

//     float sdRoundedBox(in vec2 p, in vec2 b, in float r) {
//       vec2 q = abs(p) - b + r;
//       return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
//     }

//     void main() {
//       // Isolate the texture coordinate tracking parameters per eye window
//       bool isRightEye = (vUv.x > 0.5);
      
//       // STEP 1: Map vUv.x down to a clean [0.0, 1.0] eye-space scale 
//       vec2 eyeUv = vUv;
//       if (isRightEye) {
//         eyeUv.x = (vUv.x - 0.5) * 2.0;
//       } else {
//         eyeUv.x = vUv.x * 2.0;
//       }

//       // STEP 2: Center eye coordinates to a local [-1.0, 1.0] grid for distortion math
//       vec2 uv = eyeUv * 2.0 - 1.0;

//       // Clipping logic for lens mask
//       float mask = sdRoundedBox(uv, lensSize, cornerRadius);
//       if (mask > 0.0 && type == 0) {
//         gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
//         return;
//       }

//       float r2 = dot(uv, uv);
//       vec2 distorted_uv;

//       if (type == 1) {
//         // --- BARREL DISTORTION ---
//         uv = uv * (1.0 + k1 * r2 + k2 * r2 * r2);
//         distorted_uv = 0.5 * (uv + 1.0);
//       } else {
//         // --- PINCUSHION DISTORTION ---
//         float r4 = r2 * r2;
//         distorted_uv = ((uv / (1.0 + k1 * r2 + k2 * r4)) + 1.0) / 2.0;
//       }

//       // STEP 3: Boundary edge clip for distorted sampling space
//       if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
//         gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
//       } else {
//         // STEP 4: Map local eye space back to global texture atlas locations
//         vec2 finalTexCoord = distorted_uv;
//         if (isRightEye) {
//           finalTexCoord.x = 0.5 + (distorted_uv.x * 0.5);
//         } else {
//           finalTexCoord.x = distorted_uv.x * 0.5;
//         }
        
//         gl_FragColor = texture2D(tDiffuse, finalTexCoord);
//       }
//     }
//   '''
// };
