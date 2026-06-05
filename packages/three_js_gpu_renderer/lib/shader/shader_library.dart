/// Shader features that map directly to preprocessor definitions in the shader library.
enum ShaderFeature {
  useTexture('USE_TEXTURE'),
  useNormalMap('USE_NORMAL_MAP'),
  useMetallicRoughnessMap('USE_METALLIC_ROUGHNESS_MAP'),
  useAoMap('USE_AO_MAP'),
  useEmissiveMap('USE_EMISSIVE_MAP'),
  useDirectionalLight('USE_DIRECTIONAL_LIGHT'),
  usePointLights('USE_POINT_LIGHTS'),
  useVertexColors('USE_VERTEX_COLORS'),
  useFog('USE_FOG'),
  useSkinning('USE_SKINNING'),
  useMorphTargets('USE_MORPH_TARGETS'),
  useInstancing('USE_INSTANCING'),
  useAlphaCutoff('USE_ALPHA_CUTOFF'),
  useShadows('USE_SHADOWS');

  const ShaderFeature(this.define);
  final String define;
}

/// Shader source code library containing the global structures and core shaders.
abstract class ShaderLibrary {
  /// Generates WGSL boolean constant structures acting as preprocessor definitions.
  static String generateDefines(Set<ShaderFeature> features) {
    final buffer = StringBuffer();
    
    // Add explicitly enabled feature constants
    for (final feature in features) {
      buffer.writeln('const ${feature.define}: bool = true;');
    }
    
    // Add disabled feature fallback constants
    for (final feature in ShaderFeature.values) {
      if (!features.contains(feature)) {
        buffer.writeln('const ${feature.define}: bool = false;');
      }
    }
    
    return buffer.toString();
  }

  /// Common structures used across vertex and fragment shaders.
  static const String commonStructures = '''
// ============================================================================
// Common Structures
// ============================================================================

struct CameraUniforms {
    viewMatrix: mat4x4<f32>,
    projectionMatrix: mat4x4<f32>,
    viewProjectionMatrix: mat4x4<f32>,
    cameraPosition: vec3<f32>,
    near: f32,
    far: f32,
    _padding: vec3<f32>,
};

struct ModelUniforms {
    modelMatrix: mat4x4<f32>,
    normalMatrix: mat4x4<f32>,
};

struct MaterialUniforms {
    baseColor: vec4<f32>,
    emissive: vec3<f32>,
    metallic: f32,
    roughness: f32,
    alphaCutoff: f32,
    normalScale: f32,
    aoStrength: f32,
};

struct DirectionalLight {
    direction: vec3<f32>,
    intensity: f32,
    color: vec3<f32>,
    _padding: f32,
};

struct PointLight {
    position: vec3<f32>,
    intensity: f32,
    color: vec3<f32>,
    range: f32,
};

struct FogUniforms {
    color: vec3<f32>,
    density: f32,
    near: f32,
    far: f32,
    _padding: vec2<f32>,
};
''';

  /// Standard vertex shader supporting dynamic configurations.
  static const String standardVertexShader = '''
// ============================================================================
// Standard Vertex Shader
// ============================================================================

// Bind group 0: Per-frame uniforms
@group(0) @binding(0) var<uniform> camera: CameraUniforms;

// Bind group 1: Per-object uniforms
@group(1) @binding(0) var<uniform> model: ModelUniforms;

// Vertex input
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
#ifdef USE_VERTEX_COLORS
    @location(3) color: vec4<f32>,
#endif
#ifdef USE_TANGENT
    @location(4) tangent: vec4<f32>,
#endif
};

// Vertex output
struct VertexOutput {
    @builtin(position) clipPosition: vec4<f32>,
    @location(0) worldPosition: vec3<f32>,
    @location(1) worldNormal: vec3<f32>,
    @location(2) uv: vec2<f32>,
#ifdef USE_VERTEX_COLORS
    @location(3) vertexColor: vec4<f32>,
#endif
#ifdef USE_TANGENT
    @location(4) worldTangent: vec3<f32>,
    @location(5) worldBitangent: vec3<f32>,
#endif
};

@vertex
fn main(input: VertexInput) -> VertexOutput {
    var output: VertexOutput;

    // Transform position to world space
    let worldPosition = (model.modelMatrix * vec4<f32>(input.position, 1.0)).xyz;
    output.worldPosition = worldPosition;

    // Transform to clip space
    output.clipPosition = camera.viewProjectionMatrix * vec4<f32>(worldPosition, 1.0);

    // Transform normal to world space (using normal matrix for non-uniform scaling)
    output.worldNormal = normalize((model.normalMatrix * vec4<f32>(input.normal, 0.0)).xyz);

    // Pass through UV
    output.uv = input.uv;

#ifdef USE_VERTEX_COLORS
    output.vertexColor = input.color;
#endif

#ifdef USE_TANGENT
    output.worldTangent = normalize((model.modelMatrix * vec4<f32>(input.tangent.xyz, 0.0)).xyz);
    output.worldBitangent = cross(output.worldNormal, output.worldTangent) * input.tangent.w;
#endif

    return output;
}
''';

  /// Standard fragment shader with unified PBR configurations.
  static const String standardFragmentShader = '''
// ============================================================================
// Standard Fragment Shader (PBR)
// ============================================================================

// Bind group 0: Per-frame uniforms
@group(0) @binding(0) var<uniform> camera: CameraUniforms;
@group(0) @binding(1) var<uniform> directionalLight: DirectionalLight;
#ifdef USE_FOG
@group(0) @binding(2) var<uniform> fog: FogUniforms;
#endif

// Bind group 1: Per-object uniforms
@group(1) @binding(0) var<uniform> model: ModelUniforms;

// Bind group 2: Material uniforms and textures
@group(2) @binding(0) var<uniform> material: MaterialUniforms;
#ifdef USE_TEXTURE
@group(2) @binding(1) var baseColorTexture: texture_2d<f32>;
@group(2) @binding(2) var baseColorSampler: sampler;
#endif
#ifdef USE_NORMAL_MAP
@group(2) @binding(3) var normalTexture: texture_2d<f32>;
@group(2) @binding(4) var normalSampler: sampler;
#endif
#ifdef USE_METALLIC_ROUGHNESS_MAP
@group(2) @binding(5) var metallicRoughnessTexture: texture_2d<f32>;
@group(2) @binding(6) var metallicRoughnessSampler: sampler;
#endif

// Fragment input (from vertex shader)
struct FragmentInput {
    @builtin(position) clipPosition: vec4<f32>,
    @location(0) worldPosition: vec3<f32>,
    @location(1) worldNormal: vec3<f32>,
    @location(2) uv: vec2<f32>,
#ifdef USE_VERTEX_COLORS
    @location(3) vertexColor: vec4<f32>,
#endif
#ifdef USE_TANGENT
    @location(4) worldTangent: vec3<f32>,
    @location(5) worldBitangent: vec3<f32>,
#endif
};

// PBR Constants
const PI: f32 = 3.14159265359;
const DIELECTRIC_F0: vec3<f32> = vec3<f32>(0.04, 0.04, 0.04);

// Normal Distribution Function (GGX/Trowbridge-Reitz)
fn distributionGGX(N: vec3<f32>, H: vec3<f32>, roughness: f32) -> f32 {
    let a = roughness * roughness;
    let a2 = a * a;
    let NdotH = max(dot(N, H), 0.0);
    let NdotH2 = NdotH * NdotH;

    let num = a2;
    var denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

// Geometry function (Schlick-GGX)
fn geometrySchlickGGX(NdotV: f32, roughness: f32) -> f32 {
    let r = roughness + 1.0;
    let k = (r * r) / 8.0;

    let num = NdotV;
    let denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

fn geometrySmith(N: vec3<f32>, V: vec3<f32>, L: vec3<f32>, roughness: f32) -> f32 {
    let NdotV = max(dot(N, V), 0.0);
    let NdotL = max(dot(N, L), 0.0);
    let ggx2 = geometrySchlickGGX(NdotV, roughness);
    let ggx1 = geometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// Fresnel (Schlick approximation)
fn fresnelSchlick(cosTheta: f32, F0: vec3<f32>) -> vec3<f32> {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

@fragment
fn main(input: FragmentInput) -> @location(0) vec4<f32> {
    // Get base color
    var baseColor = material.baseColor;
#ifdef USE_TEXTURE
    baseColor = baseColor * textureSample(baseColorTexture, baseColorSampler, input.uv);
#endif
#ifdef USE_VERTEX_COLORS
    baseColor = baseColor * input.vertexColor;
#endif

    // Alpha cutoff
#ifdef USE_ALPHA_CUTOFF
    if (baseColor.a < material.alphaCutoff) {
        discard;
    }
#endif

    // Get normal
    var N = normalize(input.worldNormal);
#ifdef USE_NORMAL_MAP
    let tangentNormal = textureSample(normalTexture, normalSampler, input.uv).xyz * 2.0 - 1.0;
    let TBN = mat3x3<f32>(
        normalize(input.worldTangent),
        normalize(input.worldBitangent),
        N
    );
    N = normalize(TBN * (tangentNormal * vec3<f32>(material.normalScale, material.normalScale, 1.0)));
#endif

    // Get metallic and roughness
    var metallic = material.metallic;
    var roughness = material.roughness;
#ifdef USE_METALLIC_ROUGHNESS_MAP
    let metallicRoughness = textureSample(metallicRoughnessTexture, metallicRoughnessSampler, input.uv);
    metallic = metallic * metallicRoughness.b;
    roughness = roughness * metallicRoughness.g;
#endif
    roughness = clamp(roughness, 0.04, 1.0);

    // Calculate view direction
    let V = normalize(camera.cameraPosition - input.worldPosition);

    // Calculate F0 (surface reflection at zero incidence)
    let F0 = mix(DIELECTRIC_F0, baseColor.rgb, metallic);

    // Lighting calculation
    var Lo = vec3<f32>(0.0);

#ifdef USE_DIRECTIONAL_LIGHT
    // Directional light contribution
    let L = normalize(-directionalLight.direction);
    let H = normalize(V + L);

    let NDF = distributionGGX(N, H, roughness);
    let G = geometrySmith(N, V, L, roughness);
    let F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    let kS = F;
    let kD = (vec3<f32>(1.0) - kS) * (1.0 - metallic);

    let numerator = NDF * G * F;
    let denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    let specular = numerator / denominator;

    let NdotL = max(dot(N, L), 0.0);
    let radiance = directionalLight.color * directionalLight.intensity;
    Lo = Lo + (kD * baseColor.rgb / PI + specular) * radiance * NdotL;
#endif

    // Ambient (very simple)
    let ambient = vec3<f32>(0.03) * baseColor.rgb;

    // Emissive
    let emissive = material.emissive;

    // Final color
    var color = ambient + Lo + emissive;

    // HDR tonemapping (Reinhard)
    color = color / (color + vec3<f32>(1.0));

    // Gamma correction
    color = pow(color, vec3<f32>(1.0 / 2.2));

#ifdef USE_FOG
    // Linear fog
    let fogDistance = length(input.worldPosition - camera.cameraPosition);
    let fogFactor = clamp((fog.far - fogDistance) / (fog.far - fog.near), 0.0, 1.0);
    color = mix(fog.color, color, fogFactor);
#endif

    return vec4<f32>(color, baseColor.a);
}
''';

  /// Unlit vertex shader (simple, no lighting).
  static const String unlitVertexShader = '''
// ============================================================================
// Unlit Vertex Shader
// ============================================================================

struct Uniforms {
    modelViewProjection: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@vertex
fn main(input: VertexInput) -> VertexOutput {
    var output: VertexOutput;
    output.position = uniforms.modelViewProjection * vec4<f32>(input.position, 1.0);
    output.color = input.color;
    return output;
}
''';

  /// Unlit fragment shader (simple, no lighting).
  static const String unlitFragmentShader = '''
// ============================================================================
// Unlit Fragment Shader
// ============================================================================

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@fragment
fn main(input: VertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(input.color, 1.0);
}
''';

  /// Combines definitions with shader source.
  static String compileShader(String source, Set<ShaderFeature> features) {
    final defines = generateDefines(features);
    return '$defines\n\n$commonStructures\n\n$source';
  }
}

/// Precompiled shader variants for common configurations.
abstract class ShaderVariants {
  /// Basic unlit shader with vertex colors
  static final unlitVertexColor = ShaderVariant(
    vertex: ShaderLibrary.unlitVertexShader,
    fragment: ShaderLibrary.unlitFragmentShader,
    features: const {},
  );

  /// Standard PBR with texture
  static final standardTextured = ShaderVariant(
    vertex: ShaderLibrary.standardVertexShader,
    fragment: ShaderLibrary.standardFragmentShader,
    features: const {
      ShaderFeature.useTexture,
      ShaderFeature.useDirectionalLight,
    },
  );

  /// Standard PBR with normal map
  static final standardNormalMapped = ShaderVariant(
    vertex: ShaderLibrary.standardVertexShader,
    fragment: ShaderLibrary.standardFragmentShader,
    features: const {
      ShaderFeature.useTexture,
      ShaderFeature.useNormalMap,
      ShaderFeature.useDirectionalLight,
    },
  );
}

/// A compiled shader variant with specific features enabled.
class ShaderVariant {
  ShaderVariant({
    required this.vertex,
    required this.fragment,
    required this.features,
  });

  final String vertex;
  final String fragment;
  final Set<ShaderFeature> features;

  // Cached compiled shaders mapping Kotlin's "by lazy" evaluation architecture via custom getters
  String? _compiledVertex;
  String get compiledVertex => _compiledVertex ??= ShaderLibrary.compileShader(vertex, features);

  String? _compiledFragment;
  String get compiledFragment => _compiledFragment ??= ShaderLibrary.compileShader(fragment, features);
}
