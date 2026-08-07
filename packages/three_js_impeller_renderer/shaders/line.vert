#include <instancing.glsl>

layout(std140, binding = 1) uniform LineBlock {
    vec4 lineParms; // res, res, scale, width
    vec4 instanceStart;       // w = instanceDistanceStart
    vec4 instanceEnd;         // w = instanceDistanceEnd
    vec4 instanceColorStart;  // w = instanceID
    vec4 instanceColorEnd;    // w = world
} line;

in vec3 position; // x = [-1, 1], y = segment travel [0, 1]
in vec2 uv;

out vec3 v_color;
out vec3 v_worldPosition;
out vec2 v_uv;
out float v_lineDistance;

void trimSegment(const in vec4 start, inout vec4 end) {
    float a = material.projectionMatrix[2][2]; 
    float b = material.projectionMatrix[3][2]; 
    float nearEstimate = -0.5 * b / a;
    float alpha = (nearEstimate - start.z) / (end.z - start.z);
    end.xyz = mix(start.xyz, end.xyz, alpha);
}

void main() {
    // Unpack your new LineBlock variables safely
    vec3 segmentStart  = line.instanceStart.xyz;
    vec3 segmentEnd    = line.instanceEnd.xyz;
    float distanceStart = line.instanceStart.w;
    float distanceEnd   = line.instanceEnd.w;
    float instanceID    = line.instanceColorStart.w;
    
    vec3 colorStart    = line.instanceColorStart.xyz;
    vec3 colorEnd      = line.instanceColorEnd.xyz;

    // Pull configuration parameters out of your main material block
    float linewidth    = line.lineParms.w;
    float dashScale    = line.lineParms.z;
    vec2 resolution    = line.lineParms.xy;
    float aspect       = resolution.x / resolution.y;

    // Resolve structural matrix transformations for Impeller
    mat4 instanceModelMatrix = getBatchingInstance(int(instanceID));
    mat4 modelViewMatrix = material.viewMatrix * material.modelMatrix * instanceModelMatrix;

    // Set up fragment interpolation nodes
    v_color = (position.y < 0.5) ? colorStart : colorEnd;
    v_color *= material.baseColor.rgb; 
    v_lineDistance = (position.y < 0.5) ? dashScale * distanceStart : dashScale * distanceEnd;
    v_uv = uv;

    // Camera space transforms
    vec4 start = modelViewMatrix * vec4(segmentStart, 1.0);
    vec4 end   = modelViewMatrix * vec4(segmentEnd, 1.0);

    // Track world position context for clipping planes and scene parameters
    vec4 worldPos4 = material.modelMatrix * instanceModelMatrix * vec4(mix(segmentStart, segmentEnd, position.y), 1.0);
    v_worldPosition = worldPos4.xyz;

    // Handle near-plane camera intersection clipping 
    bool perspective = (material.projectionMatrix[2][3] == -1.0);
    if (perspective) {
        if (start.z < 0.0 && end.z >= 0.0) {
            trimSegment(start, end);
        } else if (end.z < 0.0 && start.z >= 0.0) {
            trimSegment(end, start);
        }
    }

    // Project forward to Normalized Device Coordinates (NDC)
    vec4 clipStart = material.projectionMatrix * start;
    vec4 clipEnd   = material.projectionMatrix * end;

    vec3 ndcStart = clipStart.xyz / clipStart.w;
    vec3 ndcEnd   = clipEnd.xyz / clipEnd.w;

    // Screen space directional configuration
    vec2 dir = ndcEnd.xy - ndcStart.xy;
    dir.x *= aspect;
    dir = normalize(dir);

    vec2 offset = vec2(dir.y, -dir.x);
    dir.x /= aspect;
    offset.x /= aspect;

    // Extrude out the 2D quad geometry 
    if (position.x < 0.0) {
        offset *= -1.0;
    }

    // Apply cap offsets based on segment travel limits
    if (position.y < 0.0) {
        offset += -dir;
    } else if (position.y > 1.0) {
        offset += dir;
    }

    // Width allocation scale
    offset *= (linewidth * 0.001);
    offset /= resolution.y;

    // Reassemble standard clipping coordinate bounds
    vec4 clip = (position.y < 0.5) ? clipStart : clipEnd;
    offset *= clip.w;
    clip.xy += offset;

    gl_Position = clip;
}
