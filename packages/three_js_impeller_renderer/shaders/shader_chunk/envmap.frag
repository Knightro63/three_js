
// Binding 10: From master list
layout(set = 0, binding = 10) uniform sampler2D envMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    float envMapIntensity;
    float flipEnvMap;
    mat3 envMapRotation;
    float refractionRatio;
    float reflectivity;
    float specularStrength;
};

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
    vec3 cameraPosition;
    bool isOrthographic;
};

// Location 10: World position for reflection math
layout(location = 10) in vec3 vWorldPosition;
// Location 11: Pre-calculated reflection vector (optional)
layout(location = 11) in vec3 vReflect;

/**
 * Converts envmapFragment logic.
 * Calculates reflections/refractions and blends with outgoingLight.
 */
void applyEnvMap(
    vec3 normal, 
    inout vec3 outgoingLight, 
    bool useWorldPos, 
    bool isReflection,
    int blendingMode // 0: MULTIPLY, 1: MIX, 2: ADD
) {
    vec3 reflectVec;

    if (useWorldPos) {
        vec3 cameraToFrag;
        if (isOrthographic) {
            // Extracts view direction from the view matrix
            cameraToFrag = normalize(vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
        } else {
            cameraToFrag = normalize(vWorldPosition - cameraPosition);
        }

        // Uses utility from common.frag
        vec3 worldNormal = inverseTransformDirection(normal, viewMatrix);

        if (isReflection) {
            reflectVec = reflect(cameraToFrag, worldNormal);
        } else {
            reflectVec = refract(cameraToFrag, worldNormal, refractionRatio);
        }
    } else {
        reflectVec = vReflect;
    }

    // Apply rotation and flip
    vec3 sampleDir = envMapRotation * vec3(flipEnvMap * reflectVec.x, reflectVec.yz);
    
    // Note: Assuming Equirectangular sampler2D logic for envMap
    // If using CubeUV, call textureCubeUV() from our previously converted file.
    vec4 envColor = texture(envMap, equirectUv(normalize(sampleDir)));
    envColor.rgb *= envMapIntensity;

    float factor = specularStrength * reflectivity;

    if (blendingMode == 0) { // MULTIPLY
        outgoingLight = mix(outgoingLight, outgoingLight * envColor.xyz, factor);
    } else if (blendingMode == 1) { // MIX
        outgoingLight = mix(outgoingLight, envColor.xyz, factor);
    } else if (blendingMode == 2) { // ADD
        outgoingLight += envColor.xyz * factor;
    }
}
