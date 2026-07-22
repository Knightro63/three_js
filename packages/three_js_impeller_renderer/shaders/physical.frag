#include <material_block.glsl>
#include <scene_block.glsl>
#include <light.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>
#include <standard.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D normalMap;
uniform sampler2D bumpMap;
uniform sampler2D ormMap;
uniform sampler2D lightMap;
uniform sampler2D emissiveMap;

uniform sampler2D clearcoatParamsMap;
uniform sampler2D clearcoatNormalMap;
uniform sampler2D advancedPhysicalMap;
uniform sampler2D iridescenceThicknessMap;
uniform sampler2D sheenColorMap;
uniform sampler2D sheenRoughnessMap;

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_worldNormal;
in vec2 v_uv;

out vec4 frag_color;

vec3 schlickFresnel(vec3 f0, float dotNV) {
    return f0 + (vec3(1.0) - f0) * pow(clamp(1.0 - dotNV, 0.0, 1.0), 5.0);
}

void main() {
    // 1. Evaluate clipping slices
    if (evaluateClippingPlanes(v_worldPosition)) {
        discard;
    }

    // 2. Resolve Material Configuration Bitmask Flags
    bool hasMap                = material.flags0.y > 0.5;
    bool hasAlphaMap           = material.flags0.z > 0.5;
    bool hasAoMap              = material.flags0.w > 0.5;
    bool hasLightMap           = material.flags1.y > 0.5;
    bool hasBumpMap            = material.flags1.z > 0.5;
    bool hasNormalMap          = material.flags1.w > 0.5;
    bool hasRoughnessMap       = material.flags2.y > 0.5;
    bool hasMetalnessMap       = material.flags2.z > 0.5;
    bool hasEmissiveMap        = material.flags2.w > 0.5;
    bool hasClearcoatMap       = material.flags3.x > 0.5;
    bool hasClearcoatNormalMap = material.flags3.y > 0.5;
    bool hasClearcoatRoughMap  = material.flags3.z > 0.5;
    bool hasSheenColorMap      = material.flags3.w > 0.5;
    bool hasSheenRoughMap      = material.flags4.x > 0.5;
    bool hasTransmissionMap    = material.flags4.y > 0.5;
    bool hasThicknessMap       = material.flags4.z > 0.5;
    bool hasIridescenceMap     = material.flags4.w > 0.5;
    bool hasIridescenceThick   = material.flags5.x > 0.5;

    // 3. Process Base Albedo and Opacity Channels
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
    if (alpha < material.pbrParams.w) {
        discard;
    }

    if (hasAoMap) {
        blendedAlbedo *= texture(ormMap, v_uv).r * material.mapIntensities.w;
    }
    if (hasLightMap) {
        blendedAlbedo += texture(lightMap, v_uv).rgb * material.mapIntensities.z;
    }

    vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb;
    // 4. Parse Base PBR parameters
    float roughnessFactor = material.pbrParams.x;
    if (hasRoughnessMap) {
        roughnessFactor *= texture(ormMap, v_uv).g;
    }
    float metalnessFactor = material.pbrParams.y;
    if (hasMetalnessMap) {
        metalnessFactor *= texture(ormMap, v_uv).b;
    }

    // Packed Physical Extension Coefficients
    vec4 ccSample = vec4(1.0);
    if (hasClearcoatMap || hasClearcoatRoughMap) {
        ccSample = texture(clearcoatParamsMap, v_uv);
    }
    float clearcoatFactor = material.physicalAdvancedParams.x;
    if (hasClearcoatMap) {
        clearcoatFactor *= ccSample.r;
    }
    float clearcoatRoughness = material.physicalAdvancedParams.y;
    if (hasClearcoatRoughMap) {
        clearcoatRoughness *= ccSample.g;
    }
    clearcoatRoughness = clamp(clearcoatRoughness, 0.04, 1.0);

    vec3 sheenColorFactor = material.sheenColorAndIntensity.rgb;
    if (hasSheenColorMap) {
        sheenColorFactor *= texture(sheenColorMap, v_uv).rgb;
    }
    float sheenRoughnessFactor = material.sheenColorAndIntensity.w;
    if (hasSheenRoughMap) {
        sheenRoughnessFactor *= texture(sheenRoughnessMap, v_uv).g;
    }

    vec4 advSample = vec4(1.0);
    if (hasTransmissionMap || hasThicknessMap || hasIridescenceMap) {
        advSample = texture(advancedPhysicalMap, v_uv);
    }
    float transmissionFactor = material.physicalAdvancedParams.z;
    if (hasTransmissionMap) {
        transmissionFactor *= advSample.r;
    }
    float thicknessFactor = material.physicalAdvancedParams.w;
    if (hasThicknessMap) {
        thicknessFactor *= advSample.g;
    }

    float iridescenceFactor = material.attenuationParms.w;
    if (hasIridescenceMap) {
        iridescenceFactor *= advSample.b;
    }
    float iridescenceIOR = material.lineParams.x;
    float iridescenceThickness = material.lineParams.y;
    if (hasIridescenceThick) {
        iridescenceThickness *= texture(iridescenceThicknessMap, v_uv).g;
    }

    // 5. Surface Normal Evaluations
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
    vec3 baseNormal = evaluateNormal(v_worldNormal, v_worldPosition);
    vec3 N = baseNormal;
    
    if (hasNormalMap) {
        vec3 normalMapSample = texture(normalMap, v_uv).xyz * 2.0 - 1.0;
        normalMapSample.xy *= material.mapIntensities.x;
        N = perturbNormalArb(v_worldPosition, N, normalMapSample.xy, faceDirection);
    } else if (hasBumpMap) {
        float bumpVal = texture(bumpMap, v_uv).r;
        vec2 dHdxy = vec2(dFdx(bumpVal), dFdy(bumpVal)) * material.mapIntensities.x;
        N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
    }

    vec3 clearcoatN = baseNormal;
    if (hasClearcoatNormalMap) {
        vec3 ccNormalSample = texture(clearcoatNormalMap, v_uv).xyz * 2.0 - 1.0;
        ccNormalSample.xy *= material.lineParams.z;
        clearcoatN = perturbNormalArb(v_worldPosition, clearcoatN, ccNormalSample.xy, faceDirection);
    }

    // 6. Fragment Vector Re-Normalization
    vec3 N_clean = normalize(N);
    vec3 V_clean = normalize(material.cameraPosition.xyz - v_worldPosition);
    vec3 clearcoatN_clean = normalize(clearcoatN);
    float dotNV = clamp(dot(N_clean, V_clean), 0.0, 1.0);
    float dotClearcoatNV = clamp(dot(clearcoatN_clean, V_clean), 0.0, 1.0);

    float ior = material.specularAndIOR.w;
    vec3 f0 = vec3(pow((ior - 1.0) / (ior + 1.0), 2.0));
    vec3 specularColorReflection = mix(f0 * material.specularAndIOR.rgb, linearAlbedo, metalnessFactor);

    if (iridescenceFactor > 0.05) {
        float eta2 = pow(iridescenceIOR, 2.0);
        float sinTheta2 = 1.0 - pow(dotNV, 2.0);
        float cosThetaT = sqrt(max(0.0, eta2 - sinTheta2));
        vec3 iridescenceFresnel = vec3(0.5) + 0.5 * cos(vec3(6.28318) * (iridescenceThickness * cosThetaT / 500.0));
        specularColorReflection = mix(specularColorReflection, iridescenceFresnel, iridescenceFactor);
    }

    // 7. Base Lighting Calculations
    vec3 baseLighting = calculateDynamicLighting(N_clean, V_clean, v_worldPosition, linearAlbedo, roughnessFactor, specularColorReflection);

    if (max(sheenColorFactor.r, max(sheenColorFactor.g, sheenColorFactor.b)) > 0.0) {
        float sheenFresnel = pow(1.0 - dotNV, 4.0);
        vec3 sheenLayer = sheenColorFactor * sheenFresnel * (1.0 - sheenRoughnessFactor);
        baseLighting += sheenLayer;
    }

    if (transmissionFactor > 0.0) {
        vec3 transmissionColor = material.attenuationParms.rgb;
        float attenuationDistance = material.attenuationParms.w;
        vec3 thicknessAttenuation = vec3(1.0);
        if (attenuationDistance > 0.0) {
            vec3 absorption = -log(max(transmissionColor, vec3(0.0001))) / attenuationDistance;
            thicknessAttenuation = exp(-absorption * thicknessFactor);
        }
        vec3 fresnelRefraction = schlickFresnel(specularColorReflection, dotNV);
        vec3 transmittedLight = linearAlbedo * thicknessAttenuation * (vec3(1.0) - fresnelRefraction);
        baseLighting = mix(baseLighting, baseLighting + transmittedLight, transmissionFactor * (1.0 - metalnessFactor));
    }

    if (hasEmissiveMap) {
        vec3 emissiveSample = texture(emissiveMap, v_uv).rgb;
        baseLighting += material.emissiveColor.rgb * emissiveSample * material.materialParams.w;
    }

    if (clearcoatFactor > 0.0) {
        float clearcoatF0 = 0.04;
        float clearcoatFresnel = clearcoatF0 + (1.0 - clearcoatF0) * pow(1.0 - dotClearcoatNV, 5.0);
        float safeRoughness = max(clearcoatRoughness, 0.04);
        vec3 clearcoatSpecular = vec3(pow(dotClearcoatNV, 1.0 / safeRoughness));
        clearcoatSpecular = clamp(clearcoatSpecular, vec3(0.0), vec3(5.0));
        float factor = clearcoatFactor * clearcoatFresnel;
        baseLighting = baseLighting * vec3(1.0 - factor) + (clearcoatSpecular * factor);
    }

    baseLighting = applyFog(baseLighting, v_worldPosition);
    vec4 finalRGBA = vec4(baseLighting, alpha);
    finalRGBA = applyColor(finalRGBA, scene.rendParms.z);

    frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
