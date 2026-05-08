
/**
 * Binding 25: A texture containing influence weights per instance.
 * x-axis: [Base Influence, Target 0, Target 1, ..., Target N]
 * y-axis: gl_InstanceID
 */
layout(set = 0, binding = 25) uniform sampler2D morphInfluenceTexture;

/**
 * Converts morphinstanceVertex logic.
 * Fetches weights for the current instance into local variables.
 */
void fetchInstanceMorphWeights(
    out float morphTargetBaseInfluence, 
    out float morphTargetInfluences[8] // Using fixed size 8 for GLSL 4.60
) {
    // Fetch base influence from the first texel of the instance's row
    morphTargetBaseInfluence = texelFetch(morphInfluenceTexture, ivec2(0, gl_InstanceID), 0).r;

    for (int i = 0; i < 8; i++) {
        // Fetch each target influence from subsequent texels
        morphTargetInfluences[i] = texelFetch(morphInfluenceTexture, ivec2(i + 1, gl_InstanceID), 0).r;
    }
}
