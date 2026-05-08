#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for Point materials.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/color_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Optional UV Output (Synced with Frag 23)
layout(location = 23) out vec2 vUv;

layout(std140, binding = 1) uniform MaterialUniforms {
    float size;
    float scale;
    mat3 uvTransform;
    bool usePointsUv;
    bool useSizeAttenuation;
};

void main() {
    // 2. UV & COLOR SETUP
    if (usePointsUv) {
        vUv = (uvTransform * vec3(inUv, 1.0)).xy;
    }

    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphcolor.vert"

    // 3. CORE GEOMETRY
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 4. POINT SIZE LOGIC
    gl_PointSize = size;

    if (useSizeAttenuation) {
        // isPerspectiveMatrix helper from common.vert
        bool isPerspective = isPerspectiveMatrix(projectionMatrix);
        if (isPerspective) {
            gl_PointSize *= (scale / -mvPosition.z);
        }
    }

    // 5. FINALIZE
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
