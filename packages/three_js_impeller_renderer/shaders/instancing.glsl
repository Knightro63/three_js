layout(binding = 3) uniform sampler2D instanceTexture;

mat4 getInstanceMatrix() {
    // Total indices inside a single instance mesh template (passed via uniforms)
    float templateIndexCount = material.materialParams.x; 
    if (templateIndexCount <= 0.0) templateIndexCount = 36.0; // e.g., Fallback default for a cube

    // 1. Calculate which instance batch copy this specific hardware thread belongs to
    float computedInstanceId = floor(float(gl_VertexIndex) / templateIndexCount);

    // 2. Perform your standard square texture coordinate layout lookups
    float size = material.boneTextureParm.y;
    if (size <= 0.0) size = 4.0;
    
    int j = int(computedInstanceId) * 4;
    float yPixel = floor(float(j) / size);
    float xPixel = mod(float(j), size);
    
    vec2 uv1 = vec2(xPixel + 0.5, yPixel + 0.5) / size;
    vec2 uv2 = vec2(xPixel + 1.5, yPixel + 0.5) / size;
    vec2 uv3 = vec2(xPixel + 2.5, yPixel + 0.5) / size;
    vec2 uv4 = vec2(xPixel + 3.5, yPixel + 0.5) / size;
    
    return mat4(
        texture(instanceTexture, uv1),
        texture(instanceTexture, uv2),
        texture(instanceTexture, uv3),
        texture(instanceTexture, uv4)
    );
}
