#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/tonemapping_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    float backgroundIntensity;
    bool decodeVideoTexture; // Replacement for DECODE_VIDEO_TEXTURE
};

// Binding 58: Dedicated background texture map per Master List
layout(set = 0, binding = 58) uniform sampler2D t2D;

// Location 53: vUv synced with Vertex 53 per Master List
layout(location = 53) in vec2 vUv;

// Final Output per Master List (Synced with pc_fragColor)
layout(location = 0) out vec4 pc_fragColor;

void main() {
    vec4 texColor = texture(t2D, vUv);

    if (decodeVideoTexture) {
        // Inline sRGB decode logic for video textures
        texColor = vec4(mix(
            pow(texColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)),
            texColor.rgb * 0.0773993808,
            vec3(lessThanEqual(texColor.rgb, vec3(0.04045)))
        ), texColor.w);
    }

    texColor.rgb *= backgroundIntensity;

    // Use outgoingLight to interface with tonemapping/colorspace chunks
    vec3 outgoingLight = texColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"

    pc_fragColor = vec4(outgoingLight, texColor.a);
}
