import 'dart:typed_data';
import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import '../material/material_description_registry.dart';
import 'render_stats_tracker.dart'; // To interface with Material classes

class MaterialTextureBinding {
  final gpux.GpuBindGroup bindGroup;
  final gpux.GpuBindGroupLayout layout;
  const MaterialTextureBinding(this.bindGroup, this.layout);
}

class _CachedTexture {
  final gpux.GpuTexture gpuTexture;
  final gpux.GpuTextureView view;
  int version;
  int width;
  int height;
  int depth;
  int trackedBytes;

  _CachedTexture({
    required this.gpuTexture,
    required this.view,
    required this.version,
    required this.width,
    required this.height,
    required this.depth,
    required this.trackedBytes,
  });
}

class _LayoutKey {
  final bool useAlbedo;
  final bool useNormal;
  final bool useVolume;

  const _LayoutKey(this.useAlbedo, this.useNormal, this.useVolume);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LayoutKey &&
          runtimeType == other.runtimeType &&
          useAlbedo == other.useAlbedo &&
          useNormal == other.useNormal &&
          useVolume == other.useVolume;

  @override
  int get hashCode => useAlbedo.hashCode ^ useNormal.hashCode ^ useVolume.hashCode;
}

class _BindGroupKey {
  final _LayoutKey layoutKey;
  final int? albedoId;
  final int albedoVersion;
  final int? normalId;
  final int normalVersion;
  final int? volumeId;
  final int volumeVersion;

  const _BindGroupKey(
    this.layoutKey,
    this.albedoId,
    this.albedoVersion,
    this.normalId,
    this.normalVersion,
    this.volumeId,
    this.volumeVersion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BindGroupKey &&
          runtimeType == other.runtimeType &&
          layoutKey == other.layoutKey &&
          albedoId == other.albedoId &&
          albedoVersion == other.albedoVersion &&
          normalId == other.normalId &&
          normalVersion == other.normalVersion &&
          volumeId == other.volumeId &&
          volumeVersion == other.volumeVersion;

  @override
  int get hashCode => Object.hash(
        layoutKey,
        albedoId,
        albedoVersion,
        normalId,
        normalVersion,
        volumeId,
        volumeVersion,
      );
}

class _TextureUpload {
  final int width;
  final int height;
  final int depth;
  final gpux.GpuTextureFormat format;
  final gpux.GpuTextureDimension dimension;
  final gpux.GpuTextureViewDimension viewDimension;
  final int bytesPerTexel;
  final int trackedBytes;
  final Uint8List data; // Can be Float32List or Uint8List

  const _TextureUpload({
    required this.width,
    required this.height,
    required this.depth,
    required this.format,
    required this.dimension,
    required this.viewDimension,
    required this.bytesPerTexel,
    required this.trackedBytes,
    required this.data,
  });

  _TextureUpload copyWith({
    gpux.GpuTextureDimension? dimension,
    gpux.GpuTextureViewDimension? viewDimension,
  }) {
    return _TextureUpload(
      width: width,
      height: height,
      depth: depth,
      format: format,
      dimension: dimension ?? this.dimension,
      viewDimension: viewDimension ?? this.viewDimension,
      bytesPerTexel: bytesPerTexel,
      trackedBytes: trackedBytes,
      data: data,
    );
  }
}

class GpuMaterialTextureManager {
  final gpux.GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;

  gpux.GpuDevice? _currentDevice;
  gpux.GpuSampler? _defaultSampler;
  
  final Map<_LayoutKey, gpux.GpuBindGroupLayout> _layoutCache = {};
  final Map<_BindGroupKey, MaterialTextureBinding> _bindGroupCache = {};
  final Map<int, _CachedTexture> _textureCache = {};

  _CachedTexture? _fallbackAlbedo;
  _CachedTexture? _fallbackNormal;
  _CachedTexture? _fallbackVolume;

  GpuMaterialTextureManager({
    required gpux.GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  void onDeviceReady(gpux.GpuDevice device) {
    if (_currentDevice == device) return;
    dispose();
    _currentDevice = device;
    
    _defaultSampler = device.createSampler(
      label: "Material Texture Sampler",
      addressModeU: gpux.GpuAddressMode.repeat,
      addressModeV: gpux.GpuAddressMode.repeat,
      magFilter: gpux.GpuFilterMode.linear,
      minFilter: gpux.GpuFilterMode.linear,
      mipmapFilter: gpux.GpuMipmapFilterMode.linear,
    );

    _fallbackAlbedo = _createFallbackTexture(device: device,data: Uint8List.fromList([255, 255, 255, 255]));
    _fallbackNormal = _createFallbackTexture(device: device, data: Uint8List.fromList([127, 127, 255, 255]));
    _fallbackVolume = _createFallbackTexture(
      device: device,
      data: Uint8List.fromList([255, 255, 255, 255]),
      depth: 1,
      dimension: gpux.GpuTextureDimension.d3,
      viewDimension: gpux.GpuTextureViewDimension.d3,
      label: "MaterialVolumeFallback",
    );
  }

  MaterialTextureBinding? prepare({
    required MaterialDescriptor descriptor,
    required Material? material,
    required bool useAlbedo,
    required bool useNormal,
    required bool useVolume,
  }) {
    final device = _currentDevice ?? _deviceProvider();
    if (device == null) return null;
    if (_currentDevice != device) onDeviceReady(device);

    final sampler = _defaultSampler;
    if (sampler == null) return null;

    final layoutKey = _LayoutKey(useAlbedo, useNormal, useVolume);
    final layout = _layoutCache.putIfAbsent(layoutKey, () {
      return _createLayout(descriptor, layoutKey, device)!;
    });

    final albedoTexture = useAlbedo ? (_acquireTexture(device, _albedoSource(material)) ?? _fallbackAlbedo) : _fallbackAlbedo;
    final normalTexture = useNormal ? (_acquireTexture(device, _normalSource(material)) ?? _fallbackNormal) : _fallbackNormal;
    final volumeTexture = useVolume ? (_acquireTexture(device, _volumeSource(material)) ?? _fallbackVolume) : _fallbackVolume;
    final albedoKey = albedoTexture?.gpuTexture.hashCode;
    final normalKey = normalTexture?.gpuTexture.hashCode;
    final volumeKey = volumeTexture?.gpuTexture.hashCode;

    final albedoVersion = albedoTexture?.version ?? -1;
    final normalVersion = normalTexture?.version ?? -1;
    final volumeVersion = volumeTexture?.version ?? -1;

    final cacheKey = _BindGroupKey(
      layoutKey,
      albedoKey,
      albedoVersion,
      normalKey,
      normalVersion,
      volumeKey,
      volumeVersion,
    );

    if (_bindGroupCache.containsKey(cacheKey)) {
      return _bindGroupCache[cacheKey];
    }

    final List<gpux.GpuBindGroupEntry> entries = [];

    if (useAlbedo) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
      final textureView = albedoTexture?.view ?? _fallbackAlbedo?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(gpux.GpuBindGroupEntry.textureView(binding: textureBinding.binding, view: textureView));
        entries.add(gpux.GpuBindGroupEntry.sampler(binding: samplerBinding.binding, sampler: sampler));
      }
    }

    if (useNormal) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.texture2d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.sampler);
      final textureView = normalTexture?.view ?? _fallbackNormal?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(gpux.GpuBindGroupEntry.textureView(binding: textureBinding.binding, view: textureView));
        entries.add(gpux.GpuBindGroupEntry.sampler(binding: samplerBinding.binding, sampler:sampler));
      }
    }

    if (useVolume) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.texture3d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.sampler);
      final textureView = volumeTexture?.view ?? _fallbackVolume?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(gpux.GpuBindGroupEntry.textureView(binding: textureBinding.binding, view: textureView));
        entries.add(gpux.GpuBindGroupEntry.sampler(binding: samplerBinding.binding, sampler: sampler));
      }
    }

    if (entries.isEmpty) return null;

    // Mimics sorting entries by binding location programmatically
    entries.sort((a, b) => a.binding.compareTo(b.binding));

    final bindGroup = device.createBindGroup(
      layout: layout,
      entries: entries,
      label: "Material Texture BindGroup",
    );

    final binding = MaterialTextureBinding(bindGroup, layout);
    _bindGroupCache[cacheKey] = binding;
    return binding;
  }

  void dispose() {
    _bindGroupCache.clear();
    for (final cached in _textureCache.values) {
      _statsTracker?.recordTextureDisposed(cached.trackedBytes);
      try { cached.gpuTexture.destroy(); } catch (_) {}
    }
    _textureCache.clear();

    if (_fallbackAlbedo != null) {
      _statsTracker?.recordTextureDisposed(_fallbackAlbedo!.trackedBytes);
      try { _fallbackAlbedo!.gpuTexture.destroy(); } catch (_) {}
    }
    if (_fallbackNormal != null) {
      _statsTracker?.recordTextureDisposed(_fallbackNormal!.trackedBytes);
      try { _fallbackNormal!.gpuTexture.destroy(); } catch (_) {}
    }
    if (_fallbackVolume != null) {
      _statsTracker?.recordTextureDisposed(_fallbackVolume!.trackedBytes);
      try { _fallbackVolume!.gpuTexture.destroy(); } catch (_) {}
    }

    _fallbackAlbedo = null;
    _fallbackNormal = null;
    _fallbackVolume = null;
    _defaultSampler = null;
    _layoutCache.clear();
    _currentDevice = null;
  }

  Texture? _albedoSource(Material? material) {
    return material?.map;
  }

  Texture? _normalSource(Material? material) {
    return material?.normalMap;
  }

  Data3DTexture? _volumeSource(Material? material) {
    return material?.map as Data3DTexture?;
  }

  gpux.GpuBindGroupLayout? _createLayout(MaterialDescriptor descriptor, _LayoutKey key, gpux.GpuDevice device) {
    final List<gpux.GpuBindGroupLayoutEntry> entries = [];

    if (key.useAlbedo) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (key.useNormal) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.texture2d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (key.useVolume) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.texture3d);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding, dimension: gpux.GpuTextureViewDimension.d3));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.binding.compareTo(b.binding));

    return device.createBindGroupLayout(
      entries,
      label: "Material Texture Layout (${key.useAlbedo}, ${key.useNormal}, ${key.useVolume})",
    );
  }

  gpux.GpuBindGroupLayoutEntry _textureLayoutEntry(int binding, {gpux.GpuTextureViewDimension dimension = gpux.GpuTextureViewDimension.d2}) {
    return gpux.GpuBindGroupLayoutEntry.texture(
      binding: binding,
      visibility: gpux.GpuShaderStage.fragment,
      sampleType: gpux.GpuTextureSampleType.float,
      viewDimension: dimension,
      multisampled: false,
    );
  }

  gpux.GpuBindGroupLayoutEntry _samplerLayoutEntry(int binding) {
    return gpux.GpuBindGroupLayoutEntry.sampler(
      binding: binding,
      visibility: gpux.GpuShaderStage.fragment,
      type: gpux.GpuSamplerBindingType.filtering,
    );
  }

  MaterialBinding? _bindingFor(MaterialDescriptor descriptor, MaterialBindingSource source, MaterialBindingType type) {
    for (final b in descriptor.bindings) {
      if (b.source == source && b.type == type) return b;
    }
    return null;
  }

  _CachedTexture? _acquireTexture(gpux.GpuDevice device, Texture? texture) {
    if (texture == null) return null;
    final upload = _buildTextureUpload(texture);
    if (upload == null) return null;
    final cached = _textureCache[texture.id];
    if (cached != null &&
        cached.version == texture.version &&
        cached.width == upload.width &&
        cached.height == upload.height &&
        cached.depth == upload.depth) {
      return cached;
    }

    if (cached != null) {
      _statsTracker?.recordTextureDisposed(cached.trackedBytes);
      try { cached.gpuTexture.destroy(); } catch (_) {}
    }

    final gpux.GpuTextureFormat formatEnum = upload.format == "rgba32float"
        ? gpux.GpuTextureFormat.rgba32Float
        : (upload.format == "rgba8unorm-srgb" ? gpux.GpuTextureFormat.rgba8UnormSrgb : gpux.GpuTextureFormat.rgba8Unorm);

    final gpuTexture = device.createTexture(
      width: upload.width,
      height: upload.height,
      depthOrArrayLayers: upload.depth,
      mipLevelCount: 1,
      sampleCount: 1,
      dimension: upload.dimension,
      format: formatEnum,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
      label: texture.name.isEmpty ? "MaterialTexture${texture.id}" : texture.name,
    );

    _writeTextureData(device, gpuTexture, upload);
    final view = gpuTexture.createView(dimension: upload.viewDimension);

    final cachedTexture = _CachedTexture(
      gpuTexture: gpuTexture,
      view: view,
      version: texture.version,
      width: upload.width,
      height: upload.height,
      depth: upload.depth,
      trackedBytes: upload.trackedBytes,
    );

    _textureCache[texture.id] = cachedTexture;
    _statsTracker?.recordTextureCreated(upload.trackedBytes);
    texture.needsUpdate = false;

    return cachedTexture;
  }

  _TextureUpload? _buildTextureUpload(Texture texture) {
    if (texture is Data3DTexture) {
      final upload = _textureDataFor(
        WebGlToWebGpuFormat.convert(texture.format),//gpux.GpuTextureFormat.values[texture.format], 
        texture.image.data, 
        texture.image.width, 
        texture.image.height, 
        texture.image.depth
      );
      return upload?.copyWith(dimension: gpux.GpuTextureDimension.d3, viewDimension: gpux.GpuTextureViewDimension.d3);
    }
    else{
      final upload = _textureDataFor(
        WebGlToWebGpuFormat.convert(texture.format),//gpux.GpuTextureFormat.values[texture.format],
        texture.image.data,
        texture.image.width, 
        texture.image.height, 
        1
      );
      return upload?.copyWith(dimension: gpux.GpuTextureDimension.d2, viewDimension: gpux.GpuTextureViewDimension.d2);
    }
  }

  _TextureUpload? _textureDataFor(
    gpux.GpuTextureFormat format,
    Uint8List? byteData,
    int width,
    int height,
    int depth,
  ) {
    if (byteData != null) {
      return _TextureUpload(
        width: width,
        height: height,
        depth: depth,
        format: format,
        dimension: gpux.GpuTextureDimension.d2,
        viewDimension: gpux.GpuTextureViewDimension.d2,
        bytesPerTexel: 4,
        trackedBytes: byteData.length,
        data: byteData,
      );
    }
    return null;
  }

  _CachedTexture? _createFallbackTexture({
    required gpux.GpuDevice device,
    required Uint8List data,
    int depth = 1,
    gpux.GpuTextureDimension dimension = gpux.GpuTextureDimension.d2,
    gpux.GpuTextureViewDimension viewDimension = gpux.GpuTextureViewDimension.d2,
    String label = "MaterialTextureFallback",
  }) {
    final gpuTexture = device.createTexture(
      width: 1,
      height: 1,
      depthOrArrayLayers: depth,
      mipLevelCount: 1,
      sampleCount: 1,
      dimension: dimension,
      format: gpux.GpuTextureFormat.rgba8Unorm,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
      label: label,
    );

    final upload = _TextureUpload(
      width: 1,
      height: 1,
      depth: depth,
      format: gpux.GpuTextureFormat.rgba8Unorm,
      dimension: dimension,
      viewDimension: viewDimension,
      bytesPerTexel: 4,
      trackedBytes: data.length,
      data: data,
    );

    _writeTextureData(device, gpuTexture, upload);
    final view = gpuTexture.createView(dimension: viewDimension);
    final trackedBytes = data.length * depth;
    _statsTracker?.recordTextureCreated(trackedBytes);

    return _CachedTexture(
      gpuTexture: gpuTexture,
      view: view,
      version: 0,
      width: 1,
      height: 1,
      depth: depth,
      trackedBytes: trackedBytes,
    );
  }

  void _writeTextureData(gpux.GpuDevice device, gpux.GpuTexture texture, _TextureUpload upload) {
    device.queue.writeTexture(
      texture: texture,
      mipLevel: 0,
      originX: 0, 
      originY: 0, 
      originZ: 0,
      data: upload.data,//.buffer.asByteData(upload.data.offsetInBytes, upload.data.lengthInBytes).buffer.asUint8List(),
      dataOffset: 0,
      bytesPerRow: upload.width * upload.bytesPerTexel,
      rowsPerImage: upload.height,
      width: upload.width,
      height: upload.height,
      depthOrArrayLayers: upload.depth,
    );
  }
}


class WebGlToWebGpuFormat {
  // WebGL 1 & 2 constant token allocations mapped directly to modern WebGPU enums
  static const int GL_RGBA = 1023;       // Your active texture format constant value
  static const int GL_RGBA_NATIVE = 6408; // Standard WebGL RGBA token
  static const int GL_RGB = 6407;        // Standard WebGL RGB token
  static const int GL_LUMINANCE = 6409;  // Grayscale / Alpha markers
  static const int GL_ALPHA = 6406;

  static gpux.GpuTextureFormat convert(int webGlFormat) {
    switch (webGlFormat) {
      case GL_RGBA:
      case GL_RGBA_NATIVE:
        return gpux.GpuTextureFormat.rgba8Unorm; // Native equivalent for standard 32-bit textures
      case GL_RGB:
        // WebGPU does not natively support 24-bit RGB due to memory channel strides. 
        // We fallback safely to 32-bit RGBA exactly like modern graphics architectures handle it!
        return gpux.GpuTextureFormat.rgba8Unorm; 
      case GL_LUMINANCE:
      case GL_ALPHA:
        return gpux.GpuTextureFormat.r8Unorm; // Single 8-bit channel fallback
      default:
        // Safe uniform baseline fallback if it receives an unknown constant integer
        return gpux.GpuTextureFormat.rgba8Unorm;
    }
  }
}