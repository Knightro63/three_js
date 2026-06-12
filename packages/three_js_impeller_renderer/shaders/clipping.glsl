void evaluateClippingPlanes(vec3 worldPosition) {
    // Extract the number of active planes from your uniforms block layout
    int numPlanes = int(material.clippingPlaneParams.x);
    
    for (int i = 0; i < numPlanes; i++) {
        // Look up the specific plane equation vector array
        vec4 plane = material.clippingPlanes[i];
        
        // THE CLIPPING MATHEMATICS:
        // Calculate the dot product of the pixel's position and the plane normal, plus the constant.
        // Signed Distance = (Pos.x * N.x) + (Pos.y * N.y) + (Pos.z * N.z) + Constant
        float distanceToPlane = dot(worldPosition, plane.xyz) + plane.w;
        
        // If the distance is less than 0.0, the pixel resides on the clipped side of the plane!
        if (distanceToPlane < 0.0) {
            // Discard completely stops processing, preventing color or depth writes!
            discard;
        }
    }
}
