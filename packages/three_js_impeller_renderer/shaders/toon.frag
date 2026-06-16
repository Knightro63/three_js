#include <common.glsl>
#include <light.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D normalMap;
uniform sampler2D bumpMap;
uniform sampler2D gradientMap; // Map used by toon materials to drive cell step lookup profiles

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_worldNormal;
in vec2 v_uv;

out vec4 frag_color;

vec2 dXgrad(vec2 texUV) {
  return vec2(dFdx(texUV.x), dFdy(texUV.x));
}

vec2 dYgrad(vec2 texUV) {
  return vec2(dFdx(texUV.y), dFdy(texUV.y));
}

vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) {
    vec3 vSigmaX = dFdx(surf_pos);
    vec3 vSigmaY = dFdy(surf_pos);
    vec3 vN = surf_norm;
    vec3 R1 = cross(vSigmaY, vN);
    vec3 R2 = cross(vN, vSigmaX);
    float fDet = dot(vSigmaX, R1);
    fDet *= faceDirection;
    vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
    return normalize(abs(fDet) * vN - vGrad);
}

void main() {
    evaluateClippingPlanes(v_worldPosition);
    
    bool hasMap         = material.flags0.y > 0.5;
    bool hasAlphaMap    = material.flags0.z > 0.5;
    bool hasNormalMap   = material.flags0.x > 0.5;
    bool hasBumpMap     = material.flags1.z > 0.5;
    bool hasGradientMap = material.flags5.y > 0.5; // Index 113 matching Float32List

    vec4 texelColor = vec4(1.0);
    float alphaOverride = material.baseColor.a;

    if (hasMap) {
        texelColor = texture(map, v_uv);
        alphaOverride = material.baseColor.a * texelColor.a;
    }

    vec3 blendedAlbedo = v_color * texelColor.rgb;

    float alpha = alphaOverride;
    if (hasAlphaMap) {
        alpha *= texture(alphaMap, v_uv).g;
    }

    vec3 N = evaluateNormal(v_worldNormal, v_worldPosition);

    if (hasNormalMap) {
        vec3 normalMapSample = texture(normalMap, v_uv).xyz * 2.0 - 1.0;
        normalMapSample.xy *= material.mapIntensities.w;
        vec2 dHdxy = normalMapSample.xy;
        float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
        N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
    } else if (hasBumpMap) {
        float bumpSample = texture(bumpMap, v_uv).r;
        vec2 dHdxy = vec2(dFdx(bumpSample), dFdy(bumpSample)) * material.mapIntensities.x;
        float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
        N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
    }

    vec3 V = normalize(scene.cameraPosition.xyz - v_worldPosition);

    vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb;

    // Calculate light accumulation via unified multi-light loop array
    vec3 litLighting = calculateDynamicLighting(N, V, v_worldPosition, linearAlbedo, 0.0, vec3(0.0));

    // Cell Shading step quantization block
    if (hasGradientMap) {
        // Fallback or custom curve mapping via the step ramp texture asset
        float NdotL = clamp(dot(N, V), 0.0, 1.0); // Simple light wrap factor estimation
        vec3 gradientFactor = texture(gradientMap, vec2(NdotL, 0.5)).rgb;
        litLighting *= gradientFactor;
    } else {
        // Procedural step fallback logic matching your source parameters block
        float steps = material.pbrParams.y; // Track cartoon levels slider from Dart
        if (steps < 2.0) {
            steps = 3.0;
        }
        litLighting = floor(litLighting * steps) / (steps - 1.0);
    }

    vec3 finalColor = applyFog(litLighting, v_worldPosition);
    vec4 finalRGBA = vec4(finalColor, alpha);

    // Isolate alpha from color grading profile checks to prevent precision shelves artifacts
    finalRGBA = applyColor(finalRGBA);

    frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
