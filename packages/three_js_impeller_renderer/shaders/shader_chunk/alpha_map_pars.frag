
/**
 * Flutter GPU requires explicit binding locations. 
 * Adjust the binding index (2) to match your pipeline's DescriptorSet layout.
 */
layout(set = 0, binding = 2) uniform sampler2D alphaMap;
