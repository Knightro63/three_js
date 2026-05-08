
/**
 * PhysicalMaterial struct and core PBR math (Part 1).
 * Requires common.frag for pow2() and EPSILON.
 */

struct PhysicalMaterial {
    vec3 diffuseColor;
    float roughness;
    vec3 specularColor;
    float specularF90;
    float dispersion;

    // Clearcoat
    float clearcoat;
    float clearcoatRoughness;
    vec3 clearcoatF0;
    float clearcoatF90;

    // Iridescence
    float iridescence;
    float iridescenceIOR;
    float iridescenceThickness;
    vec3 iridescenceFresnel;
    vec3 iridescenceF0;

    // Sheen
    vec3 sheenColor;
    float sheenRoughness;

    // IOR
    float ior;

    // Transmission
    float transmission;
    float transmissionAlpha;
    float thickness;
    float attenuationDistance;
    vec3 attenuationColor;

    // Anisotropy
    float anisotropy;
    float alphaT;
    vec3 anisotropyT;
    vec3 anisotropyB;
};

// Global accumulators for multi-layer lighting
vec3 clearcoatSpecularDirect = vec3(0.0);
vec3 clearcoatSpecularIndirect = vec3(0.0);
vec3 sheenSpecularDirect = vec3(0.0);
vec3 sheenSpecularIndirect = vec3(0.0);

/**
 * Reverses the Schlick approximation to find F0.
 */
vec3 Schlick_to_F0(const in vec3 f, const in float f90, const in float dotVH) {
    float x = clamp(1.0 - dotVH, 0.0, 1.0);
    float x2 = x * x;
    float x5 = clamp(x * x2 * x2, 0.0, 0.9999);
    return (f - vec3(f90) * x5) / (1.0 - x5);
}

/**
 * Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
 * https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
 */
float V_GGX_SmithCorrelated(const in float alpha, const in float dotNL, const in float dotNV) {
    float a2 = pow2(alpha);
    float gv = dotNL * sqrt(a2 + (1.0 - a2) * pow2(dotNV));
    float gl = dotNV * sqrt(a2 + (1.0 - a2) * pow2(dotNL));
    return 0.5 / max(gv + gl, EPSILON);
}

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
float D_GGX(const in float alpha, const in float dotNH) {
    float a2 = pow2(alpha);
    float denom = pow2(dotNH) * (a2 - 1.0) + 1.0; 
    // avoid alpha = 0 with dotNH = 1
    return RECIPROCAL_PI * a2 / pow2(denom);
}

// https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf
float V_GGX_SmithCorrelated_Anisotropic(
    const in float alphaT, const in float alphaB, 
    const in float dotTV, const in float dotBV, 
    const in float dotTL, const in float dotBL, 
    const in float dotNV, const in float dotNL
) {
    float gv = dotNL * length(vec3(alphaT * dotTV, alphaB * dotBV, dotNV));
    float gl = dotNV * length(vec3(alphaT * dotTL, alphaB * dotBL, dotNL));
    float v = 0.5 / (gv + gl);
    return saturate(v);
}

float D_GGX_Anisotropic(
    const in float alphaT, const in float alphaB, 
    const in float dotNH, const in float dotTH, const in float dotBH
) {
    float a2 = alphaT * alphaB;
    highp vec3 v = vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
    highp float v2 = dot(v, v);
    float w2 = a2 / v2;
    return RECIPROCAL_PI * a2 * pow2(w2);
}

/**
 * GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
 */
vec3 BRDF_GGX_Clearcoat(
    const in vec3 lightDir, 
    const in vec3 viewDir, 
    const in vec3 normal, 
    const in PhysicalMaterial material
) {
    vec3 f0 = material.clearcoatF0;
    float f90 = material.clearcoatF90;
    float roughness = material.clearcoatRoughness;
    float alpha = pow2(roughness); // Disney/UE4 reparameterization

    vec3 halfDir = normalize(lightDir + viewDir);
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, halfDir));
    float dotVH = saturate(dot(viewDir, halfDir));

    vec3 F = F_Schlick(f0, f90, dotVH);
    float V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);
    float D = D_GGX(alpha, dotNH);

    return F * (V * D);
}



/**
 * Physical Direct Lighting and Area Lights (Part 5).
 * Requires LTC_Uv, LTC_Evaluate, and BRDF functions from previous parts.
 */

// Bindings 22 & 23: LTC Look-Up Tables for Area Lights
layout(set = 0, binding = 22) uniform sampler2D ltc_1;
layout(set = 0, binding = 23) uniform sampler2D ltc_2;

void RE_Direct_RectArea_Physical(
    const in RectAreaLight rectAreaLight,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in PhysicalMaterial material,
    inout ReflectedLight reflectedLight
) {
    vec3 normal = geometryNormal;
    vec3 viewDir = geometryViewDir;
    vec3 position = geometryPosition;
    vec3 lightPos = rectAreaLight.position;
    vec3 halfWidth = rectAreaLight.halfWidth;
    vec3 halfHeight = rectAreaLight.halfHeight;
    vec3 lightColor = rectAreaLight.color;
    float roughness = material.roughness;

    vec3 rectCoords[4];
    rectCoords[0] = lightPos + halfWidth - halfHeight;
    rectCoords[1] = lightPos - halfWidth - halfHeight;
    rectCoords[2] = lightPos - halfWidth + halfHeight;
    rectCoords[3] = lightPos + halfWidth + halfHeight;

    vec2 uv = LTC_Uv(normal, viewDir, roughness);
    vec4 t1 = texture(ltc_1, uv);
    vec4 t2 = texture(ltc_2, uv);

    mat3 mInv = mat3(
        vec3(t1.x, 0.0, t1.y),
        vec3(0.0,  1.0, 0.0),
        vec3(t1.z, 0.0, t1.w)
    );

    // LTC Fresnel Approximation (Stephen Hill)
    vec3 fresnel = (material.specularColor * t2.x + (vec3(1.0) - material.specularColor) * t2.y);

    reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate(normal, viewDir, position, mInv, rectCoords);
    reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate(normal, viewDir, position, mat3(1.0), rectCoords);
}

void RE_Direct_Physical(
    const in IncidentLight directLight,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in PhysicalMaterial material,
    inout ReflectedLight reflectedLight
) {
    float dotNL = saturate(dot(geometryNormal, directLight.direction));
    vec3 irradiance = dotNL * directLight.color;

    // Clearcoat Direct
    float dotNLcc = saturate(dot(geometryClearcoatNormal, directLight.direction));
    vec3 ccIrradiance = dotNLcc * directLight.color;
    clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat(directLight.direction, geometryViewDir, geometryClearcoatNormal, material);

    // Sheen Direct
    sheenSpecularDirect += irradiance * BRDF_Sheen(directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness);

    // Standard PBR Direct
    reflectedLight.directSpecular += irradiance * BRDF_GGX(directLight.direction, geometryViewDir, geometryNormal, material);
    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}

void RE_IndirectDiffuse_Physical(
    const in vec3 irradiance,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in PhysicalMaterial material,
    inout ReflectedLight reflectedLight
) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}


/**
 * Physical Indirect Lighting and Specular Occlusion (Part 4).
 * Finalizes the PBR lighting accumulation.
 */

void RE_IndirectSpecular_Physical(
    const in vec3 radiance,
    const in vec3 irradiance,
    const in vec3 clearcoatRadiance,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in PhysicalMaterial material,
    inout ReflectedLight reflectedLight
) {
    // Sheen Indirect
    // IBLSheenBRDF must be defined in your sheen utility file
    sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF(geometryNormal, geometryViewDir, material.sheenRoughness);

    vec3 singleScattering = vec3(0.0);
    vec3 multiScattering = vec3(0.0);
    vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;

    // Multi-scattering logic (prevents energy loss at high roughness)
    #ifdef USE_IRIDESCENCE
        computeMultiscatteringIridescence(
            geometryNormal, geometryViewDir, material.specularColor, material.specularF90, 
            material.iridescence, material.iridescenceFresnel, material.roughness, 
            singleScattering, multiScattering
        );
    #else
        computeMultiscattering(
            geometryNormal, geometryViewDir, material.specularColor, 
            material.specularF90, material.roughness, singleScattering, multiScattering
        );
    #endif

    vec3 totalScattering = singleScattering + multiScattering;
    
    // Diffuse is what's left over after scattering
    vec3 diffuse = material.diffuseColor * (1.0 - max3(totalScattering));

    reflectedLight.indirectSpecular += radiance * singleScattering;
    reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
    reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}

/**
 * Specular Occlusion
 * Ref: https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
 */
float computeSpecularOcclusion(const in float dotNV, const in float ambientOcclusion, const in float roughness) {
    return saturate(pow(dotNV + ambientOcclusion, exp2(-16.0 * roughness - 1.0)) - 1.0 + ambientOcclusion);
}

/**
 * Analytical DFG and Multi-scattering (Part 6).
 * Finalizes energy-preserving IBL math.
 */

// Analytical approximation of the DFG LUT (Split-sum approximation)
// Ref: "Physically Based Shading on Mobile" - Unreal Engine
vec2 DFGApprox(const in vec3 normal, const in vec3 viewDir, const in float roughness) {
    float dotNV = saturate(dot(normal, viewDir));
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * dotNV)) * r.x + r.y;
    vec2 fab = vec2(-1.04, 1.04) * a004 + r.zw;
    return fab;
}

vec3 EnvironmentBRDF(const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness) {
    vec2 fab = DFGApprox(normal, viewDir, roughness);
    return specularColor * fab.x + specularF90 * fab.y;
}

// Fdez-Agüera's "Multiple-Scattering Microfacet Model for Real-Time Image Based Lighting"
// Approximates multiscattering in order to preserve energy.
void computeMultiscattering(const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter) {
    vec2 fab = DFGApprox(normal, viewDir, roughness);
    vec3 Fr = specularColor;
    vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
    float Ess = fab.x + fab.y;
    float Ems = 1.0 - Ess;
    vec3 Favg = Fr + (1.0 - Fr) * 0.047619; // 1/21
    vec3 Fms = FssEss * Favg / (1.0 - Ems * Favg);
    singleScatter += FssEss;
    multiScatter += Fms * Ems;
}

// Overload for Iridescence
void computeMultiscatteringIridescence(const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter) {
    vec2 fab = DFGApprox(normal, viewDir, roughness);
    vec3 Fr = mix(specularColor, iridescenceF0, iridescence);
    vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
    float Ess = fab.x + fab.y;
    float Ems = 1.0 - Ess;
    vec3 Favg = Fr + (1.0 - Fr) * 0.047619; // 1/21
    vec3 Fms = FssEss * Favg / (1.0 - Ems * Favg);
    singleScatter += FssEss;
    multiScatter += Fms * Ems;
}

/**
 * Converted LTC Evaluation and Sheen BRDF (Part 7).
 * Requires common.frag for PI, RECIPROCAL_PI, transposeMat3, and saturate.
 */

vec3 LTC_Evaluate(const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[4]) {
    // Bail if point is on back side of plane of light
    vec3 v1 = rectCoords[1] - rectCoords[0];
    vec3 v2 = rectCoords[3] - rectCoords[0];
    vec3 lightNormal = cross(v1, v2);

    if (dot(lightNormal, P - rectCoords[0]) < 0.0) return vec3(0.0);

    // Construct orthonormal basis around N
    vec3 T1 = normalize(V - N * dot(V, N));
    vec3 T2 = -cross(N, T1);

    // Compute transform using native transpose from 4.60
    mat3 mat = mInv * transpose(mat3(T1, T2, N));

    // Transform rect
    vec3 coords[4];
    coords[0] = mat * (rectCoords[0] - P);
    coords[1] = mat * (rectCoords[1] - P);
    coords[2] = mat * (rectCoords[2] - P);
    coords[3] = mat * (rectCoords[3] - P);

    // Project rect onto sphere
    coords[0] = normalize(coords[0]);
    coords[1] = normalize(coords[1]);
    coords[2] = normalize(coords[2]);
    coords[3] = normalize(coords[3]);

    // Calculate vector form factor
    vec3 vectorFormFactor = vec3(0.0);
    vectorFormFactor += LTC_EdgeVectorFormFactor(coords[0], coords[1]);
    vectorFormFactor += LTC_EdgeVectorFormFactor(coords[1], coords[2]);
    vectorFormFactor += LTC_EdgeVectorFormFactor(coords[2], coords[3]);
    vectorFormFactor += LTC_EdgeVectorFormFactor(coords[3], coords[0]);

    // Adjust for horizon clipping
    float result = LTC_ClippedSphereFormFactor(vectorFormFactor);

    return vec3(result);
}

// --- Sheen BRDF ---
// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"

float D_Charlie(float roughness, float dotNH) {
    float alpha = pow2(roughness);
    float invAlpha = 1.0 / alpha;
    float cos2h = dotNH * dotNH;
    float sin2h = max(1.0 - cos2h, 0.0078125); 
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

float V_Neubelt(float dotNV, float dotNL) {
    return saturate(1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV)));
}

vec3 BRDF_Sheen(const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness) {
    vec3 halfDir = normalize(lightDir + viewDir);
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, halfDir));

    float D = D_Charlie(sheenRoughness, dotNH);
    float V = V_Neubelt(dotNV, dotNL);

    return sheenColor * (D * V);
}

// IBL Sheen BRDF curve-fit approximation
float IBLSheenBRDF(const in vec3 normal, const in vec3 viewDir, const in float roughness) {
    float dotNV = saturate(dot(normal, viewDir));
    float r2 = roughness * roughness;
    
    float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
    float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
    float DG = exp(a * dotNV + b) + (roughness < 0.25 ? 0.0 : 0.1 * (roughness - 0.25));

    return saturate(DG * RECIPROCAL_PI);
}

/**
 * Specular BRDF and LTC Utils (Part 3).
 * Requires PhysicalMaterial struct, pow2(), saturate(), and F_Schlick().
 */

vec3 BRDF_GGX(const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
    vec3 f0 = material.specularColor;
    float f90 = material.specularF90;
    float roughness = material.roughness;
    float alpha = pow2(roughness); // UE4's roughness

    vec3 halfDir = normalize(lightDir + viewDir);
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, halfDir));
    float dotVH = saturate(dot(viewDir, halfDir));

    vec3 F = F_Schlick(f0, f90, dotVH);

    // Dynamic checks for Iridescence and Anisotropy
    if (material.iridescence > 0.0) {
        F = mix(F, material.iridescenceFresnel, material.iridescence);
    }

    float V, D;
    if (material.anisotropy > 0.0) {
        float dotTL = dot(material.anisotropyT, lightDir);
        float dotTV = dot(material.anisotropyT, viewDir);
        float dotTH = dot(material.anisotropyT, halfDir);
        float dotBL = dot(material.anisotropyB, lightDir);
        float dotBV = dot(material.anisotropyB, viewDir);
        float dotBH = dot(material.anisotropyB, halfDir);

        V = V_GGX_SmithCorrelated_Anisotropic(material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL);
        D = D_GGX_Anisotropic(material.alphaT, alpha, dotNH, dotTH, dotBH);
    } else {
        V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);
        D = D_GGX(alpha, dotNH);
    }

    return F * (V * D);
}

// --- Rect Area Light (LTC) Utilities ---

vec2 LTC_Uv(const in vec3 N, const in vec3 V, const in float roughness) {
    const float LUT_SIZE = 64.0;
    const float LUT_SCALE = (LUT_SIZE - 1.0) / LUT_SIZE;
    const float LUT_BIAS = 0.5 / LUT_SIZE;

    float dotNV = saturate(dot(N, V));
    
    // texture parameterized by sqrt( GGX alpha ) and sqrt( 1 - cos( theta ) )
    vec2 uv = vec2(roughness, sqrt(1.0 - dotNV));
    uv = uv * LUT_SCALE + LUT_BIAS;
    return uv;
}

float LTC_ClippedSphereFormFactor(const in vec3 f) {
    // An approximation of the form factor of a horizon-clipped rectangle.
    float l = length(f);
    return max((l * l + f.z) / (l + 1.0), 0.0);
}

vec3 LTC_EdgeVectorFormFactor(const in vec3 v1, const in vec3 v2) {
    float x = dot(v1, v2);
    float y = abs(x);

    // rational polynomial approximation to theta / sin( theta ) / 2PI
    float a = 0.8543985 + (0.4965155 + 0.0145206 * y) * y;
    float b = 3.4175940 + (4.1616724 + y) * y;
    float v = a / b;

    float theta_sintheta = (x > 0.0) ? v : 0.5 * inversesqrt(max(1.0 - x * x, 1e-7)) - v;

    return cross(v1, v2) * theta_sintheta;
}
