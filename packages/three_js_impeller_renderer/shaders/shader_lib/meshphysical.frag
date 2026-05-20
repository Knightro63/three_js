#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/dithering_pars_fragment.frag"
#include "../shader_chunk/color_pars_fragment.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/aomap_pars_fragment.frag"
#include "../shader_chunk/lightmap_pars_fragment.frag"
#include "../shader_chunk/emissivemap_pars_fragment.frag"
#include "../shader_chunk/iridescence_fragment.frag"
#include "../shader_chunk/cube_uv_reflection_fragment.frag"
#include "../shader_chunk/envmap_common_pars_fragment.frag"
#include "../shader_chunk/envmap_physical_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/normal_pars_fragment.frag"
#include "../shader_chunk/lights_physical_pars_fragment.frag"
#include "../shader_chunk/transmission_pars_fragment.frag"
#include "../shader_chunk/shadowmap_pars_fragment.frag"
#include "../shader_chunk/bumpmap_pars_fragment.frag"
#include "../shader_chunk/normalmap_pars_fragment.frag"
#include "../shader_chunk/clearcoat_pars_fragment.frag"
#include "../shader_chunk/iridescence_pars_fragment.frag"
#include "../shader_chunk/roughnessmap_pars_fragment.frag"
#include "../shader_chunk/metalnessmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Sequentially stacked right behind your 32 vertex matrix registers.
uniform CoreMaterialUniforms {
    vec3 diffuse;               // Float Indices 32, 33, 34
    vec3 emissive;              // Float Indices 35, 36, 37
    float roughness;            // Float Index 38
    float metalness;            // Float Index 39
    float opacity;              // Float Index 40
};

uniform PhysicalExtensionUniforms {
    vec3 specularColor;         // Float Indices 41, 42, 43
    vec3 sheenColor;            // Float Indices 44, 45, 46
    float ior;                  // Float Index 47
    float specularIntensity;    // Float Index 48
    float clearcoat;            // Float Index 49
    float clearcoatRoughness;   // Float Index 50
    float dispersion;           // Float Index 51
    float sheenRoughness;       // Float Index 52
};

uniform IridescenceAnisotropyUniforms {
    vec4 iridescenceParams;     // Float Indices 53, 54, 55, 56 -> [iridescence, ior, thicknessMin, thicknessMax]
    vec2 anisotropyVector;      // Float Indices 57, 58
};

uniform FeatureSwitchesUniforms {
    bool isPhysical;            // Float Index 59 (Enables physical IOR and specular extensions)
    bool useClearcoat;          // Float Index 60
    bool useSheen;              // Float Index 61
};

// 3. TEXTURE SAMPLERS (Decoupled image array mappings starting at sampler index 0)
uniform sampler2D specularColorMap;
uniform sampler2D specularIntensityMap;
uniform sampler2D sheenColorMap;
uniform sampler2D sheenRoughnessMap;
uniform sampler2D anisotropyMap;

// 4. PIPELINE INPUTS
in vec3 vViewPosition;
in vec3 vNormal;
in vec2 vUv;

// 5. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
    vec3 totalEmissiveRadiance = emissive;

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"
    #include "../shader_chunk/roughnessmap_fragment.frag"
    #include "../shader_chunk/metalnessmap_fragment.frag"
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"
    #include "../shader_chunk/clearcoat_normal_fragment_begin.frag"
    #include "../shader_chunk/clearcoat_normal_fragment_maps.frag"
    #include "../shader_chunk/emissivemap_fragment.frag"

    // accumulation
    #include "../shader_chunk/lights_physical_fragment.frag"
    #include "../shader_chunk/lights_fragment_begin.frag"
    #include "../shader_chunk/lights_fragment_maps.frag"
    #include "../shader_chunk/lights_fragment_end.frag"

    // modulation
    #include "../shader_chunk/aomap_fragment.frag"

    vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
    vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;

    #include "../shader_chunk/transmission_fragment.frag"

    vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;

    // Converted runtime branch mapping macro dependencies
    if (useSheen) {
        float sheenEnergyComp = 1.0 - 0.157 * max(max(sheenColor.r, sheenColor.g), sheenColor.b);
        outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
    }

    if (useClearcoat) {
        float dotNVcc = clamp(dot(geometryClearcoatNormal, geometryViewDir), 0.0, 1.0);
        vec3 Fcc = F_Schlick(material.clearcoatF0, material.clearcoatF90, dotNVcc);
        outgoingLight = outgoingLight * (1.0 - material.clearcoat * Fcc) + (clearcoatSpecularDirect + clearcoatSpecularIndirect) * material.clearcoat;
    }

    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"
    #include "../shader_chunk/premultiplied_alpha_fragment.frag"
    #include "../shader_chunk/dithering_fragment.frag"

    fragColor = vec4(outgoingLight, diffuseColor.a);
}
