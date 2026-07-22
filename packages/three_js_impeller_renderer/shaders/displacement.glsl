layout(binding = 4) uniform sampler2D displacementMap;

vec4 getDisplacementPosition(vec4 position, vec3 normal, vec2 uv) {
  bool hasDisplacementMap = material.flags2.x > 0.5;
  if(!hasDisplacementMap){
    return position;
  }
  vec3 localPosition = position.xyz;
  float displacement = texture(displacementMap, uv).r;
  localPosition += normal * (displacement * material.displacementParams.x + material.displacementParams.y);

  return vec4(localPosition,1.0);
}