// --- Cleaned up unpacking logic to match 0.0-1.0 texture spaces ---
vec2 unpackRGBATo2Half(vec4 v) { 
    return vec2(v.x + (v.y / 255.0), v.z + (v.w / 255.0)); 
}

vec4 calculateShadows(vec4 worldPosition, vec3 worldNormal) {
    vec3 combinedShadowFactor = vec3(1.0);
    int totalLights = min(int(scene.envParms.w), 16);
    
    for (int i = 0; i < totalLights; i++) {
        vec4 extParams = scene.lightExtendedParams[i];
        float castsShadow = extParams.w;
        
        if (castsShadow < 0.5) {
            continue;
        }
        
        float lightType = extParams.z; 
        float normalBias = extParams.x;
        float depthBias = extParams.y;
        
        // 1. Apply normal bias to eliminate shadow acne
        vec3 biasedWorldPos = worldPosition.xyz + (worldNormal * normalBias);
        
        // 2. Transform the position into light projection space
        vec4 lightSpacePos = scene.lightSpaceMatrices[i] * vec4(biasedWorldPos, 1.0);
        
        // 3. Perform perspective division to get normalized device coordinates
        vec3 projCoords = lightSpacePos.xyz / lightSpacePos.w;
        
        vec2 shadowUV = projCoords.xy * 0.5 + 0.5;
        float currentDepth = projCoords.z; 

        // Frustum clipping
        if (shadowUV.x < 0.0 || shadowUV.x > 1.0 || shadowUV.y < 0.0 || shadowUV.y > 1.0 || currentDepth > 1.0 || currentDepth < 0.0) {
            continue;
        }
        
        // 5. Sample the VSM texture map
        vec4 shadowSample = texture(shadow_pass, shadowUV);
        vec2 moments = unpackRGBATo2Half(shadowSample);
        float mean = moments.x;
        float std_dev = moments.y;
        
        // 6. Calculate shadow visibility factor using Chebyshev's Inequality
        float visibility = 1.0;
        if (currentDepth > mean + depthBias) {
            // Variance is std_dev squared
            float variance = std_dev * std_dev;
            variance = max(variance, 0.00002); // Guard against zero division
            
            float d = currentDepth - mean;
            float p_max = variance / (variance + d * d);
            
            // Standard light bleed reduction clamp
            visibility = clamp((p_max - 0.1) / 0.9, 0.0, 1.0);
        }
        
        combinedShadowFactor *= visibility;
    }
    
    return vec4(combinedShadowFactor, 1.0);
}
