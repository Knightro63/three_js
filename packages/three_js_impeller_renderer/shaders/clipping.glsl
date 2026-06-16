bool evaluateClippingPlanes(vec3 worldPosition) {
    int numPlanes = int(material.flags0.x);
    
    for (int i = 0; i < numPlanes; i++) {
        vec4 plane = material.clippingPlanes[i];
        float distanceToPlane = dot(worldPosition, plane.xyz) + plane.w;
        
        if (distanceToPlane < 0.0) {
            return true;
        }
    }

    return false;
}
