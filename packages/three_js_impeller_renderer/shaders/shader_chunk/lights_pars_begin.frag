#version 460 core

/**
 * Common Lighting Parameters and Structures
 * Note: Requires FrameUniforms (Binding 0) and common.frag
 */

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
    vec3 ambientLightColor;
    bool receiveShadow;
};

// --- Structures ---

struct PointLight {
    vec3 position;
    vec3 color;
    float distance;
    float decay;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float distance;
    float decay;
    float coneCos;
    float penumbraCos;
};

struct DirectionalLight {
    vec3 direction;
    vec3 color;
};

struct HemisphereLight {
    vec3 direction;
    vec3 skyColor;
    vec3 groundColor;
};

// --- Uniforms ---
// Note: Using fixed sizes for arrays as Flutter GPU requires static allocation.
layout(set = 0, binding = 18) uniform LightProbeUniforms {
    vec3 uLightProbe[9];
};

layout(set = 0, binding = 19) uniform LightBlock {
    DirectionalLight directionalLights[4];
    PointLight pointLights[8];
    SpotLight spotLights[8];
    HemisphereLight hemisphereLights[4];
    int uNumDirectionalLights;
    int uNumPointLights;
    int uNumSpotLights;
    int uNumHemiLights;
};

// --- Math Functions ---

vec3 shGetIrradianceAt(in vec3 normal, in vec3 shCoefficients[9]) {
    float x = normal.x, y = normal.y, z = normal.z;
    vec3 result = shCoefficients[0] * 0.886227;
    result += shCoefficients[1] * 2.0 * 0.511664 * y;
    result += shCoefficients[2] * 2.0 * 0.511664 * z;
    result += shCoefficients[3] * 2.0 * 0.511664 * x;
    result += shCoefficients[4] * 2.0 * 0.429043 * x * y;
    result += shCoefficients[5] * 2.0 * 0.429043 * y * z;
    result += shCoefficients[6] * (0.743125 * z * z - 0.247708);
    result += shCoefficients[7] * 2.0 * 0.429043 * x * z;
    result += shCoefficients[8] * 0.429043 * (x * x - y * y);
    return result;
}

vec3 getLightProbeIrradiance(const in vec3 lightProbe[9], const in vec3 normal) {
    vec3 worldNormal = inverseTransformDirection(normal, viewMatrix);
    return shGetIrradianceAt(worldNormal, lightProbe);
}

vec3 getAmbientLightIrradiance(const in vec3 ambientColor) {
    return ambientColor;
}

float getDistanceAttenuation(const in float lightDist, const in float cutoff, const in float decay) {
    float distanceFalloff = 1.0 / max(pow(lightDist, decay), 0.01);
    if (cutoff > 0.0) {
        distanceFalloff *= pow2(saturate(1.0 - pow4(lightDist / cutoff)));
    }
    return distanceFalloff;
}

float getSpotAttenuation(const in float coneCos, const in float penumbraCos, const in float angleCos) {
    return smoothstep(coneCos, penumbraCos, angleCos);
}

// --- Light Info Helpers ---

void getDirectionalLightInfo(const in DirectionalLight directionalLight, out IncidentLight light) {
    light.color = directionalLight.color;
    light.direction = directionalLight.direction;
    light.visible = true;
}

void getPointLightInfo(const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light) {
    vec3 lVector = pointLight.position - geometryPosition;
    light.direction = normalize(lVector);
    float lightDistance = length(lVector);
    light.color = pointLight.color;
    light.color *= getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay);
    light.visible = (light.color != vec3(0.0));
}

void getSpotLightInfo(const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light) {
    vec3 lVector = spotLight.position - geometryPosition;
    light.direction = normalize(lVector);
    float angleCos = dot(light.direction, spotLight.direction);
    float spotAtten = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);
    
    if (spotAtten > 0.0) {
        float lightDistance = length(lVector);
        light.color = spotLight.color * spotAtten;
        light.color *= getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay);
        light.visible = (light.color != vec3(0.0));
    } else {
        light.color = vec3(0.0);
        light.visible = false;
    }
}

vec3 getHemisphereLightIrradiance(const in HemisphereLight hemiLight, const in vec3 normal) {
    float dotNL = dot(normal, hemiLight.direction);
    float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
    return mix(hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight);
}
