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

void applyClippingPlanes(inout vec4 diffuseColor, vec3 worldPosition) {
  int numPlanes = int(material.cpp.x);
  int unionPlanes = int(material.cpp.y);
  bool useAlphaToCoverage = material.cpp.z > 0.5;

  if (numPlanes <= 0) return;

  if (useAlphaToCoverage) {
      float clipOpacity = 1.0;

    for (int i = 0; i < unionPlanes; i++) {
      vec4 plane = material.clippingPlanes[i];
      float distanceToPlane = -dot(worldPosition, plane.xyz) + plane.w;
      float distanceGradient = fwidth(distanceToPlane) / 2.0;
      clipOpacity *= smoothstep(-distanceGradient, distanceGradient, distanceToPlane);
    }

    if (unionPlanes < numPlanes) {
      float intersectionOpacity = 1.0;
      for (int i = unionPlanes; i < numPlanes; i++) {
        vec4 plane = material.clippingPlanes[i];
        float distanceToPlane = -dot(worldPosition, plane.xyz) + plane.w;
        float distanceGradient = fwidth(distanceToPlane) / 2.0;
        intersectionOpacity *= 1.0 - smoothstep(-distanceGradient, distanceGradient, distanceToPlane);
      }
      clipOpacity *= 1.0 - intersectionOpacity;
    }

    diffuseColor.a *= clipOpacity;
    if (diffuseColor.a <= 0.001) discard;

  } 
  else {
    for (int i = 0; i < unionPlanes; i++) {
      vec4 plane = material.clippingPlanes[i];
      float distanceToPlane = dot(worldPosition, plane.xyz) + plane.w;
      if (distanceToPlane < 0.0) {
        discard;
      }
    }

    // 4. Standard Intersection Hard Clipping
    if (unionPlanes < numPlanes) {
      bool clipped = true;
      for (int i = unionPlanes; i < numPlanes; i++) {
        vec4 plane = material.clippingPlanes[i];
        float distanceToPlane = dot(worldPosition, plane.xyz) + plane.w;
        clipped = (distanceToPlane < 0.0) && clipped;
      }
      if (clipped) discard;
    }
  }
}
