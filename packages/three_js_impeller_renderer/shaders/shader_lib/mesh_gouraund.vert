#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/envmap_pars_vertex.vert"
#include "../shader_chunk/bsdfs.vert"
#include "../shader_chunk/lights_pars_begin.vert"
#include "../shader_chunk/color_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/shadowmap_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec3 normal;
in vec2 uv;

// 3. UNIFORMS BLOCKS
// Keeping indices 0 through 31 reserved for basic structural projections
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

uniform VertexConfigUniforms {
    bool isDoubleSided;      // Float Index 32 (Converted from DOUBLE_SIDED macro)
    bool useLightProbes;     // Float Index 33 (Converted from USE_LIGHT_PROBES macro)
    float activePointLights;  // Float Index 34 (Dynamic runtime ceiling count for point loops)
    float activeSpotLights;   // Float Index 35 (Dynamic runtime ceiling count for spot loops)
    float activeDirLights;    // Float Index 36 (Dynamic runtime ceiling count for directional loops)
    float activeHemiLights;   // Float Index 37 (Dynamic runtime ceiling count for hemisphere loops)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching to fragment stage)
out vec3 vLightFront;
out vec3 vIndirectFront;
out vec3 vLightBack;
out vec3 vIndirectBack;
out vec2 vUv;

void main() {
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphcolor_vertex.vert"
    #include "../shader_chunk/beginnormal_vertex.vert"
    #include "../shader_chunk/morphnormal_vertex.vert"
    #include "../shader_chunk/skinbase_vertex.vert"
    #include "../shader_chunk/skinnormal_vertex.vert"
    #include "../shader_chunk/defaultnormal_vertex.vert"
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/skinning_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/envmap_vertex.vert"

    // INLINED FROM LEGACY <lights_lambert_vertex> Chunks
    vec3 diffuse = vec3(1.0);
    vec3 geometryPosition = mvPosition.xyz;
    vec3 geometryNormal = normalize(transformedNormal);
    vec3 geometryViewDir = (isOrthographic) ? vec3(0.0, 0.0, 1.0) : normalize(-mvPosition.xyz);
    vec3 backGeometryNormal = -geometryNormal;

    vLightFront = vec3(0.0);
    vIndirectFront = vec3(0.0);
    vLightBack = vec3(0.0);
    vIndirectBack = vec3(0.0);

    IncidentLight directLight;
    float dotNL;
    vec3 directLightColor_Diffuse;

    // Ambient Occlusion Base Setup
    vIndirectFront += getAmbientLightIrradiance(ambientLightColor);

    if (useLightProbes) {
        vIndirectFront += getLightProbeIrradiance(lightProbe, geometryNormal);
    }

    if (isDoubleSided) {
        vIndirectBack += getAmbientLightIrradiance(ambientLightColor);
        if (useLightProbes) {
            vIndirectBack += getLightProbeIrradiance(lightProbe, backGeometryNormal);
        }
    }

    // POINT LIGHTS PIPELINE (Loop maximums hardcoded for ahead-of-time compiler compliance)
    for (int i = 0; i < 4; i++) {
        if (float(i) >= activePointLights) break;
        getPointLightInfo(pointLights[i], geometryPosition, directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        directLightColor_Diffuse = directLight.color;
        
        vLightFront += clamp(dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        if (isDoubleSided) {
            vLightBack += clamp(-dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        }
    }

    // SPOT LIGHTS PIPELINE
    for (int i = 0; i < 4; i++) {
        if (float(i) >= activeSpotLights) break;
        getSpotLightInfo(spotLights[i], geometryPosition, directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        directLightColor_Diffuse = directLight.color;
        
        vLightFront += clamp(dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        if (isDoubleSided) {
            vLightBack += clamp(-dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        }
    }

    // DIRECTIONAL LIGHTS PIPELINE
    for (int i = 0; i < 4; i++) {
        if (float(i) >= activeDirLights) break;
        getDirectionalLightInfo(directionalLights[i], directLight);
        dotNL = dot(geometryNormal, directLight.direction);
        directLightColor_Diffuse = directLight.color;
        
        vLightFront += clamp(dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        if (isDoubleSided) {
            vLightBack += clamp(-dotNL, 0.0, 1.0) * directLightColor_Diffuse;
        }
    }

    // HEMISPHERE LIGHTS PIPELINE
    for (int i = 0; i < 2; i++) {
        if (float(i) >= activeHemiLights) break;
        vIndirectFront += getHemisphereLightIrradiance(hemisphereLights[i], geometryNormal);
        if (isDoubleSided) {
            vIndirectBack += getHemisphereLightIrradiance(hemisphereLights[i], backGeometryNormal);
        }
    }

    #include "../shader_chunk/shadowmap_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
