#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float backgroundIntensity;
    bool decodeVideoTexture; // SPIR-V replacement for DECODE_VIDEO_TEXTURE
};

// Binding 54: Using specularMap slot for generic background t2D to avoid conflicts
// Alternatively, if this is a diffuse background, Binding 57 (transmissionSamplerMap) 
// or a new generic slot could be used. Standardizing to Binding 57.
layout(binding = 58) uniform sampler2D t2D;

// Location 31: vMapUv (Standard Diffuse/Map UV)
layout(location = 53) in vec2 vUv;
layout(location = 0) out vec4 pc_fragColor;

void main() {
    vec4 texColor = texture(t2D, vUv);

    if (decodeVideoTexture) {
        // Inline sRGB decode logic
        vec3 mid = pow(texColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4));
        vec3 low = texColor.rgb * 0.0773993808;
        texColor.rgb = mix(mid, low, vec3(lessThanEqual(texColor.rgb, vec3(0.04045))));
    }

    texColor.rgb *= backgroundIntensity;

    // Tonemapping and Colorspace conversion applied here
    pc_fragColor = texColor;
}
