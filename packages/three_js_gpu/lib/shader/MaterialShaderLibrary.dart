import './ShaderChunkRegistry.dart';

/// Descriptor identifying the chunks required to assemble a material shader.
/// Used as a cache key for compiled shader sources.
class MaterialShaderDescriptor {
  const MaterialShaderDescriptor({
    required this.key,
    required this.vertexChunks,
    required this.fragmentChunks,
    this.replacements = const {},
  });

  final String key;
  final List<String> vertexChunks;
  final List<String> fragmentChunks;
  final Map<String, String> replacements;

  /// Fluent extension replacement block modeling Kotlin's `withOverrides` property loop
  MaterialShaderDescriptor withOverrides(Map<String, String> overrides) {
    if (overrides.isEmpty) return this;

    // Check if the current replacements map already contains identical key/value entries
    bool allMatch = true;
    for (final entry in overrides.entries) {
      if (replacements[entry.key] != entry.value) {
        allMatch = false;
        break;
      }
    }
    if (allMatch) return this;

    final merged = Map<String, String>.from(replacements);
    overrides.forEach((k, v) => merged[k] = v);

    return copyWith(replacements: merged);
  }

  MaterialShaderDescriptor copyWith({
    String? key,
    List<String>? vertexChunks,
    List<String>? fragmentChunks,
    Map<String, String>? replacements,
  }) {
    return MaterialShaderDescriptor(
      key: key ?? this.key,
      vertexChunks: vertexChunks ?? this.vertexChunks,
      fragmentChunks: fragmentChunks ?? this.fragmentChunks,
      replacements: replacements ?? this.replacements,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialShaderDescriptor &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          Object.hashAll(vertexChunks) == Object.hashAll(other.vertexChunks) &&
          Object.hashAll(fragmentChunks) == Object.hashAll(other.fragmentChunks) &&
          Object.hashAll(replacements.entries) == Object.hashAll(other.replacements.entries);

  @override
  int get hashCode => Object.hash(
        key,
        Object.hashAll(vertexChunks),
        Object.hashAll(fragmentChunks),
        Object.hashAll(replacements.entries),
      );
}

/// Fully assembled shader source code for a material.
class MaterialShaderSource {
  const MaterialShaderSource(this.vertexSource, this.fragmentSource);
  final String vertexSource;
  final String fragmentSource;
}

/// Compiles shader descriptors into full WGSL/GLSL strings using [ShaderChunkRegistry].
abstract class MaterialShaderGenerator {
  static final Map<MaterialShaderDescriptor, MaterialShaderSource> _cache = {};

  static MaterialShaderSource compile(MaterialShaderDescriptor descriptor) {
    MaterialShaderLibrary.ensureBuiltInsRegistered();

    final cached = _cache[descriptor];
    if (cached != null) return cached;

    final vertex = ShaderChunkRegistry.assemble(
      chunkNames: descriptor.vertexChunks,
      stage: ShaderStageType.vertex,
      replacements: descriptor.replacements,
    );

    final fragment = ShaderChunkRegistry.assemble(
      chunkNames: descriptor.fragmentChunks,
      stage: ShaderStageType.fragment,
      replacements: descriptor.replacements,
    );

    final compiled = MaterialShaderSource(vertex, fragment);
    _cache[descriptor] = compiled;

    return compiled;
  }

  static void clearCacheForTests() => _cache.clear();
}

/// Provides high-level material descriptors and handles registration of the built-in shader chunks.
abstract class MaterialShaderLibrary {
  static bool _builtInsRegistered = false;

  static const _basicDescriptor = MaterialShaderDescriptor(
    key: 'material.basic',
    vertexChunks: ['material.basic.vertex.main'],
    fragmentChunks: ['material.basic.fragment.main'],
    replacements: {
      'VERTEX_INPUT_EXTRA': '',
      'VERTEX_OUTPUT_EXTRA': '',
      'VERTEX_ASSIGN_EXTRA': '',
      'FRAGMENT_INPUT_EXTRA': '',
      'FRAGMENT_INIT_EXTRA': '',
      'FRAGMENT_EXTRA': '',
      'FRAGMENT_BINDINGS': '',
    },
  );

  static const _meshStandardDescriptor = MaterialShaderDescriptor(
    key: 'material.meshStandard',
    vertexChunks: ['material.pbr.vertex.main'],
    fragmentChunks: ['material.pbr.fragment.main'],
    replacements: {
      'VERTEX_INPUT_EXTRA': '',
      'VERTEX_OUTPUT_EXTRA': '',
      'VERTEX_ASSIGN_EXTRA': '',
      'FRAGMENT_INPUT_EXTRA': '',
      'FRAGMENT_INIT_EXTRA': '',
      'FRAGMENT_EXTRA': '',
      'FRAGMENT_BINDINGS': '',
    },
  );

  static MaterialShaderDescriptor basic() {
    ensureBuiltInsRegistered();
    return _basicDescriptor;
  }

  static MaterialShaderDescriptor meshStandard() {
    ensureBuiltInsRegistered();
    return _meshStandardDescriptor;
  }

  static void ensureBuiltInsRegistered() {
    if (_builtInsRegistered) return;
    
    ShaderChunkRegistry.registerAll(
      _BuiltInMaterialChunks.defaults,
      replaceExisting: true,
    );
    _builtInsRegistered = true;
  }

  static void resetForTests() => _builtInsRegistered = false;
}

/// Internal compilation chunk blueprints encapsulating the standard WGSL multi-pass system.
abstract class _BuiltInMaterialChunks {
  static final List<ShaderChunk> defaults = [
    ShaderChunk(
      name: 'common.uniforms',
      source: '''
struct Uniforms {
    projectionMatrix: mat4x4<f32>,
    viewMatrix: mat4x4<f32>,
    modelMatrix: mat4x4<f32>,
    baseColor: vec4<f32>,
    pbrParams: vec4<f32>,
    cameraPosition: vec4<f32>,
    ambientColor: vec4<f32>,
    fogColor: vec4<f32>,
    fogParams: vec4<f32>,
    mainLightDirection: vec4<f32>,
    mainLightColor: vec4<f32>,
    morphInfluences0: vec4<f32>,
    morphInfluences1: vec4<f32>,
}
@group(0) @binding(0) var<uniform> uniforms: Uniforms;
''',
    ),
    ShaderChunk(
      name: 'material.basic.vertex.input',
      stage: ShaderStageType.vertex,
      source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}
struct BasicVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    {{VERTEX_OUTPUT_EXTRA}}
}
''',
    ),
    ShaderChunk(
      name: 'material.basic.vertex.main',
      stage: ShaderStageType.vertex,
      source: '''
#include <common.uniforms>
#include <material.basic.vertex.input>
@vertex fn vs_main(input: VertexInput) -> BasicVertexOutput {
    var output: BasicVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;
    {{VERTEX_ASSIGN_EXTRA}}
    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    let viewPosition = uniforms.viewMatrix * worldPosition;
    output.position = uniforms.projectionMatrix * viewPosition;
    let materialColor = uniforms.baseColor.rgb;
    output.color = materialColor * vertexColor;
    return output;
}
''',
    ),
    ShaderChunk(
      name: 'material.basic.fragment.input',
      stage: ShaderStageType.fragment,
      source: '''
struct BasicFragmentInput {
    @location(0) color: vec3<f32>,
    {{FRAGMENT_INPUT_EXTRA}}
}
''',
    ),
    ShaderChunk(
      name: 'material.basic.fragment.main',
      stage: ShaderStageType.fragment,
      source: '''
#include <common.uniforms>
#include <material.basic.fragment.input>
{{FRAGMENT_BINDINGS}}
@fragment fn fs_main(input: BasicFragmentInput) -> @location(0) vec4<f32> {
    var color = input.color;
    {{FRAGMENT_INIT_EXTRA}}
    {{FRAGMENT_EXTRA}}
    return vec4<f32>(color, uniforms.baseColor.a);
}
''',
    ),
    ShaderChunk(
      name: 'material.pbr.vertex.input',
      stage: ShaderStageType.vertex,
      source: '''
struct PbrVertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}
struct PbrVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) worldNormal: vec3<f32>,
    @location(1) viewDir: vec3<f32>,
    @location(2) albedo: vec3<f32>,
    {{VERTEX_OUTPUT_EXTRA}}
}
''',
    ),
    ShaderChunk(
      name: 'material.pbr.vertex.main',
      stage: ShaderStageType.vertex,
      source: '''
#include <common.uniforms>
#include <material.pbr.vertex.input>
@vertex fn vs_main(input: PbrVertexInput) -> PbrVertexOutput {
    var output: PbrVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = max(input.color, vec3<f32>(1.0));
    {{VERTEX_ASSIGN_EXTRA}}
    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    let viewPosition = uniforms.viewMatrix * worldPosition;
    output.position = uniforms.projectionMatrix * viewPosition;
    let normalMatrix = mat3x3<f32>(
        uniforms.modelMatrix[0].xyz,
        uniforms.modelMatrix[1].xyz,
        uniforms.modelMatrix[2].xyz
    );
    output.worldNormal = normalize(normalMatrix * normal);
    let cameraPos = uniforms.cameraPosition.xyz;
    output.viewDir = cameraPos - worldPosition.xyz;
    let materialColor = uniforms.baseColor.rgb;
    output.albedo = materialColor * vertexColor;
    return output;
}
''',
    ),
    ShaderChunk(
      name: 'material.pbr.fragment.bindings',
      stage: ShaderStageType.fragment,
      source: '''
@group(2) @binding(0) var prefilterTexture: texture_cube<f32>;
@group(2) @binding(1) var prefilterSampler: sampler;
@group(2) @binding(2) var brdfLutTexture: texture_2d<f32>;
@group(2) @binding(3) var brdfLutSampler: sampler;
''',
    ),
    ShaderChunk(
      name: 'material.pbr.fragment.functions',
      stage: ShaderStageType.fragment,
      source: '''
fn roughness_to_mip(roughness: f32, mipCount: f32) -> f32 {
    if (mipCount <= 1.0) {
        return 0.0;
    }
    let clamped = clamp(roughness, 0.0, 1.0);
    let perceptual = clamped * clamped;
    final maxLevel = mipCount - 1.0;
    return min(maxLevel, perceptual * maxLevel);
}
fn mix_vec3(a: vec3<f32>, b: vec3<f32>, factor: f32) -> vec3<f32> {
    return a * (1.0 - factor) + b * factor;
}
fn saturate(value: f32) -> f32 {
    return clamp(value, 0.0, 1.0);
}
''',
    ),
    ShaderChunk(
      name: 'material.pbr.fragment.input',
      stage: ShaderStageType.fragment,
      source: '''
struct PbrFragmentInput {
    @location(0) worldNormal: vec3<f32>,
    @location(1) viewDir: vec3<f32>,
    @location(2) albedo: vec3<f32>,
    {{FRAGMENT_INPUT_EXTRA}}
}
''',
    ),
    ShaderChunk(
      name: 'material.pbr.fragment.main',
      stage: ShaderStageType.fragment,
      source: '''
#include <common.uniforms>
#include <material.pbr.fragment.bindings>
#include <material.pbr.fragment.functions>
#include <material.pbr.fragment.input>
{{FRAGMENT_BINDINGS}}
@fragment fn fs_main(input: PbrFragmentInput) -> @location(0) vec4<f32> {
    var N = normalize(input.worldNormal);
    let V = normalize(input.viewDir);
    var baseColor = clamp(input.albedo, vec3<f32>(0.0), vec3<f32>(1.0));
    {{FRAGMENT_INIT_EXTRA}}
    let roughness = uniforms.pbrParams.x;
    let metalness = uniforms.pbrParams.y;
    let envIntensity = uniforms.pbrParams.z;
    let mipCount = uniforms.pbrParams.w;
    var reflection = vec3<f32>(0.0);
    var NdotV = 0.0;
    if (length(V) > 0.0) {
        let R = reflect(-V, N);
        let lod = roughness_to_mip(roughness, mipCount);
        let sampled = textureSampleLevel(prefilterTexture, prefilterSampler, R, lod);
        reflection = sampled.rgb;
        NdotV = saturate(dot(N, V));
    }
    let F0 = mix_vec3(vec3<f32>(0.04), baseColor, metalness);
    let brdfSample = textureSample(brdfLutTexture, brdfLutSampler, vec2<f32>(NdotV, roughness)).rg;
    let specular = reflection * (F0 * brdfSample.x + vec3<f32>(brdfSample.y)) * envIntensity;
    let diffuse = baseColor * (1.0 - metalness);
    var color = clamp(diffuse + specular, vec3<f32>(0.0), vec3<f32>(1.0));
    {{FRAGMENT_EXTRA}}
    return vec4<f32>(color, 1.0);
}
''',
    ),
  ];
}
