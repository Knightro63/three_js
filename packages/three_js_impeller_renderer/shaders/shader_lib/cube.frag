#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float tFlip;
    float opacity;
};

// Binding 59: tCube (New dedicated binding)
layout(binding = 59) uniform sampler2D tCube;

// Location 10: vWorldPosition (Received from Vertex Location 6)
layout(location = 10) in vec3 vWorldPosition;

// Location 31: pc_fragColor 
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec3 lookupDir = vec3(tFlip * vWorldPosition.x, vWorldPosition.yz);
    
    // Atlas-style lookup logic placeholder for Flutter GPU
    vec4 texColor = texture(tCube, lookupDir.xy); 

    texColor.a *= opacity;

    pc_fragColor = texColor;
}
