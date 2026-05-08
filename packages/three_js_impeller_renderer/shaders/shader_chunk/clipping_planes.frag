
// Binding 9: Dedicated block for clipping planes
// Using a fixed max size (e.g., 8) as GLSL 4.60 requires constant array sizes.
layout(set = 0, binding = 9) uniform ClippingUniforms {
    vec4 clippingPlanes[8]; 
    int numClippingPlanes;
    int unionClippingPlanes;
};

// Location 7: Position used for clipping math
layout(location = 7) in vec3 vClipPosition;

/**
 * Applies clipping logic. 
 * Note: ALPHA_TO_COVERAGE logic is integrated via the 'useAlphaToCoverage' toggle.
 */
void applyClipping(inout vec4 diffuseColor, bool useAlphaToCoverage) {
    if (numClippingPlanes <= 0) return;

    if (useAlphaToCoverage) {
        float clipOpacity = 1.0;

        // Union Planes
        for (int i = 0; i < unionClippingPlanes; i++) {
            vec4 plane = clippingPlanes[i];
            float distanceToPlane = -dot(vClipPosition, plane.xyz) + plane.w;
            float distanceGradient = fwidth(distanceToPlane) / 2.0;
            clipOpacity *= smoothstep(-distanceGradient, distanceGradient, distanceToPlane);
        }

        // Intersection Planes
        if (unionClippingPlanes < numClippingPlanes) {
            float intersectionOpacity = 1.0;
            for (int i = unionClippingPlanes; i < numClippingPlanes; i++) {
                vec4 plane = clippingPlanes[i];
                float distanceToPlane = -dot(vClipPosition, plane.xyz) + plane.w;
                float distanceGradient = fwidth(distanceToPlane) / 2.0;
                intersectionOpacity *= 1.0 - smoothstep(-distanceGradient, distanceGradient, distanceToPlane);
            }
            clipOpacity *= 1.0 - intersectionOpacity;
        }

        diffuseColor.a *= clipOpacity;
        if (diffuseColor.a <= 0.0) discard;

    } else {
        // Standard Hard Clipping
        for (int i = 0; i < unionClippingPlanes; i++) {
            vec4 plane = clippingPlanes[i];
            if (dot(vClipPosition, plane.xyz) > plane.w) discard;
        }

        if (unionClippingPlanes < numClippingPlanes) {
            bool clipped = true;
            for (int i = unionClippingPlanes; i < numClippingPlanes; i++) {
                vec4 plane = clippingPlanes[i];
                clipped = (dot(vClipPosition, plane.xyz) > plane.w) && clipped;
            }
            if (clipped) discard;
        }
    }
}
