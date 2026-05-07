#version 460 core

#define RECIPROCAL_PI 0.3183098861837907

/**
 * Note: F_Schlick must be provided by your common PBR library.
 */
vec3 F_Schlick(const in vec3 specularColor, const in float f90, const in float dotVH);

float G_BlinnPhong_Implicit() {
    // geometry term is (n dot l)(n dot v) / 4(n dot l)(n dot v)
    return 0.25;
}

float D_BlinnPhong(const in float shininess, const in float dotNH) {
    return RECIPROCAL_PI * (shininess * 0.5 + 1.0) * pow(dotNH, shininess);
}

vec3 BRDF_BlinnPhong(
    const in vec3 lightDir, 
    const in vec3 viewDir, 
    const in vec3 normal, 
    const in vec3 specularColor, 
    const in float shininess
) {
    vec3 halfDir = normalize(lightDir + viewDir);
    
    // replaced saturate() with clamp()
    float dotNH = clamp(dot(normal, halfDir), 0.0, 1.0);
    float dotVH = clamp(dot(viewDir, halfDir), 0.0, 1.0);

    vec3 F = F_Schlick(specularColor, 1.0, dotVH);
    float G = G_BlinnPhong_Implicit();
    float D = D_BlinnPhong(shininess, dotNH);

    return F * (G * D);
}
