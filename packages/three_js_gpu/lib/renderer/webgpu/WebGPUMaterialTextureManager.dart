import 'dart:typed_data';
import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/renderer/webgpu/RenderStatsTracker.dart';
import 'package:three_js_gpu/renderer/webgpu/WebGPUTexture.dart'; // To interface with Material classes

class MaterialTextureBinding {
  final GpuBindGroup bindGroup;
  final GpuBindGroupLayout layout;
  const MaterialTextureBinding(this.bindGroup, this.layout);
}

class _CachedTexture {
  final GpuTexture gpuTexture;
  final GpuTextureView view;
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
  final String format;
  final GpuTextureDimension dimension;
  final GpuTextureViewDimension viewDimension;
  final int bytesPerTexel;
  final int trackedBytes;
  final TypedData data; // Can be Float32List or Uint8List

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
    GpuTextureDimension? dimension,
    GpuTextureViewDimension? viewDimension,
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

class WebGPUMaterialTextureManager {
  final GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;

  GpuDevice? _currentDevice;
  GpuSampler? _defaultSampler;
  
  final Map<_LayoutKey, GpuBindGroupLayout> _layoutCache = {};
  final Map<_BindGroupKey, MaterialTextureBinding> _bindGroupCache = {};
  final Map<int, _CachedTexture> _textureCache = {};

  _CachedTexture? _fallbackAlbedo;
  _CachedTexture? _fallbackNormal;
  _CachedTexture? _fallbackVolume;

  WebGPUMaterialTextureManager({
    required GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  void onDeviceReady(GpuDevice device) {
    if (_currentDevice == device) return;
    dispose();
    _currentDevice = device;
    
    _defaultSampler = device.createSampler(label: "Material Texture Sampler");

    _fallbackAlbedo = _createFallbackTexture(device: device,data: Uint8List.fromList([255, 255, 255, 255]));
    _fallbackNormal = _createFallbackTexture(device: device, data: Uint8List.fromList([127, 127, 255, 255]));
    _fallbackVolume = _createFallbackTexture(
      device: device,
      data: Uint8List.fromList([255, 255, 255, 255]),
      depth: 1,
      dimension: GpuTextureDimension.d3,
      viewDimension: GpuTextureViewDimension.d3,
      label: "MaterialVolumeFallback",
    );
  }

  MaterialTextureBinding? prepare({
    required MaterialDescriptor descriptor,
    required EngineMaterial? material,
    required bool useAlbedo,
    required bool useNormal,
    required bool useVolume,
  }) {
    if (!useAlbedo && !useNormal && !useVolume) return null;

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

    final List<GpuBindGroupEntry> entries = [];

    if (useAlbedo) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.texture2D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
      final textureView = albedoTexture?.view ?? _fallbackAlbedo?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(GpuBindGroupEntry(binding: textureBinding.binding, resource: GpuBindingResourceTexture(textureView)));
        entries.add(GpuBindGroupEntry(binding: samplerBinding.binding, resource: GpuBindingResourceSampler(sampler)));
      }
    }

    if (useNormal) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.texture2D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.sampler);
      final textureView = normalTexture?.view ?? _fallbackNormal?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(GpuBindGroupEntry(binding: textureBinding.binding, resource: GpuBindingResourceTexture(textureView)));
        entries.add(GpuBindGroupEntry(binding: samplerBinding.binding, resource: GpuBindingResourceSampler(sampler)));
      }
    }

    if (useVolume) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.texture3D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.sampler);
      final textureView = volumeTexture?.view ?? _fallbackVolume?.view;
      if (textureBinding != null && samplerBinding != null && textureView != null) {
        entries.add(GpuBindGroupEntry(binding: textureBinding.binding, resource: GpuBindingResourceTexture(textureView)));
        entries.add(GpuBindGroupEntry(binding: samplerBinding.binding, resource: GpuBindingResourceSampler(sampler)));
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

  Texture2D? _albedoSource(EngineMaterial? material) {
    if (material is MeshBasicMaterial) return material.map as Texture2D?;
    if (material is MeshStandardMaterial) return material.map as Texture2D?;
    return null;
  }

  Texture2D? _normalSource(EngineMaterial? material) {
    if (material is MeshStandardMaterial) return material.normalMap as Texture2D?;
    return null;
  }

  Data3DTexture? _volumeSource(EngineMaterial? material) {
    if (material is MeshBasicMaterial) return material.map as Data3DTexture?;
    return null;
  }

  GpuBindGroupLayout? _createLayout(MaterialDescriptor descriptor, _LayoutKey key, GpuDevice device) {
    final List<GpuBindGroupLayoutEntry> entries = [];

    if (key.useAlbedo) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.texture2D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (key.useNormal) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.texture2D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.normalMap, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (key.useVolume) {
      final textureBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.texture3D);
      final samplerBinding = _bindingFor(descriptor, MaterialBindingSource.volumeTexture, MaterialBindingType.sampler);
      if (textureBinding != null && samplerBinding != null) {
        entries.add(_textureLayoutEntry(textureBinding.binding, dimension: GpuTextureViewDimension.d3));
        entries.add(_samplerLayoutEntry(samplerBinding.binding));
      }
    }

    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.binding.compareTo(b.binding));

    return device.createBindGroupLayout(GpuBindGroupLayoutDescriptor(
      entries: entries,
      label: "Material Texture Layout (${key.useAlbedo}, ${key.useNormal}, ${key.useVolume})",
    ));
  }

  GpuBindGroupLayoutEntry _textureLayoutEntry(int binding, {GpuTextureViewDimension dimension = GpuTextureViewDimension.d2}) {
    return GpuBindGroupLayoutEntry(
      binding: binding,
      visibility: GpuShaderStage.fragment,
      texture: GpuTextureBindingLayout(
        sampleType: GpuTextureSampleType.float,
        viewDimension: dimension,
        multisampled: false,
      ),
    );
  }

  GpuBindGroupLayoutEntry _samplerLayoutEntry(int binding) {
    return GpuBindGroupLayoutEntry(
      binding: binding,
      visibility: GpuShaderStage.fragment,
      sampler: const GpuSamplerBindingLayout(GpuSamplerBindingType.filtering),
    );
  }

  BindingElement? _bindingFor(MaterialDescriptor descriptor, MaterialBindingSource source, MaterialBindingType type) {
    for (final b in descriptor.bindings) {
      if (b.source == source && b.type == type) return b;
    }
    return null;
  }

  _CachedTexture? _acquireTexture(GpuDevice device, Texture? texture) {
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

    final GpuTextureFormat formatEnum = upload.format == "rgba32float"
        ? GpuTextureFormat.rgba32Float
        : (upload.format == "rgba8unorm-srgb" ? GpuTextureFormat.rgba8UnormSrgb : GpuTextureFormat.rgba8Unorm);

    final gpuTexture = device.createTexture(
      width: upload.width,
      height: upload.height,
      depthOrArrayLayers: upload.depth,
      mipLevelCount: 1,
      sampleCount: 1,
      dimension: upload.dimension,
      format: formatEnum,
      usage: GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst,
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
    if (texture is Texture2D) {
      final upload = _textureDataFor(texture.format, texture.getData(), texture.getFloatData(), null, texture.width, texture.height, 1);
      return upload?.copyWith(dimension: GpuTextureDimension.d2, viewDimension: GpuTextureViewDimension.d2);
    }
    if (texture is Data3DTexture) {
      final upload = _textureDataFor(texture.format, texture.getData().isNotEmpty ? texture.getData() : null, texture.getFloatData(), texture.getIntData(), texture.width, texture.height, texture.depth);
      return upload?.copyWith(dimension: GpuTextureDimension.d3, viewDimension: GpuTextureViewDimension.d3);
    }
    return null;
  }

  _TextureUpload? _textureDataFor(
    TextureFormat format,
    Uint8List? byteData,
    Float32List? floatData,
    Int32List? intData,
    int width,
    int height,
    int depth,
  ) {
    if (width <= 0 || height <= 0 || depth <= 0) return null;

    if (floatData != null && format == TextureFormat.rgba32F) {
      return _TextureUpload(
        width: width,
        height: height,
        depth: depth,
        format: "rgba32float",
        dimension: GpuTextureDimension.d2,
        viewDimension: GpuTextureViewDimension.d2,
        bytesPerTexel: 16,
        trackedBytes: floatData.length * 4,
        data: floatData,
      );
    }

    if (byteData != null) {
      return _TextureUpload(
        width: width,
        height: height,
        depth: depth,
        format: (format == TextureFormat.srgb8Alpha8) ? "rgba8unorm-srgb" : "rgba8unorm",
        dimension: GpuTextureDimension.d2,
        viewDimension: GpuTextureViewDimension.d2,
        bytesPerTexel: 4,
        trackedBytes: byteData.length,
        data: byteData,
      );
    }

    if (intData != null) {
      final typed = Uint8List(intData.length);
      for (int i = 0; i < intData.length; i++) {
        typed[i] = intData[i].clamp(0, 255);
      }
      return _TextureUpload(
        width: width,
        height: height,
        depth: depth,
        format: "rgba8unorm",
        dimension: GpuTextureDimension.d2,
        viewDimension: GpuTextureViewDimension.d2,
        bytesPerTexel: 4,
        trackedBytes: typed.length,
        data: typed,
      );
    }

    if (floatData != null) {
      final typed = Uint8List(floatData.length);
      for (int i = 0; i < floatData.length; i++) {
        typed[i] = (floatData[i].clamp(0.0, 1.0) * 255.0).toInt().clamp(0, 255);
      }
      return _TextureUpload(
        width: width,
        height: height,
        depth: depth,
        format: "rgba8unorm",
        dimension: GpuTextureDimension.d2,
        viewDimension: GpuTextureViewDimension.d2,
        bytesPerTexel: 4,
        trackedBytes: typed.length,
        data: typed,
      );
    }

    return null;
  }

  _CachedTexture? _createFallbackTexture({
    required GpuDevice device,
    required Uint8List data,
    int depth = 1,
    GpuTextureDimension dimension = GpuTextureDimension.d2,
    GpuTextureViewDimension viewDimension = GpuTextureViewDimension.d2,
    String label = "MaterialTextureFallback",
  }) {
    final gpuTexture = device.createTexture(
      width: 1,
      height: 1,
      depthOrArrayLayers: depth,
      mipLevelCount: 1,
      sampleCount: 1,
      dimension: dimension,
      format: GpuTextureFormat.rgba8Unorm,
      usage: GpuTextureUsage.textureBinding | GpuTextureUsage.copyDst,
      label: label,
    );

    final upload = _TextureUpload(
      width: 1,
      height: 1,
      depth: depth,
      format: "rgba8unorm",
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

  void _writeTextureData(GpuDevice device, GpuTexture texture, _TextureUpload upload) {
    final destination = GpuImageCopyTexture(
      texture: texture,
      mipLevel: 0,
      origin: const GpuOrigin3D(x: 0, y: 0, z: 0),
    );

    final layout = GpuTextureDataLayout(
      offset: 0,
      bytesPerRow: upload.width * upload.bytesPerTexel,
      rowsPerImage: upload.height,
    );

    final size = GpuExtent3D(
      width: upload.width,
      height: upload.height,
      depthOrArrayLayers: upload.depth,
    );

    device.queue.writeTexture(
      destination: destination,
      data: upload.data.buffer.asByteData(upload.data.offsetInBytes, upload.data.lengthInBytes),
      dataLayout: layout,
      size: size,
    );
  }
}

// Global mockup structures if missing from three_js core bindings
enum MaterialBindingSource { albedoMap, normalMap, volumeTexture }
enum MaterialBindingType { texture2D, texture3D, sampler }

class MaterialDescriptor {
  final List<BindingElement> bindings;
  const MaterialDescriptor(this.bindings);
}

class BindingElement {
  final int binding;
  final MaterialBindingSource source;
  final MaterialBindingType type;
  const BindingElement({required this.binding, required this.source, required this.type});
}
