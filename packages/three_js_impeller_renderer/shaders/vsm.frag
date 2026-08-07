#include <packing.glsl>

layout(std140, binding = 0) uniform VsmBlock {
    vec4 rr; // x: res_x, y: res_y, z: radius, w: is_horizontal_pass
} vsm;

uniform sampler2D shadow_pass;

in vec2 v_uv;

out vec4 frag_color;

void main() {
  float samples = 8.0;
  float mean = 0.0;
  float squared_mean = 0.0;
  
  vec2 resolution = vsm.rr.xy;
  float radius = vsm.rr.z;
  
  float uvStride = samples <= 1.0 ? 0.0 : 2.0 / (samples - 1.0);
  float uvStart = samples <= 1.0 ? 0.0 : -1.0;
  
  vec2 base_uv = v_uv; 

  for (float i = 0.0; i < samples; i++) {
    float uvOffset = uvStart + i * uvStride;
    vec2 offset;
    
    if (vsm.rr.w > 0.5) {
      offset = vec2(uvOffset * radius, 0.0) / resolution;
    } else {
      offset = vec2(0.0, uvOffset * radius) / resolution;
    }
    
    vec2 sample_uv = base_uv + offset;
    // Replaced texture2D with modern GLSL texture()
    vec4 color_sample = texture(shadow_pass, sample_uv);

    if (vsm.rr.w > 0.5) {
      vec2 distribution = unpackRGBATo2Half(color_sample);
      mean += distribution.x;
      squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
    } else {
      float depth = unpackRGBAToDepth(color_sample);
      mean += depth;
      squared_mean += depth * depth;
    }
  }
  
  mean = mean / samples;
  squared_mean = squared_mean / samples;
  
  // Safeguard against floating-point precision variance bugs
  float variance = max(0.0, squared_mean - (mean * mean));
  float std_dev = sqrt(variance);
  
  frag_color = pack2HalfToRGBA(vec2(mean, std_dev));
}
