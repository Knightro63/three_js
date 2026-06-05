import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk normalChunk = ShaderChunk(
  name: 'common.normal',
  source: '''
// Helper to calculate face-tangents on-the-fly when explicit vertex tangents are missing.
// This matches WebGL's standard derivative-space normal mapping.
fn perturbNormal2Arb(worldPos: vec3<f32>, surf_norm: vec3<f32>, mapNormal: vec3<f32>, uv: vec2<f32>) -> vec3<f32> {
    let q0 = dpdx(worldPos);
    let q1 = dpdy(worldPos);
    let st0 = dpdx(uv);
    let st1 = dpdy(uv);

    let N = surf_norm; // Base geometric surface normal

    let crs = cross(q0, q1);
    var T = q0 * st1.y - q1 * st0.y;
    var B = q1 * st0.x - q0 * st1.x;

    let scale = sign(dot(crs, cross(T, B)));
    T = normalize(T * scale);
    B = normalize(B * scale);

    // Form the local Tangent, Bitangent, Normal space matrix
    let tbn = mat3x3<f32>(T, B, N);
    
    // Transform normal map vector from tangent space to world space
    return normalize(tbn * mapNormal);
}

// Centralized master normal resolver function called by your fragment shader
fn resolveNormal(
  interpolatedNormal: vec3<f32>, 
  worldPos: vec3<f32>, 
  uv: vec2<f32>, 
  sampledNormalMap: vec3<f32>
) -> vec3<f32> {
    // Feature matrix flags mapping out your conditional branches
    let useFlatShading = uniforms.features[0][2] > 0.5; // Column 0, Row 2
    let useNormalMap   = uniforms.features[0][3] > 0.5; // Column 0, Row 3
    let useBumpMap     = uniforms.features[0][2] > 0.5; // Column 0, Row 2 (PBR mapIntensities overlay)

    var N: vec3<f32>;

    // 1. CHOOSE BASE GEOMETRIC GEOMETRY LAYER (Flat Shading vs Smooth Vertex Normals)
    if (useFlatShading) {
        let p_dx = dpdx(worldPos);
        let p_dy = dpdy(worldPos);
        N = normalize(cross(p_dx, p_dy));
    } else {
        N = normalize(interpolatedNormal);
    }

    // Ensure double-sided rendering flipped normals look right if mesh side is double
    // WebGL Parity: gl_FrontFacing check
    // let faceSign = select(-1.0, 1.0, is_front_facing); // Pass via builtin fragment if needed
    
    // 2. APPLY NORMAL MAP OVERLAY MODULATION (WebGL: normal_fragment_maps)
    if (useNormalMap) {
        // Map raw 0.0-1.0 texture sample bytes back to standard -1.0 to 1.0 vectors
        var normalMapVector = sampledNormalMap * 2.0 - vec3<f32>(1.0);
        
        // Scale normal map impact dynamically (uniforms.mapIntensities.x holds bumpScale/normalScale)
        normalMapVector.x = normalMapVector.x * uniforms.mapIntensities.x;
        normalMapVector.y = normalMapVector.y * uniforms.mapIntensities.x;
        normalMapVector.z = sqrt(max(0.0, 1.0 - normalMapVector.x * normalMapVector.x - normalMapVector.y * normalMapVector.y));
        
        N = perturbNormal2Arb(worldPos, N, normalize(normalMapVector), uv);
    }
    
    // 3. APPLY BUMP MAP OVERLAY MODULATION (WebGL: bumpmap_pars_fragment)
    if (useBumpMap && !useNormalMap) {
        // Optional placeholder: If calculating heightmaps via gray values, 
        // you would evaluate screen partial derivatives of your height values here
    }

    return N;
}
  ''',
);