import 'dart:typed_data';
import 'package:collection/collection.dart';

/**
 * Material quality levels
 */
enum MaterialQuality { LOW, MEDIUM, HIGH, ULTRA }

/**
 * Shader feature flags
 */
abstract final class ShaderFeature {
  static const String TESSELLATION = "tessellation";
  static const String GEOMETRY_SHADER = "geometry_shader";
  static const String SUBSURFACE_SCATTERING = "subsurface_scattering";
  static const String IRIDESCENCE = "iridescence";
  static const String COMPUTE = "compute";
  static const String NORMAL_MAPPING = "normal_mapping";
  static const String PARALLAX_MAPPING = "parallax_mapping";
  static const String ALPHA_TESTING = "alpha_testing";
  static const String TRANSPARENCY = "transparency";
  static const String INSTANCING = "instancing";
}

/// Extension mapping Kotlin's String.featureName extension property
extension ShaderFeatureExtension on String {
  String get featureName => this;
}

/**
 * Material feature configuration
 */
class MaterialFeature {
  bool enabled;
  double intensity;
  Map<String, dynamic> parameters;

  MaterialFeature({
    this.enabled = false,
    this.intensity = 1.0,
    this.parameters = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialFeature &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          intensity == other.intensity &&
          const MapEquality().equals(parameters, other.parameters);

  @override
  int get hashCode =>
      enabled.hashCode ^ intensity.hashCode ^ const MapEquality().hash(parameters);
}

/**
 * Material optimization settings
 */
class MaterialOptimizations {
  int maxTextureSize;
  bool useCompression;
  bool generateMipmaps;
  bool enableCaching;
  bool textureAtlasing;
  bool shaderSimplification;
  bool lodGeneration;

  MaterialOptimizations({
    this.maxTextureSize = 2048,
    this.useCompression = true,
    this.generateMipmaps = true,
    this.enableCaching = true,
    this.textureAtlasing = false,
    this.shaderSimplification = false,
    this.lodGeneration = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialOptimizations &&
          runtimeType == other.runtimeType &&
          maxTextureSize == other.maxTextureSize &&
          useCompression == other.useCompression &&
          generateMipmaps == other.generateMipmaps &&
          enableCaching == other.enableCaching &&
          textureAtlasing == other.textureAtlasing &&
          shaderSimplification == other.shaderSimplification &&
          lodGeneration == other.lodGeneration;

  @override
  int get hashCode =>
      maxTextureSize.hashCode ^
      useCompression.hashCode ^
      generateMipmaps.hashCode ^
      enableCaching.hashCode ^
      textureAtlasing.hashCode ^
      shaderSimplification.hashCode ^
      lodGeneration.hashCode;
}

/**
 * Shader compilation result
 */
class ShaderCompilationResult {
  final bool success;
  final List<String> errors;
  final List<String> warnings;
  final Uint8List? bytecode;
  final ShaderReflectionData? reflectionData;

  ShaderCompilationResult({
    required this.success,
    this.errors = const [],
    this.warnings = const [],
    this.bytecode,
    this.reflectionData,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShaderCompilationResult) return false;

    return success == other.success &&
        const ListEquality().equals(errors, other.errors) &&
        const ListEquality().equals(warnings, other.warnings) &&
        const ListEquality().equals(bytecode, other.bytecode) &&
        reflectionData == other.reflectionData;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        const ListEquality().hash(errors) ^
        const ListEquality().hash(warnings) ^
        const ListEquality().hash(bytecode) ^
        reflectionData.hashCode;
  }
}

/**
 * Shader reflection data
 */
class ShaderReflectionData {
  final List<UniformInfo> uniforms;
  final List<AttributeInfo> attributes;
  final List<TextureInfo> textures;
  final List<BufferInfo> buffers;

  ShaderReflectionData({
    this.uniforms = const [],
    this.attributes = const [],
    this.textures = const [],
    this.buffers = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderReflectionData &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(uniforms, other.uniforms) &&
          const ListEquality().equals(attributes, other.attributes) &&
          const ListEquality().equals(textures, other.textures) &&
          const ListEquality().equals(buffers, other.buffers);

  @override
  int get hashCode =>
      const ListEquality().hash(uniforms) ^
      const ListEquality().hash(attributes) ^
      const ListEquality().hash(textures) ^
      const ListEquality().hash(buffers);
}

/**
 * Uniform variable information
 */
class UniformInfo {
  final String name;
  final String type;
  final int location;
  final int size;

  UniformInfo({
    required this.name,
    required this.type,
    required this.location,
    required this.size,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniformInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          location == other.location &&
          size == other.size;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ location.hashCode ^ size.hashCode;
}

/**
 * Attribute variable information
 */
class AttributeInfo {
  final String name;
  final String type;
  final int location;

  AttributeInfo({
    required this.name,
    required this.type,
    required this.location,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributeInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          location == other.location;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ location.hashCode;
}

/**
 * Texture binding information
 */
class TextureInfo {
  final String name;
  final int binding;
  final String type;

  TextureInfo({
    required this.name,
    required this.binding,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextureInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          binding == other.binding &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ binding.hashCode ^ type.hashCode;
}

/**
 * Buffer binding information
 */
class BufferInfo {
  final String name;
  final int binding;
  final int size;

  BufferInfo({
    required this.name,
    required this.binding,
    required this.size,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BufferInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          binding == other.binding &&
          size == other.size;

  @override
  int get hashCode => name.hashCode ^ binding.hashCode ^ size.hashCode;
}

/**
 * Hardware capabilities for material adaptation
 */
class HardwareCapabilities {
  final int maxTextureMemory; 
  final int maxTextureSize;
  final double maxAnisotropy;
  final Set<String> supportedTextureFormats;
  final bool supportsComputeShaders;
  final bool supportsGeometryShaders;
  final bool supportsTessellation;
  final int maxVertexAttributes;
  final int maxFragmentTextures;
  final int maxUniformBufferSize;
  final DeviceTier deviceTier;

  HardwareCapabilities({
    this.maxTextureMemory = 1024 * 1024 * 1024, 
    this.maxTextureSize = 4096,
    this.maxAnisotropy = 16.0,
    this.supportedTextureFormats = const {"RGBA8", "RGB8", "DXT1", "DXT5"},
    this.supportsComputeShaders = true,
    this.supportsGeometryShaders = true,
    this.supportsTessellation = false,
    this.maxVertexAttributes = 16,
    this.maxFragmentTextures = 32,
    this.maxUniformBufferSize = 64 * 1024,
    this.deviceTier = DeviceTier.HIGH,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HardwareCapabilities &&
          runtimeType == other.runtimeType &&
          maxTextureMemory == other.maxTextureMemory &&
          maxTextureSize == other.maxTextureSize &&
          maxAnisotropy == other.maxAnisotropy &&
          const SetEquality().equals(supportedTextureFormats, other.supportedTextureFormats) &&
          supportsComputeShaders == other.supportsComputeShaders &&
          supportsGeometryShaders == other.supportsGeometryShaders &&
          supportsTessellation == other.supportsTessellation &&
          maxVertexAttributes == other.maxVertexAttributes &&
          maxFragmentTextures == other.maxFragmentTextures &&
          maxUniformBufferSize == other.maxUniformBufferSize &&
          deviceTier == other.deviceTier;

  @override
  int get hashCode =>
      maxTextureMemory.hashCode ^
      maxTextureSize.hashCode ^
      maxAnisotropy.hashCode ^
      const SetEquality().hash(supportedTextureFormats) ^
      supportsComputeShaders.hashCode ^
      supportsGeometryShaders.hashCode ^
      supportsTessellation.hashCode ^
      maxVertexAttributes.hashCode ^
      maxFragmentTextures.hashCode ^
      maxUniformBufferSize.hashCode ^
      deviceTier.hashCode;
}

/**
 * Device performance tier
 */
enum DeviceTier { LOW, MEDIUM, HIGH, ULTRA }

/**
 * Material validation result
 */
sealed class MaterialValidationResult {}

final class MaterialValidationValid extends MaterialValidationResult {}

final class MaterialValidationInvalid extends MaterialValidationResult {
  final List<String> errors;
  MaterialValidationInvalid(this.errors);
}

final class MaterialValidationWarning extends MaterialValidationResult {
  final List<String> warnings;
  MaterialValidationWarning(this.warnings);
}

/**
 * Material processing result
 */
sealed class MaterialProcessingResult<T> {}

final class MaterialProcessingSuccess<T> extends MaterialProcessingResult<T> {
  final T result;
  MaterialProcessingSuccess(this.result);
}

final class MaterialProcessingError<T> extends MaterialProcessingResult<T> {
  final String message;
  final Object? cause; 
  MaterialProcessingError(this.message, [this.cause]);
}

/**
 * Texture optimization settings
 */
class TextureOptimizationSettings {
  final int maxSize;
  final TextureCompression compression;
  final bool generateMipmaps;
  final double quality;

  TextureOptimizationSettings({
    this.maxSize = 2048,
    this.compression = TextureCompression.AUTO,
    this.generateMipmaps = true,
    this.quality = 0.8,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextureOptimizationSettings &&
          runtimeType == other.runtimeType &&
          maxSize == other.maxSize &&
          compression == other.compression &&
          generateMipmaps == other.generateMipmaps &&
          quality == other.quality;

  @override
  int get hashCode =>
      maxSize.hashCode ^ compression.hashCode ^ generateMipmaps.hashCode ^ quality.hashCode;
}

enum TextureCompression { AUTO }