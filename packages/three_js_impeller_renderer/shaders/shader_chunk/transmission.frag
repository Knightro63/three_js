#version 460 core

// Bindings - Sequential after SpecularMap (54)
layout(set = 0, binding = 55) uniform sampler2D transmissionMap;
layout(set = 0, binding = 56) uniform sampler2D thicknessMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float transmission;
    float thickness;
    float attenuationDistance;
    vec3 attenuationColor;
    float ior;
    float dispersion;
};

layout(set = 0, binding = 0) uniform FrameUniforms {
    vec3 cameraPosition;
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
};

// Updated Locations per Master List sequence
layout(location = 42) in vec2 vTransmissionMapUv; // Sequential after vSpecularMapUv (41)
layout(location = 43) in vec2 vThicknessMapUv;

/**
 * Converts transmissionFragment logic.
 * Note: Requires getIBLVolumeRefraction from transmission_pars.frag.
 */
void applyTransmission(
    inout vec3 totalDiffuse, 
    inout PhysicalMaterial material, 
    vec3 normal, 
    vec3 vWorldPosition,
    bool useTransmissionMap,
    bool useThicknessMap
) {
    material.transmission = transmission;
    material.transmissionAlpha = 1.0;
    material.thickness = thickness;
    material.attenuationDistance = attenuationDistance;
    material.attenuationColor = attenuationColor;

    if (useTransmissionMap) {
        material.transmission *= texture(transmissionMap, vTransmissionMapUv).r;
    }

    if (useThicknessMap) {
        material.thickness *= texture(thicknessMap, vThicknessMapUv).g;
    }

    vec3 pos = vWorldPosition;
    vec3 v = normalize(cameraPosition - pos);
    vec3 n = inverseTransformDirection(normal, viewMatrix);

    // Complex IBL Refraction call
    vec4 transmitted = getIBLVolumeRefraction(
        n, v, material.roughness, material.diffuseColor, material.specularColor, 
        material.specularF90, pos, modelMatrix, viewMatrix, projectionMatrix, 
        dispersion, ior, material.thickness, material.attenuationColor, material.attenuationDistance
    );

    material.transmissionAlpha = mix(material.transmissionAlpha, transmitted.a, material.transmission);
    totalDiffuse = mix(totalDiffuse, transmitted.rgb, material.transmission);
}
