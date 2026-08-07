#include <color.glsl>
//include <tonemapping.glsl>

uniform sampler2D t2D;

in vec2 v_uv;
in float v_bright;

out vec4 frag_color;

void main() {
  vec4 texelColor = texture(t2D, v_uv);
  // texelColor.rgb = mix(
  //   pow(texelColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)), 
  //   texelColor.rgb * 0.0773993808, 
  //   vec3(lessThanEqual(texelColor.rgb, vec3(0.04045)))
  // );
  texelColor.rgb *= v_bright;

  if (texelColor.a < 0.01) {
    discard; 
  }

  frag_color = applyColor(texelColor,2);
}
