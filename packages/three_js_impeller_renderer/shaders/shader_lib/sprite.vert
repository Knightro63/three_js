#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec2 uv;

// 3. UNIFORMS BLOCKS
// Shared continuous layout tracker matching your global engine pattern
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
    mat4 modelMatrix;        // Float Indices 32 through 47 (16 float slots)
};

uniform SpriteConfigUniforms {
    vec2 center;             // Float Indices 48, 49 (Pivot point mapping context)
    float rotation;          // Float Index 50        (2D camera space roll rotation angle)
    bool useSizeAttenuation; // Float Index 51        (Converted from compile-time macro)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// This links straight to your companion fragment shader inputs by variable string name
out vec2 vUv;

void main() {
    #include "../shader_chunk/uv_vertex.vert"

    // Transform sprite anchor origin using the combined view pipeline matrix
    vec4 mvPosition = modelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);

    // Extract viewport scaling factors out of the base model transformation matrix rows
    vec2 scale;
    scale.x = length(vec3(modelMatrix[0].x, modelMatrix[0].y, modelMatrix[0].z));
    scale.y = length(vec3(modelMatrix[1].x, modelMatrix[1].y, modelMatrix[1].z));

    // Converted runtime branch: cancels perspective scaling shrinkage if disabled
    if (!useSizeAttenuation) {
        // isPerspectiveMatrix helper is pulled directly out of common.vert
        bool isPerspective = isPerspectiveMatrix(projectionMatrix);
        if (isPerspective) {
            scale *= -mvPosition.z;
        }
    }

    // Offset sprite quad dimensions relative to its custom coordinate center boundary pivot
    vec2 alignedPosition = (position.xy - (center - vec2(0.5))) * scale;

    // Apply 2D rotation matrix calculations over localized vertex positions
    vec2 rotatedPosition;
    rotatedPosition.x = cos(rotation) * alignedPosition.x - sin(rotation) * alignedPosition.y;
    rotatedPosition.y = sin(rotation) * alignedPosition.x + cos(rotation) * alignedPosition.y;

    // Inject transformed billboard vertices back into the view space array coordinates
    mvPosition.xy += rotatedPosition;
    gl_Position = projectionMatrix * mvPosition;

    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
