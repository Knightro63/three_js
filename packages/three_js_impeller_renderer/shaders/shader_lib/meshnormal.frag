#version 460 core

/**
 * Stage: Fragment
 * Purpose: Visualizes surface normals (World or Tangent space) as RGB colors.
 */

#define NORMAL

// 1. DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag" // Provides packNormalToRGB
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/normal_pars.frag"
#include "../shader_chunk/bumpmap_pars.frag"
#include "../shader_chunk/normalmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    float opacity;
    bool isOpaque;
};

// Location 13: vViewPosition synced with Vertex 13
layout(location = 13) in vec3 vViewPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    // Initialize base color (Normal shaders usually use black as base)
    vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    
    // 2. NORMAL PROCESSING
    // Establishes the 'normal' variable, applying Bump or Normal maps if active
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"

    // 3. PACKING & OUTPUT
    // packNormalToRGB converts [-1, 1] range to [0, 1] for visualization
    pc_fragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );

    if (isOpaque) {
        pc_fragColor.a = 1.0;
    }
}
