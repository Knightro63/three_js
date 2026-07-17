// Arbitrary surface normal perturbation calculation block 
vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) { 
  vec3 vSigmaX = dFdx(surf_pos); 
  vec3 vSigmaY = dFdy(surf_pos); 
  vec3 vN = surf_norm; 
  vec3 R1 = cross(vSigmaY, vN); 
  vec3 R2 = cross(vN, vSigmaX); 
  float fDet = dot(vSigmaX, R1); 
  fDet *= faceDirection; 
  vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2); 
  return normalize(abs(fDet) * vN - vGrad); 
} 