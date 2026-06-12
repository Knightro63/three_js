// Helper to calculate face-tangents on-the-fly when explicit vertex tangents are missing.
vec3 perturbNormal2Arb(vec3 worldPos, vec3 surf_norm, vec3 mapNormal, vec2 uv) {
    vec3 q0 = dFdx(worldPos);
    vec3 q1 = dFdy(worldPos);
    vec2 st0 = dFdx(uv);
    vec2 st1 = dFdy(uv);
    
    vec3 N = surf_norm; // Base geometric surface normal
    vec3 crs = cross(q0, q1);
    
    vec3 T = q0 * st1.y - q1 * st0.y;
    vec3 B = q1 * st0.x - q0 * st1.x;
    
    float scale = sign(dot(crs, cross(T, B)));
    T = normalize(T * scale);
    B = normalize(B * scale);
    
    // Form the local Tangent, Bitangent, Normal space matrix
    // GLSL constructors initialize matrices column-by-column
    mat3 tbn = mat3(T, B, N);
    
    // Transform normal map vector from tangent space to world space
    return normalize(tbn * mapNormal);
}

// Centralized master normal resolver function called by your fragment shader
vec3 resolveNormal(
    vec3 interpolatedNormal, 
    vec3 worldPos, 
    vec2 uv, 
    vec3 sampledNormalMap
) {
    // Feature matrix flags mapping out your conditional branches
    // Note: Multidimensional array access in GLSL matches: matrix[column][row]
    bool useFlatShading = material.features[0][2] > 0.5; // Column 0, Row 2
    bool useNormalMap   = material.features[0][3] > 0.5; // Column 0, Row 3
    bool useBumpMap     = material.features[0][2] > 0.5; // Column 0, Row 2

    vec3 N;

    // 1. CHOOSE BASE GEOMETRIC GEOMETRY LAYER (Flat Shading vs Smooth Vertex Normals)
    if (useFlatShading) {
        vec3 p_dx = dFdx(worldPos);
        vec3 p_dy = dFdy(worldPos);
        N = normalize(cross(p_dx, p_dy));
    } else {
        N = normalize(interpolatedNormal);
    }

    // 2. APPLY NORMAL MAP OVERLAY MODULATION
    if (useNormalMap) {
        // Map raw 0.0-1.0 texture sample bytes back to standard -1.0 to 1.0 vectors
        vec3 normalMapVector = sampledNormalMap * 2.0 - vec3(1.0);
        
        // Scale normal map impact dynamically
        normalMapVector.x = normalMapVector.x * material.mapIntensities.x;
        normalMapVector.y = normalMapVector.y * material.mapIntensities.x;
        normalMapVector.z = sqrt(max(0.0, 1.0 - normalMapVector.x * normalMapVector.x - normalMapVector.y * normalMapVector.y));
        
        N = perturbNormal2Arb(worldPos, N, normalize(normalMapVector), uv);
    }

    // 3. APPLY BUMP MAP OVERLAY MODULATION
    if (useBumpMap && !useNormalMap) {
        // Optional placeholder: Heightmap generation via gray values derivative space
    }

    return N;
}
