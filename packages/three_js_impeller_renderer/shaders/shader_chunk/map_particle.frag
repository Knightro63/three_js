#version 460 core

// Bindings from Master List
layout(set = 0, binding = 4) uniform sampler2D map;      // Diffuse Map
layout(set = 0, binding = 2) uniform sampler2D alphaMap; // Alpha Map

layout(set = 0, binding = 1) uniform MaterialUniforms {
    mat3 uvTransform; // For rotating/scaling point textures
    // ... other uniforms
};

// Location 23: Reusing vUv lane for vertex-based particle UVs
layout(location = 23) in vec2 vUv;

/**
 * Converts mapParticleFragment logic.
 * Note: usePointsUv determines if we use vertex UVs or gl_PointCoord (sprites).
 */
void applyParticleMaps(inout vec4 diffuseColor, bool usePointsUv, bool useMap, bool useAlphaMap) {
    vec2 uv;

    if (usePointsUv) {
        uv = vUv;
    } else {
        // gl_PointCoord.y is flipped to match standard UV space
        uv = (uvTransform * vec3(gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1.0)).xy;
    }

    if (useMap) {
        diffuseColor *= texture(map, uv);
    }

    if (useAlphaMap) {
        // Reads .g channel for alpha as per your established logic
        diffuseColor.a *= texture(alphaMap, uv).g;
    }
}
