
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    vec3 fogColor;
    float fogDensity;
    float fogNear;
    float fogFar;
};

// Location 12: Interpolated depth from vertex shader
layout(location = 12) in float vFogDepth;

// Final output color
layout(location = 0) out vec4 fragColor;

/**
 * Converts fogFragment logic.
 * Note: useExp2 determines if we use Exponential squared or Linear fog.
 */
void applyFog(bool useExp2) {
    float fogFactor = 0.0;

    if (useExp2) {
        // FOG_EXP2
        fogFactor = 1.0 - exp(-fogDensity * fogDensity * vFogDepth * vFogDepth);
    } else {
        // Linear Fog
        fogFactor = smoothstep(fogNear, fogFar, vFogDepth);
    }

    // Mix the RGB, preserving current fragment alpha
    fragColor.rgb = mix(fragColor.rgb, fogColor, fogFactor);
}
