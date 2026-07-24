layout(std140, binding = 0) uniform CatBlock {
  mat4 transform;
  vec4 backgroundIntensity;
} cat;

in vec3 position;
in vec2 uv;

out vec2 v_uv;
out float v_bright;

void main() {
  mat3 uvTransform = mat3(
    cat.transform[0].xyz,
    cat.transform[1].xyz,
    cat.transform[2].xyz
  );
  
  v_uv = vec2(uv.x, 1.0 - uv.y); 
  gl_Position = vec4( position.xy, 0.999, 1.0 );
  v_bright = cat.backgroundIntensity.x;
}