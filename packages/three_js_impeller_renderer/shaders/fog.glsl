vec3 applyFog(vec3 baseColor, vec3 worldPos) {
    // If fogParams.x is <= 0.0, fog is disabled for this object
    if (scene.fogParams.x <= 0.0) {
        return baseColor;
    }

    // 1. Calculate absolute distance from camera in World Space
    float vFogDepth = distance(scene.cameraPosition.xyz, worldPos);
    float fogFactor = 0.0;
    
    float fogNear = scene.fogParams.x;
    float fogFar = scene.fogParams.y;
    float fogDensity = scene.fogParams.z;
    float isFogExp2 = scene.fogParams.w; // 1.0 = Exp2 mode, 0.0 = Linear mode

    if (isFogExp2 > 0.5) {
        // Match GLSL: 1.0 - exp( - density * density * depth * depth )
        float d = fogDensity * vFogDepth;
        fogFactor = 1.0 - exp(-d * d);
    } else {
        // Native GLSL optimized smoothstep(fogNear, fogFar, vFogDepth)
        fogFactor = smoothstep(fogNear, fogFar, vFogDepth);
    }

    // Smoothly blend the base canvas color into your background color channel
    return mix(baseColor, scene.fogColor.rgb, fogFactor);
}
