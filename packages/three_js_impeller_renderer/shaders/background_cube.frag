#include <color.glsl>

uniform samplerCube envMap;
uniform sampler2D envMap2D;

in vec3 v_worldPosition; 
in vec2 v_uv; 
in vec4 parms;

out vec4 frag_color;

void main() {
  vec4 texColor = vec4(0.0,0.0,0.0,1.0);
  //mat3 backgroundRotation = mat3(bgMapRotation);
  //vec3 sampleDirection = normalize(backgroundRotation * v_worldPosition);

  if(parms.x > 1.5){
    texColor = texture(envMap, v_worldPosition);
  }
  else if(parms.x > 0.5){
    vec2 correctedUV = vec2(v_uv.x, 1.0 - v_uv.y);
    texColor = texture(envMap2D, correctedUV); 
  }

  if (texColor.a < 0.001) {
    discard;
  }

  texColor.rgb *= parms.y;
  frag_color = applyColor(texColor, 2);
}
