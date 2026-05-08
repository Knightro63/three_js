
// Binding 6: Dedicated sampler for the Bump (Height) map.
layout(set = 0, binding = 5) uniform sampler2D bumpMap;

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... other uniforms
    float bumpScale;
};

// Inputs from vertex shader
layout(location = 0) in vec3 vPosition;   // For surf_pos
layout(location = 5) in vec2 vBumpMapUv; // Changed to Location 3 to avoid clashing with Alpha/AO UVs

/**
 * Evaluate the derivative of the height w.r.t. screen-space using forward differencing.
 * Morten S. Mikkelsen: https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf
 */
vec2 dHdxy_fwd() {
    vec2 dSTdx = dFdx(vBumpMapUv);
    vec2 dSTdy = dFdy(vBumpMapUv);

    float Hll = bumpScale * texture(bumpMap, vBumpMapUv).x;
    float dBx = bumpScale * texture(bumpMap, vBumpMapUv + dSTdx).x - Hll;
    float dBy = bumpScale * texture(bumpMap, vBumpMapUv + dSTdy).x - Hll;

    return vec2(dBx, dBy);
}

/**
 * Perturb the normal based on the height derivative.
 */
vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) {
    vec3 vSigmaX = normalize(dFdx(surf_pos));
    vec3 vSigmaY = normalize(dFdy(surf_pos));
    vec3 vN = surf_norm; // assumed normalized

    vec3 R1 = cross(vSigmaY, vN);
    vec3 R2 = cross(vN, vSigmaX);

    float fDet = dot(vSigmaX, R1) * faceDirection;

    vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
    return normalize(abs(fDet) * surf_norm - vGrad);
}
