
/**
 * Normal Map Parameters and Procedural Tangent Utility.
 * Requires normalMap at Binding 27.
 */

// Binding 27: Dedicated sampler for Normal Map
layout(set = 0, binding = 27) uniform sampler2D normalMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    vec2 normalScale;
};

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat3 normalMatrix; // Used for Object Space normals
};

/**
 * Normal Mapping Without Precomputed Tangents
 * http://www.thetenthplanet.de/archives/1180
 */
mat3 getTangentFrame(vec3 eye_pos, vec3 surf_norm, vec2 uv) {
    vec3 q0 = dFdx(eye_pos);
    vec3 q1 = dFdy(eye_pos);
    vec2 st0 = dFdx(uv);
    vec2 st1 = dFdy(uv);

    vec3 N = surf_norm; // assumed normalized

    vec3 q1perp = cross(q1, N);
    vec3 q0perp = cross(N, q0);

    vec3 T = q1perp * st0.x + q0perp * st1.x;
    vec3 B = q1perp * st0.y + q0perp * st1.y;

    float det = max(dot(T, T), dot(B, B));
    float scale = (det == 0.0) ? 0.0 : inversesqrt(det);

    return mat3(T * scale, B * scale, N);
}
