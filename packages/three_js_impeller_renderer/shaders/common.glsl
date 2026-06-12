// 1. THE CRITICAL ENGINE FIX: Custom structs are banned in flutter_gpu UBOs.
// Instead, flatten properties out into parallel arrays of primitive types!
layout(std140, binding = 0) uniform SceneBlock {
    // Nested scene parameters
    mat4 projectionMatrix;
    mat4 viewMatrix;
    vec4 cameraPosition;    // w = lightCount
    vec4 ambientColor;
    vec4 fogColor;
    vec4 fogParams;         // near, far, density, isFogExp2
    
    // Parallel primitive arrays replacing the Light struct array
    vec4 lightPositions[16];
    vec4 lightColors[16];
    vec4 lightAttenuationParams[16];
    vec4 lightExtendedParams[16];
} scene;

// 1. THE CRITICAL ENGINE FIX: Custom structs are banned in flutter_gpu UBOs.
// Instead, flatten properties out into parallel arrays of primitive types!
layout(std140, binding = 1) uniform MaterialBlock {
    // Core mesh properties
    mat4 modelMatrix;        // 64 bytes
    vec4 baseColor;          // 16 bytes
    vec4 emissiveColor;      // 16 bytes
    vec4 pbrParams;          // 16 bytes
    vec4 materialParams;     // 16 bytes
    vec4 mapIntensities;     // 16 bytes
    vec4 specularAndIOR;     // 16 bytes
    vec4 sheenColorAndIntensity; 
    vec4 physicalAdvancedParams; 
    vec4 attenuationColorVec; 
    vec4 lineParams;         
    vec4 lineExtendedParams; 
    vec4 morphInfluences0;   
    vec4 morphInfluences1;   
    
    vec4 clippingPlanes[6];
    vec4 clippingPlaneParams;
} material;