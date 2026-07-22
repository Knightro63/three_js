#include <material_block.glsl>
#include <scene_block.glsl>
#include <color.glsl>
#include <tonemapping.glsl>

uniform sampler2D envMap;

in vec3 v_worldPosition; 
in vec2 v_uv; 

out vec4 frag_color;

void main() {
  vec4 texColor = vec4(0.0,0.0,0.0,1.0);
  mat3 backgroundRotation = mat3(scene.bgMapRotation);
  vec3 sampleDirection = normalize(backgroundRotation * v_worldPosition);

  // if(scene.envParms.z > 1.5){
  //   float blurAmount = scene.bgMapParms.w;
  //   texColor = textureLod(envMap, sampleDirection, blurAmount * 7.0);
  // }
  if(scene.envParms.z > 0.5){
    //vec3 flippedDirection = vec3(scene.bgMapParms.y * sampleDirection.x, sampleDirection.y, sampleDirection.z);
    texColor = texture(envMap, v_uv);
  }

  if (texColor.a < 0.001) {
    discard;
  }

  texColor.rgb *= scene.bgMapParms.x;
  vec3 tone = toneMapping( texColor.rgb );
  frag_color = applyColor(vec4(tone,texColor.a), scene.rendParms.z);
}
