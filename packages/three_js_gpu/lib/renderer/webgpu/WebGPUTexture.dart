import 'dart:typed_data';
import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux package paths

/// Texture descriptor for creation.
class TextureDescriptor {
  final String? label;
  final int width;
  final int height;
  final int depth;
  final TextureFormat format;
  final int usage;
  final int mipLevelCount;
  final int sampleCount;

  const TextureDescriptor({
    this.label,
    required this.width,
    required this.height,
    this.depth = 1,
    this.format = TextureFormat.rgba8Unorm,
    this.usage = GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst,
    this.mipLevelCount = 1,
    this.sampleCount = 1,
  });
}

/// WebGPU texture implementation.
/// T031: 2D/3D texture handling and sampling.
class WebGPUTexture {
  final GpuDevice device;
  final TextureDescriptor descriptor;

  GpuTexture? _texture;
  GpuTextureView? _view;

  WebGPUTexture(this.device, this.descriptor);

  /// Creates the GPU texture.
  void create() {
    try {
      // Maps the standard Kotlin 'when' format translation down to gpux-native strong enums
      final GpuTextureFormat gpuFormat;
      switch (descriptor.format) {
        case TextureFormat.rgba8Unorm:
          gpuFormat = GpuTextureFormat.rgba8Unorm;
          break;
        case TextureFormat.rgba8Srgb:
          gpuFormat = GpuTextureFormat.rgba8UnormSrgb;
          break;
        case TextureFormat.bgra8Unorm:
          gpuFormat = GpuTextureFormat.bgra8Unorm;
          break;
        case TextureFormat.bgra8Srgb:
          gpuFormat = GpuTextureFormat.bgra8UnormSrgb;
          break;
        case TextureFormat.depth24Plus:
          gpuFormat = GpuTextureFormat.depth24Plus;
          break;
        case TextureFormat.depth32Float:
          gpuFormat = GpuTextureFormat.depth32Float;
          break;
      }

      final dimension = descriptor.depth > 1 
          ? GpuTextureDimension.d3 
          : GpuTextureDimension.d2;

      // Safe, strongly-typed creation descriptor instantiation matching gpux API
      _texture = device.createTexture(
        label: descriptor.label ?? '',
        width: descriptor.width,
        height: descriptor.height,
        depthOrArrayLayers: descriptor.depth,
        mipLevelCount: descriptor.mipLevelCount,
        sampleCount: descriptor.sampleCount,
        dimension: dimension,
        format: gpuFormat,
        usage: descriptor.usage,
      );

      if (_texture == null) {
        throw StateError("Texture creation failed: Handle returned null.");
      }

      _view = _texture!.createView();
    } catch (e) {
      print("ERROR: Texture creation failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Uploads raw image byte arrays straight into the texture memory block.
  /// @param data Extracted source image pixel buffer array
  void upload(Uint8List data, int width, int height, {int? depth}) {
    final activeTexture = _texture;
    if (activeTexture == null) {
      throw StateError("Texture not created. Call create() before uploading data.");
    }

    try {
      final targetDepth = depth ?? descriptor.depth;

      // Submit byte block data straight down into the GPU hardware queue
      device.queue.writeTexture(
        texture: activeTexture,
        mipLevel: 0,
        originX: 0, originY: 0, originZ: 0,
        data: data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes).buffer.asUint8List(),
        dataOffset: 0,
        bytesPerRow: width * 4, // 4 bytes per pixel channel for standard raw RGBA maps
        rowsPerImage: height,
        width: width,
        height: height,
        depthOrArrayLayers: targetDepth,
      );
    } catch (e) {
      print("ERROR: Texture upload failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Gets the GPU texture handle instance.
  GpuTexture? getTexture() => _texture;

  /// Gets the default texture view for active loop shaders.
  GpuTextureView? getView() => _view;

  /// Creates a custom dynamic texture view context layout window.
  GpuTextureView? createView({
    GpuTextureFormat? format,
    GpuTextureViewDimension? dimension,
    GpuTextureUsageFlags? usage,
    int baseMipLevel = 0,
    int? mipLevelCount,
    int baseArrayLayer = 0,
    int? arrayLayerCount,
    GpuTextureAspect aspect = GpuTextureAspect.all,
    String swizzle = 'rgba',
    String label = '',
  }) {
    final activeTexture = _texture;
    if (activeTexture == null) return null;

    return activeTexture.createView(
      format: format,
      dimension: dimension,
      usage: usage,
      baseMipLevel: baseMipLevel,
      mipLevelCount: mipLevelCount,
      baseArrayLayer: baseArrayLayer,
      arrayLayerCount: arrayLayerCount,
      aspect: aspect,
      swizzle: swizzle,
      label: label,
    );
  }

  /// Gets texture width, height, and depth metadata.
  TextureExtent getDimensions() {
    return TextureExtent(
      width: descriptor.width,
      height: descriptor.height,
      depth: descriptor.depth,
    );
  }

  /// Gets baseline texture configuration format.
  TextureFormat getFormat() => descriptor.format;

  /// Disposes the texture and immediately releases hardware GPU space.
  void dispose() {
    _texture?.destroy();
    _texture = null;
    _view = null;
  }
}

/// Simple tuple data wrapper container replacing Kotlin's Triple
class TextureExtent {
  final int width;
  final int height;
  final int depth;
  const TextureExtent({required this.width, required this.height, required this.depth});
}

/// Enum identifiers representing texture layout types
enum TextureFormat {
  rgba8Unorm,
  rgba8Srgb,
  bgra8Unorm,
  bgra8Srgb,
  depth24Plus,
  depth32Float,
}
