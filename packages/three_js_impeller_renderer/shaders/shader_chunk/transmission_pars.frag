#version 460 core

/**
 * Binding 57: The Transmission Sampler Map (usually a copy of the framebuffer).
 * Binding 1: MaterialUniforms - contains transmission constants and sampler size.
 * Binding 0: FrameUniforms - contains projection and model matrices.
 */
layout(set = 0, binding = 57) uniform sampler2D transmissionSamplerMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    vec2 transmissionSamplerSize;
};

// Location 10: Interpolated world position (as per master list)
layout(location = 10) in vec3 vWorldPosition;

// --- Mipped Bicubic Texture Filtering ---
// Ref: https://www.shadertoy.com/view/Dl2SDW

float w0(float a) { return (1.0 / 6.0) * (a * (a * (-a + 3.0) - 3.0) + 1.0); }
float w1(float a) { return (1.0 / 6.0) * (a * a * (3.0 * a - 6.0) + 4.0); }
float w2(float a) { return (1.0 / 6.0) * (a * (a * (-3.0 * a + 3.0) + 3.0) + 1.0); }
float w3(float a) { return (1.0 / 6.0) * (a * a * a); }

float g0(float a) { return w0(a) + w1(a); }
float g1(float a) { return w2(a) + w3(a); }
float h0(float a) { return -1.0 + w1(a) / (w0(a) + w1(a)); }
float h1(float a) { return 1.0 + w3(a) / (w2(a) + w3(a)); }

vec4 bicubic(sampler2D tex, vec2 uv, vec4 texelSize, float lod) {
    uv = uv * texelSize.zw + 0.5;
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);
    float g0x = g0(fuv.x); float g1x = g1(fuv.x);
    float h0x = h0(fuv.x); float h1x = h1(fuv.x);
    float h0y = h0(fuv.y); float h1y = h1(fuv.y);
    vec2 p0 = (vec2(iuv.x + h0x, iuv.y + h0y) - 0.5) * texelSize.xy;
    vec2 p1 = (vec2(iuv.x + h1x, iuv.y + h0y) - 0.5) * texelSize.xy;
    vec2 p2 = (vec2(iuv.x + h0x, iuv.y + h1y) - 0.5) * texelSize.xy;
    vec2 p3 = (vec2(iuv.x + h1x, iuv.y + h1y) - 0.5) * texelSize.xy;
    return g0(fuv.y) * (g0x * textureLod(tex, p0, lod) + g1x * textureLod(tex, p1, lod)) +
           g1(fuv.y) * (g0x * textureLod(tex, p2, lod) + g1x * textureLod(tex, p3, lod));
}

vec4 textureBicubic(sampler2D sampler, vec2 uv, float lod) {
    vec2 fLodSize = vec2(textureSize(sampler, int(lod)));
    vec2 cLodSize = vec2(textureSize(sampler, int(lod + 1.0)));
    vec4 fSample = bicubic(sampler, uv, vec4(1.0 / fLodSize, fLodSize), floor(lod));
    vec4 cSample = bicubic(sampler, uv, vec4(1.0 / cLodSize, cLodSize), ceil(lod));
    return mix(fSample, cSample, fract(lod));
}

// --- Volume Math ---

vec3 getVolumeTransmissionRay(const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix) {
    vec3 refractionVector = refract(-v, normalize(n), 1.0 / ior);
    vec3 modelScale = vec3(length(modelMatrix[0].xyz), length(modelMatrix[1].xyz), length(modelMatrix[2].xyz));
    return normalize(refractionVector) * thickness * modelScale;
}

float applyIorToRoughness(const in float roughness, const in float ior) {
    return roughness * clamp(ior * 2.0 - 2.0, 0.0, 1.0);
}

vec3 volumeAttenuation(const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance) {
    if (isinf(attenuationDistance)) return vec3(1.0);
    vec3 attenuationCoefficient = -log(attenuationColor) / attenuationDistance;
    return exp(-attenuationCoefficient * transmissionDistance);
}

vec4 getIBLVolumeRefraction(const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor, const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix, const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness, const in vec3 attenuationColor, const in float attenuationDistance) {
    vec4 transmittedLight = vec4(0.0);
    vec3 transmittance = vec3(0.0);

    float halfSpread = (ior - 1.0) * 0.025 * dispersion;
    vec3 iors = vec3(ior - halfSpread, ior, ior + halfSpread);

    // dispersion loop (R, G, B channels shifted by IOR)
    for (int i = 0; i < 3; i++) {
        vec3 transmissionRay = getVolumeTransmissionRay(n, v, thickness, iors[i], modelMatrix);
        vec3 refractedRayExit = position + transmissionRay;
        vec4 ndcPos = projMatrix * viewMatrix * vec4(refractedRayExit, 1.0);
        vec2 refractionCoords = (ndcPos.xy / ndcPos.w) * 0.5 + 0.5;
        
        float lod = log2(transmissionSamplerSize.x) * applyIorToRoughness(roughness, iors[i]);
        vec4 transmissionSample = textureBicubic(transmissionSamplerMap, refractionCoords, lod);
        
        transmittedLight[i] = transmissionSample[i];
        transmittedLight.a += transmissionSample.a;
        transmittance[i] = diffuseColor[i] * volumeAttenuation(length(transmissionRay), attenuationColor, attenuationDistance)[i];
    }
    transmittedLight.a /= 3.0;

    vec3 attenuatedColor = transmittance * transmittedLight.rgb;
    vec3 F = EnvironmentBRDF(n, v, specularColor, specularF90, roughness);
    float transmittanceFactor = dot(transmittance, vec3(0.3333));
    
    return vec4((1.0 - F) * attenuatedColor, 1.0 - (1.0 - transmittedLight.a) * transmittanceFactor);
}
