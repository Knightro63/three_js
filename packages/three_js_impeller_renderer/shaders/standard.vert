#include <common.glsl>
#include <skinning.glsl>

layout(binding = 3) uniform sampler2D displacementMap;

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;
in vec4 skinIndex;
in vec4 skinWeight;

out vec3 v_color;
out vec3 v_worldPosition;
out vec3 v_worldNormal;
out vec2 v_uv;
out vec4 v_skinIndex;
out vec4 v_skinWeight;

void main() {
    vec3 vertexColor = color;
    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3(1.0);
    }
    v_uv = uv;

    // 1. Process Displacement Mapping First (Local Space)
    bool hasDisplacementMap = material.flags2.x > 0.5;
    bool hasBoneTexture = material.flags0.x > 0.5;
    
    vec3 displacedPosition = position;
    if (hasDisplacementMap) {
        float displacement = texture(displacementMap, v_uv).r;
        // material.materialParams.y = displacementScale, material.materialParams.z = displacementBias
        displacedPosition += normal * (displacement * material.materialParams.y + material.materialParams.z);
    }

    // 2. Process Skeletal Skinning + Normal Matrix Updates
    vec4 worldPosition4;
    vec3 animatedNormal = normal;

    if (hasBoneTexture) {
        // Fetch the raw active 4x4 matrix transformation combination
        mat4 skinMatrix = getSkinMatrix(skinIndex, skinWeight);
        
        // Transform the local displaced position directly into final world coordinates
        // Note: Three.js skinner geometry includes the model space implicitly inside the bind stack!
        worldPosition4 = skinMatrix * vec4(displacedPosition, 1.0);
        
        // THE FIX: Skin your surface normal vectors so lighting conforms to bone movements
        animatedNormal = mat3(skinMatrix) * normal;
    } else {
        // Standard un-skinned static rendering fallback path
        worldPosition4 = material.modelMatrix * vec4(displacedPosition, 1.0);
    }

    // 3. Finalize Uniform Outputs
    v_worldPosition = worldPosition4.xyz;
    
    // Normalize normal vector into world space for the fragment shader lighting loops
    v_worldNormal = normalize(mat3(material.modelMatrix) * animatedNormal);

    // Camera Perspective Frustum Projection
    vec4 viewPosition = scene.viewMatrix * worldPosition4;
    gl_Position = scene.projectionMatrix * viewPosition;
    
    // Maintain your far plane boundary cushion fix
    gl_Position.z = gl_Position.z * 0.995; 

    // Forward fragment attributes
    v_color = material.baseColor.rgb * vertexColor;
    v_skinIndex = skinIndex;
    v_skinWeight = skinWeight;
}
