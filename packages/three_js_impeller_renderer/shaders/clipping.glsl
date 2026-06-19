bool evaluateClippingPlanes(vec3 worldPosition) {
  int numPlanes = int(material.flags0.x);
  if (numPlanes <= 0) return false;
      
  // Plane 0
  if (numPlanes > 0) {
    vec4 plane = material.clippingPlanes[0];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }
  // Plane 1
  if (numPlanes > 1) {
    vec4 plane = material.clippingPlanes[1];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }
  // Plane 2
  if (numPlanes > 2) {
    vec4 plane = material.clippingPlanes[2];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }
  // Plane 3
  if (numPlanes > 3) {
    vec4 plane = material.clippingPlanes[3];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }
  // Plane 4
  if (numPlanes > 4) {
    vec4 plane = material.clippingPlanes[4];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }
  // Plane 5
  if (numPlanes > 5) {
    vec4 plane = material.clippingPlanes[5];
    if (dot(worldPosition, plane.xyz) + plane.w < 0.0) return true;
  }

  return false;
}