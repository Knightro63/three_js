
/**
 * Note: Requires 'uv2' (Attr 30), 'vUv2' (Out 52), 
 * and 'uv2Transform' (Binding 1) from uv2_pars.vert.
 */

/**
 * Converts uv2Vertex logic.
 * Applies the mat3 transform to the secondary UV set.
 */
void applyUv2Transform() {
    // uv2Transform is provided in the MaterialUniforms block
    vUv2 = (uv2Transform * vec3(uv2, 1.0)).xy;
}
