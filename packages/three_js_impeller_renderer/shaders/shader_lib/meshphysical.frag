#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for PBR materials (Physical/Standard).
 */

#define STANDARD
#define PHYSICAL

// 1. DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/dithering_pars.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/aomap_pars.frag"
#include "../shader_chunk/lightmap_pars.frag"
#include "../shader_chunk/emissivemap_pars.frag"
#include "../shader_chunk/cube_uv_reflection.frag"
#include "../shader_chunk/envmap_common_pars.frag"
#include "../shader_chunk/envmap_physical_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/normal_pars.frag"
#include "../shader_chunk/lights_physical_pars.frag"
#include "../shader_chunk/transmission_pars.frag"
#include "../shader_chunk/shadowmap_pars.frag"
#include "../shader_chunk/bumpmap_pars.frag"
#include "../shader_chunk/normalmap_pars.frag"
#include "../shader_chunk/clearcoat_pars.frag"
#include "../shader_chunk/iridescence_pars.frag"
#include "../shader_chunk/roughnessmap_pars.frag"
#include "../shader_chunk/metalnessmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

// Uniforms from Binding 1 (MaterialUniforms)
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    float roughness;
    float metalness;
    float opacity;
    float ior;
    float specularIntensity;
    vec3 specularColor;
    float clearcoat;
    float clearcoatRoughness;
    float dispersion;
    float iridescence;
    float iridescenceIOR;
    float iridescenceThicknessMinimum;
    float iridescenceThicknessMaximum;
    vec3 sheenColor;
    float sheenRoughness;
    vec2 anisotropyVector;
    // ... booleans for feature toggles
};

// Location 13: vViewPosition per Master List
layout(location = 13) in vec3 vViewPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( diffuse, opacity );
    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
    vec3 totalEmissiveRadiance = emissive;

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/color.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"
    
    // 2. PBR PROPERTY MAPPING
    #include "../shader_chunk/roughnessmap.frag"
    #include "../shader_chunk/metalnessmap.frag"
    
    // 3. NORMAL PROCESSING
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"
    #include "../shader_chunk/clearcoat_normal_fragment_begin.frag"
    #include "../shader_chunk/clearcoat_normal_fragment_maps.frag"
    
    #include "../shader_chunk/emissivemap.frag"

    // 4. ACCUMULATION (PBR Lighting Execution)
    // This populates the 'material' struct with IOR, Specular, Sheen, etc.
    #include "../shader_chunk/lights_physical_fragment.frag"
    #include "../shader_chunk/lights_fragment_begin.frag"
    #include "../shader_chunk/lights_fragment_maps.frag"
    #include "../shader_chunk/lights_fragment_end.frag"

    #include "../shader_chunk/aomap.frag"

    vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
    vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;

    // 5. VOLUME & REFRACTION
    #include "../shader_chunk/transmission_fragment.frag"

    vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;

    // 6. LAYER BLENDING (Sheen & Clearcoat)
    if (uUseSheen) {
        float sheenEnergyComp = 1.0 - 0.157 * max(max(material.sheenColor.r, material.sheenColor.g), material.sheenColor.b);
        outgoingLight = outgoingLight * sheenEnergyComp + (sheenSpecularDirect + sheenSpecularIndirect);
    }

    if (uUseClearcoat) {
        float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
        vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
        outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
    }

    // 7. FINALIZE & OUTPUT
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"
    #include "../shader_chunk/dithering.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
