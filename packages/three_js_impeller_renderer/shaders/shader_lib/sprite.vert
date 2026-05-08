#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for billboarding sprites with rotation and scale.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

layout(std140, binding = 1) uniform MaterialUniforms {
    float rotation;
    vec2 center;
    bool useSizeAttenuation;
};

// Location 23: vUv synced with Frag 23 per Master List
layout(location = 23) out vec2 vUv;

void main() {
    // 2. UV SETUP
    #include "../shader_chunk/uv_vertex.vert"

    // 3. BILLBOARD LOGIC
    // Move the center of the sprite to view space
    vec4 mvPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );

    // Determine scale from the model matrix's basis vectors
    vec2 scale;
    scale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
    scale.y = length( vec3( modelMatrix[ 1 ].xyz ) );

    if ( !useSizeAttenuation ) {
        bool isPerspective = isPerspectiveMatrix( projectionMatrix );
        if ( isPerspective ) scale *= - mvPosition.z;
    }

    // 4. ROTATION & ALIGNMENT
    vec2 alignedPosition = ( inPosition.xy - ( center - vec2( 0.5 ) ) ) * scale;

    vec2 rotatedPosition;
    rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
    rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;

    mvPosition.xy += rotatedPosition;

    // 5. PROJECTION
    gl_Position = projectionMatrix * mvPosition;

    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
