#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/color_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec2 uv;
in vec3 color;

// 3. UNIFORMS BLOCKS
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

uniform ParticleConfigUniforms {
    mat3 uvTransform;        // Float Indices 32 through 40 (9 float slots)
    float size;              // Float Index 41
    float scale;             // Float Index 42
    bool usePointsUv;        // Float Index 43 (Converted from macro)
    bool useSizeAttenuation; // Float Index 44 (Converted from macro)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
out vec2 vUv;
out vec3 vColor;
out float vCalculatedSize; // Forwards attenuation adjustments to the fragment processor

void main() {
    vColor = color;

    if (usePointsUv) {
        vUv = (uvTransform * vec3(uv, 1.0)).xy;
    } else {
        vUv = uv;
    }

    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"
    #include "../shader_chunk/morphcolor_vertex.vert"
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"

    float calculatedSize = size;
    
    if (useSizeAttenuation) {
        // isPerspectiveMatrix is evaluated directly out of common.vert
        bool isPerspective = isPerspectiveMatrix(projectionMatrix);
        if (isPerspective) {
            // mvPosition is populated internally by project_vertex.vert
            calculatedSize *= (scale / -mvPosition.z);
        }
    }

    // Assign to native viewport and forward data stream properties
    gl_PointSize = calculatedSize;
    vCalculatedSize = calculatedSize;

    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
