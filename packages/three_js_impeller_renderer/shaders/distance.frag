#include <common.glsl>
#include <clipping.glsl>

in vec3 v_color;
in vec3 v_worldPosition;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }
  vec3 color = v_color;

    mat4 invView = inverse(scene.viewMatrix);
    vec3 cameraWorldPos = invView[3].xyz;

    float distanceToCamera = length(v_worldPosition - cameraWorldPos);

    float near = scene.fogParams.x;
    float far = scene.fogParams.y;

    if (far <= near) {
        far = 2000.0;
    }

    float normalizedDistance = clamp((distanceToCamera - near) / (far - near), 0.0, 1.0);
    float antiPrune = material.baseColor.a * 0.000001;
    frag_color = vec4(vec3(normalizedDistance) + vec3(antiPrune), material.baseColor.a);
}
