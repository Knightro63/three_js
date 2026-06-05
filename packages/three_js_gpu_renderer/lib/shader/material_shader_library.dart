import 'package:three_js_gpu_renderer/shader/shader_chunk/chunks.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/libs.dart';
import 'shader_chunk_registry.dart';

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

  static MaterialShaderDescriptor convert(String name) {
    ensureBuiltInsRegistered();
    return MaterialShaderDescriptor(
      key: 'material.$name',
      vertexChunks: ['material.$name.vertex.main'],
      fragmentChunks: ['material.$name.fragment.main'],
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
  }

  static void ensureBuiltInsRegistered() {
    if (_builtInsRegistered) return;
    ShaderChunkRegistry.registerAll(
      _BuiltInMaterialChunks.defaults(),
      replaceExisting: true,
    );
    _builtInsRegistered = true;
  }

  static void resetForTests() => _builtInsRegistered = false;
}

/// Internal compilation chunk blueprints encapsulating the standard WGSL multi-pass system.
abstract class _BuiltInMaterialChunks {

  static List<ShaderChunk> defaults() {
    final maxLights = 16;
    final maxClipppingPlanes = 6;
    return [ShaderChunk(
      name: 'common.uniforms',
      source: '''
        struct Light {
          position: vec4<f32>,//w is direction
          color: vec4<f32>,// a is intensity
          attenuationParams: vec4<f32>,     
          extendedParams: vec4<f32>,        
        };

        struct SceneUniforms {
          projectionMatrix: mat4x4<f32>,
          viewMatrix: mat4x4<f32>,
          cameraPosition: vec4<f32>,// w = lightCount
          ambientColor: vec4<f32>,
          fogColor: vec4<f32>,
          fogParams: vec4<f32>, //near,far, density, isFogExp2
          lights: array<Light, $maxLights>,
        };

        struct Uniforms {
            scene: SceneUniforms,          // Nested scene uniforms for easy access in material shaders
            modelMatrix: mat4x4<f32>,       // 64 bytes (Offsets 0-15)
            baseColor: vec4<f32>,          // 16 bytes (Offsets 16-19) -> rgb: color, a: opacity
            emissiveColor: vec4<f32>,      // 16 bytes (Offsets 20-23) -> rgb: emissive, a: intensity
            
            // x: roughness, y: metalness, z: flatShading (0/1), w: alphaTest
            pbrParams: vec4<f32>,          // 16 bytes (Offsets 24-27)
            
            // x: shininess, y: clearcoat, z: clearcoatRoughness, w: wireframe (0/1)
            materialParams: vec4<f32>,     // 16 bytes (Offsets 28-31)
            
            // x: bumpScale, y: envMapIntensity, z: lightMapIntensity, w: aoMapIntensity
            mapIntensities: vec4<f32>,     // 16 bytes (Offsets 32-35)

            // ==========================================
            // NEW EXTENSIONS: Phong Specular & PBR Sheen
            // ==========================================
            // rgb: specularColor * specularIntensity (Phong fallback)
            // a: ior (Physical index of refraction, e.g., 1.5)
            specularAndIOR: vec4<f32>,     // 16 bytes (Offsets 36-39)

            // rgb: sheenColor, a: sheen intensity parameter
            sheenColorAndIntensity: vec4<f32>, // 16 bytes (Offsets 40-43)
            
            // x: sheenRoughness, y: reflectivity, z: attenuationDistance, w: transmission
            physicalAdvancedParams: vec4<f32>, // 16 bytes (Offsets 44-47)

            // rgb: attenuationColor, a: prefilterMipCount
            attenuationColorVec: vec4<f32>, // 16 bytes (Offsets 48-51)

            // ==========================================
            // NEW EXTENSIONS: Line & Dash Parameters
            // ==========================================
            // x: linewidth, y: dashSize, z: lineCapType, w: lineJoinType
            lineParams: vec4<f32>,         // 16 bytes (Offsets 52-55)

            // x: gapSize, y: scale, z: colorspace, w: rotation (for sprite)
            lineExtendedParams: vec4<f32>, // 16 bytes (Offsets 56-59)

            // Animation / Vertex Shifting
            morphInfluences0: vec4<f32>,   // 16 bytes (Offsets 56-59)
            morphInfluences1: vec4<f32>,   // 16 bytes (Offsets 60-63)

            clippingPlanes: array<vec4<f32>, $maxClipppingPlanes>,
            clippingPlaneCount: f32,         // 16 bytes (Offsets 52-55)
        };
        @group(0) @binding(0) var<uniform> uniforms: Uniforms; 
      ''',
    ),
    ...chunks,
    ...shaderLibs,
  ];
  }
}
