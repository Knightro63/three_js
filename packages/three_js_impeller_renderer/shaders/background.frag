#include <material_block.glsl>
#include <scene_block.glsl>
#include <color.glsl>
//include <tonemapping.glsl>

uniform sampler2D map;

in vec2 v_uv; 

out vec4 frag_color;

void main() {
  bool hasMap      = material.flags0.y > 0.5;
  vec4 texelColor = vec4(1.0);

  if (hasMap) {
    texelColor = texture(map, v_uv);
    // texelColor.rgb = mix(
    //   pow(texelColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)), 
    //   texelColor.rgb * 0.0773993808, 
    //   vec3(lessThanEqual(texelColor.rgb, vec3(0.04045)))
    // );
    texelColor.rgb *= scene.bgMapParms.x;
  }

  if (texelColor.a < 0.01) {
    discard; 
  }

  vec4 finalRGBA = applyColor(texelColor,scene.rendParms.z);
  frag_color = finalRGBA;
}
