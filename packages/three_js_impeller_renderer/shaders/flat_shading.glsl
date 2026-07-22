vec3 evaluateNormal(vec3 worldNormal, vec3 worldPosition) {
  vec3 N = normalize(worldNormal);
  float isFlatShadingActive = material.pbrParams.z;
  
  if (isFlatShadingActive > 0.5) {
    N = -normalize(cross(dFdx(worldPosition), dFdy(worldPosition)));
  }
  
  return N;
}

// vec3 evaluateNormal(vec3 worldNormal, vec3 worldPosition) {
//   float isFlatShadingActive = material.pbrParams.z; 
  
//   if (isFlatShadingActive > 0.5) {
//     vec3 dx = dFdx(worldPosition);
//     vec3 dy = dFdy(worldPosition);
//     vec3 N = normalize(cross(dx, dy));
//     return gl_FrontFacing ? N : -N;
//   }
  
//   return normalize(worldNormal);
// }
