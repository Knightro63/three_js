
/**
 * Flutter GPU requires explicit binding locations. 
 * Adjust the binding index (2) to match your pipeline's DescriptorSet layout.
 */
layout(std140, binding = 1) uniform MaterialUniforms {
    int alphaMapIndex; // alphaMap
    int vAlphaMapUvIndex; // vAlphaMapUv
    

} material;

// Slot 6: The Global Texture Array (contains up to 64 maps)
layout(set = 0, binding = 6) uniform sampler2DArray u_mapArray;