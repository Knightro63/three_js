layout(binding = 3) uniform sampler2D instanceTexture;

mat4 getInstanceMatrix(float instanceID) {
    float computedInstanceId = floor(instanceID + 0.01);
    float texWidth = 4.0;
    
    float baseCount = material.boneTextureParm.w; 
    float texHeight = material.boneTextureParm.z;
    float maxValue = 1.0; 

    if (baseCount != texHeight) {
        maxValue = baseCount / texHeight;
    }
    
    if (texHeight <= 0.0) texHeight = 1.0;

    float v = clamp((computedInstanceId + 0.5) / texHeight, 0.0, maxValue);

    vec4 row1 = texture(instanceTexture, vec2(0.5 / texWidth, v));
    vec4 row2 = texture(instanceTexture, vec2(1.5 / texWidth, v));
    vec4 row3 = texture(instanceTexture, vec2(2.5 / texWidth, v));
    vec4 row4 = texture(instanceTexture, vec2(3.5 / texWidth, v));
    
    return mat4(row1, row2, row3, row4);
}

vec3 getInstanceColor(float instanceID) {
    float id = floor(instanceID + 0.01);
    float texWidth = 4.0;
    
    float baseCount = material.boneTextureParm.w; // uniformData (e.g., 1000.0)
    float texHeight = material.boneTextureParm.z; // uniformData (e.g., 1250.0)

    if (texHeight <= 0.0) texHeight = 1.0;

    // Use your 4-instances-per-row color math layout
    float colorRowOffset = floor(id / 4.0);
    float colorPixelOffset = mod(id, 4.0);

    // Shift targetRow downward past the complete matrix block height
    float targetRow = baseCount + colorRowOffset;
    
    float v = clamp((targetRow + 0.5) / texHeight, 0.0, 1.0);
    float u = (colorPixelOffset + 0.5) / texWidth;

    return texture(instanceTexture, vec2(u, v)).rgb;
}
