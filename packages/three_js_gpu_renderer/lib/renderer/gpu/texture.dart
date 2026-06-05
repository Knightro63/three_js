import 'dart:typed_data';
import 'package:gpux/gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart'; // Adjust based on your exact gpux package paths

/// Texture descriptor for creation.
class TextureDescriptor {
  final String? label;
  final int width;
  final int height;
  final int depth;
  final gpux.GpuTextureFormat format;
  late final int usage;
  final int mipLevelCount;
  final int sampleCount;

  TextureDescriptor({
    this.label,
    required this.width,
    required this.height,
    this.depth = 1,
    this.format = gpux.GpuTextureFormat.rgba8Unorm,
    int? usage,
    this.mipLevelCount = 1,
    this.sampleCount = 1,
  }){
    this.usage = usage ?? (gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst);
  }
}

/// Gpu texture implementation.
/// T031: 2D/3D texture handling and sampling.
class GpuTexture {
  final gpux.GpuDevice device;
  final TextureDescriptor descriptor;

  gpux.GpuTexture? _texture;
  gpux.GpuTextureView? _view;

  GpuTexture(this.device, this.descriptor);

  /// Creates the GPU texture.
  void create() {
    try {
      // Maps the standard Kotlin 'when' format translation down to gpux-native strong enums
      final gpux.GpuTextureFormat gpuFormat = descriptor.format;

      final dimension = descriptor.depth > 1 
          ? gpux.GpuTextureDimension.d3 
          : gpux.GpuTextureDimension.d2;

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
        usage: gpux.GpuTextureUsageFlags(descriptor.usage),
      );

      if (_texture == null) {
        throw StateError("Texture creation failed: Handle returned null.");
      }

      _view = _texture!.createView();
    } catch (e) {
      console.error("ERROR: Texture creation failed: ${e.toString()}");
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
      console.error("ERROR: Texture upload failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Gets the GPU texture handle instance.
  gpux.GpuTexture? getTexture() => _texture;

  /// Gets the default texture view for active loop shaders.
  gpux.GpuTextureView? getView() => _view;

  /// Creates a custom dynamic texture view context layout window.
  gpux.GpuTextureView? createView({
    gpux.GpuTextureFormat? format,
    gpux.GpuTextureViewDimension? dimension,
    gpux.GpuTextureUsageFlags? usage,
    int baseMipLevel = 0,
    int? mipLevelCount,
    int baseArrayLayer = 0,
    int? arrayLayerCount,
    gpux.GpuTextureAspect aspect = gpux.GpuTextureAspect.all,
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
  gpux.GpuTextureFormat getFormat() => descriptor.format;

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