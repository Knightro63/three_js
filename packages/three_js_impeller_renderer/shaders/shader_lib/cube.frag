#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/tonemapping_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    float tFlip;
    float opacity;
};

// Binding 59: Dedicated background cube texture map per Master List
layout(set = 0, binding = 59) uniform sampler2D tCube; // Atlas-style for Flutter GPU

// Location 10: vWorldPosition synced with Vertex 10 per Master List
layout(location = 10) in vec3 vWorldPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    // Calculate direction from interpolated position
    vec3 vWorldDirection = normalize(vWorldPosition);

    // Standard Cube sampling using the 2D Atlas helper
    // textureCube() from cube_uv_reflection.frag handles the Atlas lookup
    vec3 lookupDir = vec3(tFlip * vWorldDirection.x, vWorldDirection.yz);
    vec4 texColor = textureCube(tCube, lookupDir);

    texColor.a *= opacity;

    // Interface with tonemapping/colorspace chunks
    vec3 outgoingLight = texColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"

    pc_fragColor = vec4(outgoingLight, texColor.a);
}
