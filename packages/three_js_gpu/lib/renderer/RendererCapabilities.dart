import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';

import 'BackendType.dart';

/// Configuration structure describing the capabilities and limits of a renderer.
class RendererCapabilities extends Capabilities{
  RendererCapabilities({
    this.backend = BackendType.webgl,
    this.deviceName = 'Unknown',
    this.driverVersion = 'Unknown',
    this.supportsCompute = false,
    this.supportsRayTracing = false,
    this.supportsMultisampling = true,
    this.maxTextureSize = 2048,
    this.maxCubeMapSize = 1024,
    this.maxVertexAttributes = 16,
    this.maxVertexUniforms = 1024,
    this.maxFragmentUniforms = 1024,
    this.maxVertexTextures = 0,
    this.maxFragmentTextures = 16,
    this.maxCombinedTextures = 32,
    this.maxTextureSize3D = 256,
    this.maxTextureArrayLayers = 256,
    this.maxColorAttachments = 8,
    this.maxSamples = 4,
    this.maxUniformBufferSize = 16384,
    this.maxUniformBufferBindings = 36,
    this.maxAnisotropy = 16.0,
    this.vertexShaderPrecisions = const ShaderPrecisions(),
    this.fragmentShaderPrecisions = const ShaderPrecisions(),
    this.textureFormats = const {
      TextureFormat.rgba8,
      TextureFormat.rgb8,
      TextureFormat.rgba16f,
      TextureFormat.rgba32f,
    },
    this.compressedTextureFormats = const {},
    this.depthFormats = const {DepthFormat.depth24Stencil8},
    this.extensions = const {},
    this.vendor = 'Unknown',
    this.renderer = 'Unknown',
    this.version = 'Unknown',
    this.shadingLanguageVersion = 'Unknown',
    this.instancedRendering = true,
    this.multipleRenderTargets = true,
    this.depthTextures = true,
    this.floatTextures = true,
    this.halfFloatTextures = true,
    this.floatTextureLinear = true,
    this.standardDerivatives = true,
    this.vertexArrayObjects = true,
    this.computeShaders = false,
    this.geometryShaders = false,
    this.tessellation = false,
    this.shadowMaps = true,
    this.shadowMapComparison = true,
    this.shadowMapPCF = true,
    this.parallelShaderCompile = false,
    this.asyncOperations = false,
  });

  final BackendType backend;
  final String deviceName;
  final String driverVersion;
  final bool supportsCompute;
  final bool supportsRayTracing;
  final bool supportsMultisampling;
  final int maxTextureSize;
  final int maxCubeMapSize;
  final int maxVertexAttributes;
  final int maxVertexUniforms;
  final int maxFragmentUniforms;
  final int maxVertexTextures;
  final int maxFragmentTextures;
  final int maxCombinedTextures;
  final int maxTextureSize3D;
  final int maxTextureArrayLayers;
  final int maxColorAttachments;
  final int maxSamples;
  final int maxUniformBufferSize;
  final int maxUniformBufferBindings;
  final double maxAnisotropy;
  final ShaderPrecisions vertexShaderPrecisions;
  final ShaderPrecisions fragmentShaderPrecisions;
  final Set<TextureFormat> textureFormats;
  final Set<CompressedTextureFormat> compressedTextureFormats;
  final Set<DepthFormat> depthFormats;
  final Set<String> extensions;
  final String vendor;
  final String renderer;
  final String version;
  final String shadingLanguageVersion;
  final bool instancedRendering;
  final bool multipleRenderTargets;
  final bool depthTextures;
  final bool floatTextures;
  final bool halfFloatTextures;
  final bool floatTextureLinear;
  final bool standardDerivatives;
  final bool vertexArrayObjects;
  final bool computeShaders;
  final bool geometryShaders;
  final bool tessellation;
  final bool shadowMaps;
  final bool shadowMapComparison;
  final bool shadowMapPCF;
  final bool parallelShaderCompile;
  final bool asyncOperations;

  /// Checks if a specific extension/feature is supported.
  bool supports(String extension) {
    return switch (extension.toLowerCase()) {
      'instanced_rendering' => instancedRendering,
      'multiple_render_targets' || 'mrt' => multipleRenderTargets,
      'depth_textures' => depthTextures,
      'float_textures' => floatTextures,
      'half_float_textures' => halfFloatTextures,
      'float_texture_linear' => floatTextureLinear,
      'standard_derivatives' => standardDerivatives,
      'vertex_array_objects' || 'vao' => vertexArrayObjects,
      'compute_shaders' => computeShaders,
      'geometry_shaders' => geometryShaders,
      'tessellation' => tessellation,
      'shadow_maps' => shadowMaps,
      'shadow_map_comparison' => shadowMapComparison,
      'shadow_map_pcf' => shadowMapPCF,
      'parallel_shader_compile' => parallelShaderCompile,
      'async_operations' => asyncOperations,
      _ => extensions.contains(extension),
    };
  }

  bool supportsTextureFormat(TextureFormat format) => textureFormats.contains(format);

  bool supportsCompressedFormat(CompressedTextureFormat format) => compressedTextureFormats.contains(format);

  bool supportsDepthFormat(DepthFormat format) => depthFormats.contains(format);

  int getMaxTextureSize(int dimensions) {
    return switch (dimensions) {
      1 || 2 => maxTextureSize,
      3 => maxTextureSize3D,
      _ => maxTextureSize,
    };
  }

  /// Estimates if a texture of given size would fit in memory.
  bool canFitTexture(int width, int height, {TextureFormat format = TextureFormat.rgba8}) {
    if (width > maxTextureSize || height > maxTextureSize) return false;

    final int bytesPerPixel = switch (format) {
      TextureFormat.rgba8 => 4,
      TextureFormat.rgb8 => 3,
      TextureFormat.rgba16f => 8,
      TextureFormat.rgba32f => 16,
      _ => 4,
    };

    final estimatedBytes = width * height * bytesPerPixel;
    return estimatedBytes < 100000000; // 100MB safety barrier
  }

  CapabilitiesSummary getSummary() {
    return CapabilitiesSummary(
      vendor: vendor,
      renderer: renderer,
      version: version,
      maxTextureSize: maxTextureSize,
      maxSamples: maxSamples,
      floatTextures: floatTextures,
      instancedRendering: instancedRendering,
      computeShaders: computeShaders,
      shadowMaps: shadowMaps,
    );
  }

  num getMaxAnisotropy(){
    return maxAnisotropy;
  }

	bool textureFormatReadable(int textureFormat ){
    return textureFormats.contains(TextureFormat.values[textureFormat]);
  }

	bool textureTypeReadable(int textureType ){
    return switch (textureType) {
      0 => floatTextures,
      1 => halfFloatTextures,
      _ => false,
    };
  }
  String getMaxPrecision([String? precision]){
    return precision ?? '';
  }

  void dispose(){}
}

/// Precision information for a specific precision level.
class PrecisionInfo {
  const PrecisionInfo({
    this.supported = false,
    this.rangeMin = 0,
    this.rangeMax = 0,
    this.precision = 0,
  });

  final bool supported;
  final int rangeMin;
  final int rangeMax;
  final int precision;
}

/// Precision support for vertex and fragment shaders.
class ShaderPrecisions {
  const ShaderPrecisions({
    this.lowp = const PrecisionInfo(supported: true, rangeMin: -8, rangeMax: 7, precision: 8),
    this.mediump = const PrecisionInfo(supported: true, rangeMin: -14, rangeMax: 13, precision: 10),
    this.highp = const PrecisionInfo(supported: false, rangeMin: -62, rangeMax: 61, precision: 16),
  });

  final PrecisionInfo lowp;
  final PrecisionInfo mediump;
  final PrecisionInfo highp;
}

enum TextureFormat {
  rgba8, rgb8, rg8, r8,
  rgba16f, rgb16f, rg16f, r16f,
  rgba32f, rgb32f, rg32f, r32f,
  rgba8ui, rgb8ui, rg8ui, r8ui,
  rgba16ui, rgb16ui, rg16ui, r16ui,
  rgba32ui, rgb32ui, rg32ui, r32ui,
  srgb8, srgb8Alpha8
}

enum CompressedTextureFormat {
  dxt1, dxt3, dxt5, bc4, bc5, bc6h, bc7,
  etc1, etc2Rgb, etc2Rgba8, eacR11, eacRg11,
  astc4x4, astc5x4, astc5x5, astc6x5, astc6x6, astc8x5, astc8x6, astc8x8,
  astc10x5, astc10x6, astc10x8, astc10x10, astc12x10, astc12x12,
  pvrtcRgb2bpp, pvrtcRgb4bpp, pvrtcRgba2bpp, pvrtcRgba4bpp
}

enum DepthFormat { depth16, depth24, depth32f, depth24Stencil8, depth32fStencil8 }

/// Summary of key capabilities for easy display.
class CapabilitiesSummary {
  const CapabilitiesSummary({
    required this.vendor,
    required this.renderer,
    required this.version,
    required this.maxTextureSize,
    required this.maxSamples,
    required this.floatTextures,
    required this.instancedRendering,
    required this.computeShaders,
    required this.shadowMaps,
  });

  final String vendor;
  final String renderer;
  final String version;
  final int maxTextureSize;
  final int maxSamples;
  final bool floatTextures;
  final bool instancedRendering;
  final bool computeShaders;
  final bool shadowMaps;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('GPU: $vendor $renderer');
    buffer.writeln('API: $version');
    buffer.writeln('Max Texture Size: ${maxTextureSize}x$maxTextureSize');
    buffer.writeln('Max MSAA: ${maxSamples}x');
    buffer.writeln('Float Textures: ${floatTextures ? "Yes" : "No"}');
    buffer.writeln('Instanced Rendering: ${instancedRendering ? "Yes" : "No"}');
    buffer.writeln('Compute Shaders: ${computeShaders ? "Yes" : "No"}');
    buffer.writeln('Shadow Maps: ${shadowMaps ? "Yes" : "No"}');
    return buffer.toString();
  }
}

/// Namespace replacing Kotlin's singleton object wrapper.
abstract class CapabilitiesUtils {
  /// Gets a conservative capability set for compatibility.
  static RendererCapabilities getCompatibilityCapabilities() {
    return RendererCapabilities(
      maxTextureSize: 2048,
      maxCubeMapSize: 512,
      maxVertexAttributes: 16,
      maxVertexUniforms: 256,
      maxFragmentUniforms: 256,
      maxVertexTextures: 0,
      maxFragmentTextures: 8,
      maxCombinedTextures: 8,
      maxSamples: 1,
      maxAnisotropy: 1.0,
      textureFormats: {TextureFormat.rgba8, TextureFormat.rgb8},
      floatTextures: false,
      halfFloatTextures: false,
      floatTextureLinear: false,
      instancedRendering: false,
      multipleRenderTargets: false,
      computeShaders: false,
      geometryShaders: false,
      tessellation: false,
    );
  }

  /// Gets high-end capabilities for modern hardware.
  static RendererCapabilities getHighEndCapabilities() {
    return RendererCapabilities(
      maxTextureSize: 16384,
      maxCubeMapSize: 16384,
      maxVertexAttributes: 32,
      maxVertexUniforms: 4096,
      maxFragmentUniforms: 4096,
      maxVertexTextures: 32,
      maxFragmentTextures: 32,
      maxCombinedTextures: 192,
      maxSamples: 16,
      maxAnisotropy: 16.0,
      textureFormats: TextureFormat.values.toSet(),
      compressedTextureFormats: CompressedTextureFormat.values.toSet(),
      floatTextures: true,
      halfFloatTextures: true,
      floatTextureLinear: true,
      instancedRendering: true,
      multipleRenderTargets: true,
      computeShaders: true,
      geometryShaders: true,
      tessellation: true,
      parallelShaderCompile: true,
      asyncOperations: true,
    );
  }

  /// Merges capabilities, taking the minimum of limits.
  static RendererCapabilities merge(RendererCapabilities cap1, RendererCapabilities cap2) {
    return RendererCapabilities(
      maxTextureSize: math.min(cap1.maxTextureSize, cap2.maxTextureSize),
      maxCubeMapSize: math.min(cap1.maxCubeMapSize, cap2.maxCubeMapSize),
      maxVertexAttributes: math.min(cap1.maxVertexAttributes, cap2.maxVertexAttributes),
      maxVertexUniforms: math.min(cap1.maxVertexUniforms, cap2.maxVertexUniforms),
      maxFragmentUniforms: math.min(cap1.maxFragmentUniforms, cap2.maxFragmentUniforms),
      maxVertexTextures: math.min(cap1.maxVertexTextures, cap2.maxVertexTextures),
      maxFragmentTextures: math.min(cap1.maxFragmentTextures, cap2.maxFragmentTextures),
      maxCombinedTextures: math.min(cap1.maxCombinedTextures, cap2.maxCombinedTextures),
      maxSamples: math.min(cap1.maxSamples, cap2.maxSamples),
      maxAnisotropy: math.min(cap1.maxAnisotropy, cap2.maxAnisotropy),
      textureFormats: cap1.textureFormats.intersection(cap2.textureFormats),
      compressedTextureFormats: cap1.compressedTextureFormats.intersection(cap2.compressedTextureFormats),
      depthFormats: cap1.depthFormats.intersection(cap2.depthFormats),
      extensions: cap1.extensions.intersection(cap2.extensions),
      instancedRendering: cap1.instancedRendering && cap2.instancedRendering,
      multipleRenderTargets: cap1.multipleRenderTargets && cap2.multipleRenderTargets,
      depthTextures: cap1.depthTextures && cap2.depthTextures,
      floatTextures: cap1.floatTextures && cap2.floatTextures,
      halfFloatTextures: cap1.halfFloatTextures && cap2.halfFloatTextures,
      floatTextureLinear: cap1.floatTextureLinear && cap2.floatTextureLinear,
      standardDerivatives: cap1.standardDerivatives && cap2.standardDerivatives,
      vertexArrayObjects: cap1.vertexArrayObjects && cap2.vertexArrayObjects,
      computeShaders: cap1.computeShaders && cap2.computeShaders,
      geometryShaders: cap1.geometryShaders && cap2.geometryShaders,
      tessellation: cap1.tessellation && cap2.tessellation,
      shadowMaps: cap1.shadowMaps && cap2.shadowMaps,
      shadowMapComparison: cap1.shadowMapComparison && cap2.shadowMapComparison,
      shadowMapPCF: cap1.shadowMapPCF && cap2.shadowMapPCF,
      parallelShaderCompile: cap1.parallelShaderCompile && cap2.parallelShaderCompile,
      asyncOperations: cap1.asyncOperations && cap2.asyncOperations,
    );
  }
}
