#version 460 core

/**
 * Stage: Vertex
 * Purpose: Per-vertex (Gouraud) Lambertian lighting.
 */

#define GOURAUD

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/envmap_pars.vert"
#include "../shader_chunk/bsdfs.frag"           // Required for lighting math
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/color_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/shadowmap_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Varying Outputs per Master List
layout(location = 14) out vec3 vLightFront;
layout(location = 15) out vec3 vIndirectFront;
layout(location = 16) out vec3 vLightBack;
layout(location = 17) out vec3 vIndirectBack;

layout(std140, binding = 1) uniform MaterialUniforms {
    bool isDoubleSided;
    // ... other uniforms
};

void main() {
    // 2. GEOMETRY & ANIMATION
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphcolor.vert"
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/skinnormal.vert"
    #include "../shader_chunk/defaultnormal.vert"
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/envmap_vertex.vert"

    // 3. GOURAUD LIGHTING CALCULATION
    vec3 geometryPosition = mvPosition.xyz;
    vec3 geometryNormal = normalize(transformedNormal);
    
    vLightFront = vec3(0.0);
    vIndirectFront = vec3(0.0);
    vLightBack = vec3(0.0);
    vIndirectBack = vec3(0.0);

    IncidentLight directLight;
    float dotNL;

    // Ambient & Light Probes
    vIndirectFront += getAmbientLightIrradiance(ambientLightColor);
    if (isDoubleSided) {
        vIndirectBack += getAmbientLightIrradiance(ambientLightColor);
    }

    // Point Lights
    for (int i = 0; i < NUM_POINT_LIGHTS; i++) {
        getPointLightInfo(pointLights[i], geometryPosition, directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // Spot Lights
    for (int i = 0; i < NUM_SPOT_LIGHTS; i++) {
        getSpotLightInfo(spotLights[i], geometryPosition, directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // Directional Lights
    for (int i = 0; i < NUM_DIR_LIGHTS; i++) {
        getDirectionalLightInfo(directionalLights[i], directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // Hemisphere Lights
    for (int i = 0; i < NUM_HEMI_LIGHTS; i++) {
        vIndirectFront += getHemisphereLightIrradiance(hemisphereLights[i], geometryNormal);
        if (isDoubleSided) vIndirectBack += getHemisphereLightIrradiance(hemisphereLights[i], -geometryNormal);
    }

    // 4. SHADOWS & FOG
    #include "../shader_chunk/shadowmap.vert"
    #include "../shader_chunk/fog.vert"
}
