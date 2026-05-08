
/**
 * Note: Requires packing.frag for unpackRGBAToDepth and unpackRGBATo2Half.
 */

// Bindings 29-31: Shadow Map Samplers
// Bindings and Locations now perfectly aligned in blocks of 4
layout(set = 0, binding = 29) uniform sampler2D directionalShadowMap[4];
layout(location = 29) in vec4 vDirectionalShadowCoord[4];

layout(set = 0, binding = 33) uniform sampler2D spotShadowMap[4];
layout(location = 33) in vec4 vSpotLightCoord[4];

layout(set = 0, binding = 37) uniform sampler2D pointShadowMap[4];
layout(location = 37) in vec4 vPointShadowCoord[4];

// Shadow Parameters (typically in a dedicated UBO or MaterialUniforms)
struct DirectionalLightShadow {
    float shadowBias;
    float shadowNormalBias;
    float shadowRadius;
    vec2 shadowMapSize;
};

float texture2DCompare(sampler2D depths, vec2 uv, float compare) {
    return step(compare, unpackRGBAToDepth(texture(depths, uv)));
}

vec2 texture2DDistribution(sampler2D shadow, vec2 uv) {
    return unpackRGBATo2Half(texture(shadow, uv));
}

float VSMShadow(sampler2D shadow, vec2 uv, float compare) {
    float occlusion = 1.0;
    vec2 distribution = texture2DDistribution(shadow, uv);
    float hard_shadow = step(compare, distribution.x);
    if (hard_shadow != 1.0) {
        float dist = compare - distribution.x;
        float variance = max(0.00001, distribution.y * distribution.y);
        float softness_probability = variance / (variance + dist * dist);
        softness_probability = clamp((softness_probability - 0.3) / (0.95 - 0.3), 0.0, 1.0);
        occlusion = clamp(max(hard_shadow, softness_probability), 0.0, 1.0);
    }
    return occlusion;
}

float getShadow(sampler2D shadowMap, vec2 shadowMapSize, float shadowBias, float shadowRadius, vec4 shadowCoord, int shadowType) {
    float shadow = 1.0;
    vec3 projCoord = shadowCoord.xyz / shadowCoord.w;
    projCoord.z += shadowBias;

    bool inFrustum = all(greaterThanEqual(projCoord.xy, vec2(0.0))) && all(lessThanEqual(projCoord.xy, vec2(1.0)));
    if (inFrustum && projCoord.z <= 1.0) {
        if (shadowType == 1) { // PCF
            // ... PCF sampling logic ...
        } else if (shadowType == 2) { // VSM
            shadow = VSMShadow(shadowMap, projCoord.xy, projCoord.z);
        } else {
            shadow = texture2DCompare(shadowMap, projCoord.xy, projCoord.z);
        }
    }
    return shadow;
}

// Maps 3D direction to 2D UV for point light shadow atlases
vec2 cubeToUV(vec3 v, float texelSizeY) {
    vec3 absV = abs(v);
    float scaleToCube = 1.0 / max(absV.x, max(absV.y, absV.z));
    absV *= scaleToCube;
    v *= scaleToCube * (1.0 - 2.0 * texelSizeY);
    vec2 planar = v.xy;
    float almostOne = 1.0 - 1.5 * texelSizeY;
    if (absV.z >= almostOne) {
        if (v.z > 0.0) planar.x = 4.0 - v.x;
    } else if (absV.x >= almostOne) {
        float signX = sign(v.x);
        planar.x = v.z * signX + 2.0 * signX;
    } else if (absV.y >= almostOne) {
        float signY = sign(v.y);
        planar.x = v.x + 2.0 * signY + 2.0;
        planar.y = v.z * signY - 2.0;
    }
    return vec2(0.125, 0.25) * planar + vec2(0.375, 0.75);
}

float getPointShadow(sampler2D shadowMap, vec2 shadowMapSize, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowNear, float shadowFar) {
    vec3 lightToPos = shadowCoord.xyz;
    float dist = length(lightToPos);
    if (dist <= shadowFar && dist >= shadowNear) {
        float dp = (dist - shadowNear) / (shadowFar - shadowNear) + shadowBias;
        vec3 bd3D = normalize(lightToPos);
        vec2 texelSize = vec2(1.0) / (shadowMapSize * vec2(4.0, 2.0));
        return texture2DCompare(shadowMap, cubeToUV(bd3D, texelSize.y), dp);
    }
    return 1.0;
}
