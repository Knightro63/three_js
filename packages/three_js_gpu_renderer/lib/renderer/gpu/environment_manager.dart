import 'dart:math' as math;
import 'dart:typed_data';
import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import '../texture_types.dart';
import 'render_stats_tracker.dart'; // To interface with CubeTexture, Texture2D, etc.

class EnvironmentBinding {
  final gpux.GpuBindGroup bindGroup;
  final gpux.GpuBindGroupLayout layout;
  final int mipCount;
  final bool usingFallbackEnvironment;
  final bool usingFallbackBrdf;

  const EnvironmentBinding({
    required this.bindGroup,
    required this.layout,
    required this.mipCount,
    this.usingFallbackEnvironment = false,
    this.usingFallbackBrdf = false,
  });
}

/// Handles uploading prefiltered environment cubemaps to GPU memory and
/// prepares sampler/bind group objects for the Gpu renderer.
class GpuEnvironmentManager {
  static const int _halfByteStride = 8; // rgba16f = 4 * 2 bytes
  static const int _brdfBytesPerPixel = 8;
  static const int _fallbackBrdfId = -3;
  static const int _fallbackVersion = -1;
  static const int _fallbackBrdfSize = 32;

  final gpux.GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;
  final GpuResourceRegistry _resourceRegistry = GpuResourceRegistry();

  gpux.GpuTextureView? _cubeView;
  gpux.GpuSampler? _sampler;
  gpux.GpuTextureView? _brdfView;
  gpux.GpuSampler? _brdfSampler;
  gpux.GpuBindGroupLayout? _bindGroupLayout;
  gpux.GpuBindGroup? _bindGroup;

  int _lastTextureId = -1;
  int _mipCount = 1;
  int _trackedBytes = 0;
  int _lastBrdfId = -1;
  int _lastBrdfVersion = -1;
  int _trackedBrdfBytes = 0;

  GpuEnvironmentManager({
    required gpux.GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  EnvironmentBinding? prepare(Texture? cube, Texture? brdf) {
    final device = _deviceProvider();
    if (device == null) return null;

    if (cube == null) {
      dispose();
      return null;
    }

    final sourceId = cube.id;
    if (_bindGroup != null && sourceId == _lastTextureId) {
      final layout = _bindGroupLayout;
      if (layout != null) {
        return EnvironmentBinding(bindGroup: _bindGroup!, layout: layout, mipCount: _mipCount);
      }
    }

    _uploadEnvironment(device, cube);
    _createSampler(device);
    _ensureBrdfResources(device, brdf);
    _createBindGroup(device);

    final layout = _bindGroupLayout;
    final group = _bindGroup;
    if (layout == null || group == null) return null;

    return EnvironmentBinding(bindGroup: group, layout: layout, mipCount: _mipCount);
  }

  void dispose() {
    if (_trackedBytes > 0) {
      _statsTracker?.recordTextureDisposed(_trackedBytes);
      _trackedBytes = 0;
    }
    if (_trackedBrdfBytes > 0) {
      _statsTracker?.recordTextureDisposed(_trackedBrdfBytes);
      _trackedBrdfBytes = 0;
    }
    _resourceRegistry.disposeAll();
    _resourceRegistry.reset();
    
    _cubeView = null;
    _sampler = null;
    _brdfView = null;
    _brdfSampler = null;
    _bindGroup = null;
    _bindGroupLayout = null;
    _lastTextureId = -1;
    _lastBrdfId = -1;
    _lastBrdfVersion = -1;
  }

  void _uploadEnvironment(gpux.GpuDevice device, Texture cube) {
    final chain = _collectMipChain(cube);
    _mipCount = chain.mipCount;

    if (_trackedBytes > 0) {
      _statsTracker?.recordTextureDisposed(_trackedBytes);
      _trackedBytes = 0;
    }

    _resourceRegistry.disposeAll();
    _resourceRegistry.reset();
    _cubeView = null;
    _bindGroup = null;

    final texture = device.createTexture(
      width: cube.image.width,
      height: cube.image.height,
      depthOrArrayLayers: 6,
      mipLevelCount: _mipCount,
      sampleCount: 1,
      dimension: gpux.GpuTextureDimension.d2,
      format: gpux.GpuTextureFormat.rgba16Float,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
      label: "IBL Prefilter Cubemap",
    );
    _resourceRegistry.trackTexture(texture);
    _cubeView = texture.createView(
      label: "IBL Prefilter Cube View",
      dimension: gpux.GpuTextureViewDimension.cube,
      mipLevelCount: _mipCount,
    );

    _trackedBytes = chain.totalBytes;
    _statsTracker?.recordTextureCreated(_trackedBytes);

    for (int level = 0; level < _mipCount; level++) {
      final mipSize = math.max(1, cube.image.width >> level);
      final rowBytes = mipSize * _halfByteStride;
      final alignedRowBytes = _alignRowPitch(rowBytes);

      for (int face = 0; face < 6; face++) {
        final key = _FaceMipKey(face, level);
        final rawData = chain.faceMipData[key];
        if (rawData == null) continue;

        final uploadBytes = (alignedRowBytes == rowBytes)
            ? rawData
            : _padRows(rawData, rowBytes, alignedRowBytes, mipSize);

        device.queue.writeTexture(
          texture: texture,
          mipLevel: level,
          originX: 0, originY: 0, originZ: face,
          data: uploadBytes.buffer.asByteData(uploadBytes.offsetInBytes, uploadBytes.lengthInBytes).buffer.asUint8List(),
          dataOffset: 0,
          bytesPerRow: alignedRowBytes,
          rowsPerImage: mipSize,
          width: mipSize,
          height: mipSize,
          depthOrArrayLayers: 1,
        );
      }
    }
    _lastTextureId = cube.id;
  }

  void _ensureBrdfResources(gpux.GpuDevice device, Texture? brdf) {
    final sourceId = brdf?.id ?? _fallbackBrdfId;
    final sourceVersion = brdf?.version ?? _fallbackVersion;

    if (_brdfView != null && sourceId == _lastBrdfId && sourceVersion == _lastBrdfVersion) {
      brdf?.needsUpdate = false;
      return;
    }

    _brdfView = null;
    _brdfSampler = null;

    final width = brdf?.image.width ?? _fallbackBrdfSize;
    final height = brdf?.image.height ?? _fallbackBrdfSize;
    final Uint8List data = (brdf?.image.data as TypedDataList?)?.buffer.asUint8List()  ?? _fallbackBrdfData(width, height);

    final texture = device.createTexture(
      width: width,
      height: height,
      depthOrArrayLayers: 1,
      mipLevelCount: 1,
      sampleCount: 1,
      dimension: gpux.GpuTextureDimension.d2,
      format: gpux.GpuTextureFormat.rgba16Float,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
      label: "IBL BRDF LUT",
    );
    _resourceRegistry.trackTexture(texture);
    
    _brdfView = texture.createView(
      label: "IBL BRDF View",
      dimension: gpux.GpuTextureViewDimension.d2,
    );

    _brdfSampler = device.createSampler(
      magFilter: gpux.GpuFilterMode.linear,
      minFilter: gpux.GpuFilterMode.linear,
      mipmapFilter: gpux.GpuMipmapFilterMode.linear,
      lodMinClamp: 0.0,
      lodMaxClamp: 0.0,
      label: "IBL BRDF Sampler",
    );

    _uploadBrdfData(device, texture, data, width, height);
    _trackedBrdfBytes = width * height * _brdfBytesPerPixel;
    _statsTracker?.recordTextureCreated(_trackedBrdfBytes);

    _lastBrdfId = sourceId;
    _lastBrdfVersion = sourceVersion;
    brdf?.needsUpdate = false;
  }

  void _createSampler(gpux.GpuDevice device) {
    _sampler = device.createSampler(
      magFilter: gpux.GpuFilterMode.linear,
      minFilter: gpux.GpuFilterMode.linear,
      mipmapFilter: gpux.GpuMipmapFilterMode.linear,
      lodMinClamp: 0.0,
      lodMaxClamp: math.max(0, _mipCount - 1).toDouble(),
      label: "IBL Prefilter Sampler",
    );
  }

  void _createBindGroup(gpux.GpuDevice device) {
    final layout = _bindGroupLayout ?? _createBindGroupLayout(device);
    final view = _cubeView;
    final samplerHandle = _sampler;
    final brdfViewHandle = _brdfView;
    final brdfSamplerHandle = _brdfSampler;

    if (view == null || samplerHandle == null || brdfViewHandle == null || brdfSamplerHandle == null) return;

    _bindGroup = device.createBindGroup(
      layout: layout,
      entries: [
        gpux.GpuBindGroupEntry.textureView(binding: 0, view: view),
        gpux.GpuBindGroupEntry.sampler(binding: 1, sampler: samplerHandle),
        gpux.GpuBindGroupEntry.textureView(binding: 2, view: brdfViewHandle),
        gpux.GpuBindGroupEntry.sampler(binding: 3, sampler: brdfSamplerHandle),
      ],
      label: "IBL Prefilter Bind Group",
    );
  }

  gpux.GpuBindGroupLayout _createBindGroupLayout(gpux.GpuDevice device) {
    _bindGroupLayout = device.createBindGroupLayout(
      [
        const gpux.GpuBindGroupLayoutEntry.texture(
          binding: 0,
          visibility: gpux.GpuShaderStage.fragment,
          sampleType: gpux.GpuTextureSampleType.float,
          viewDimension: gpux.GpuTextureViewDimension.cube,
          multisampled: false,
        ),
        const gpux.GpuBindGroupLayoutEntry.sampler(
          binding: 1,
          visibility: gpux.GpuShaderStage.fragment,
          type: gpux.GpuSamplerBindingType.filtering,
        ),
        const gpux.GpuBindGroupLayoutEntry.texture(
          binding: 2,
          visibility: gpux.GpuShaderStage.fragment,
          sampleType: gpux.GpuTextureSampleType.float,
          viewDimension: gpux.GpuTextureViewDimension.d2,
          multisampled: false,
        ),
        const gpux.GpuBindGroupLayoutEntry.sampler(
          binding: 3,
          visibility: gpux.GpuShaderStage.fragment,
          type: gpux.GpuSamplerBindingType.filtering,
        ),
      ],
      label: "IBL Prefilter Bind Group Layout",
    );
    return _bindGroupLayout!;
  }

  _MipChainResult _collectMipChain(Texture cube) {
    final int mipCount = (cube is CubeTextureImpl) ? cube.maxMipLevel() + 1 : 1;
    final faceMipData = <_FaceMipKey, Uint8List>{};
    int totalBytes = 0;
    final int baseSize = cube.image.width;

    for (int level = 0; level < mipCount; level++) {
      final mipSize = math.max(1, baseSize >> level);
      final floatCountPerFace = mipSize * mipSize * 4;
      final bytesPerFace = _halfByteStride * mipSize * mipSize;
      totalBytes += bytesPerFace * 6;

      for (int face = 0; face < 6; face++) {
        Float32List? floatData;
        if (cube is CubeTextureImpl) {
          floatData = cube.getFaceData(CubeFace.values[face], mip: level);
        } else {
          floatData = _getFaceFloatDataAlternative(cube, face);
        }

        floatData ??= Float32List(floatCountPerFace);
        faceMipData[_FaceMipKey(face, level)] = _floatArrayToHalfBytes(floatData);
      }
    }
    return _MipChainResult(mipCount, faceMipData, totalBytes);
  }

  Float32List? _getFaceFloatDataAlternative(Texture cube, int face) {
    final dataList = cube.image.data;
    if (dataList == null) return null;

    // 1. Calculate how many elements exist per individual cube face layer
    // For a cube map, the total length is split perfectly across 6 distinct faces
    final int totalElements = dataList.length;
    final int elementsPerFace = totalElements ~/ 6; 
    
    // 2. Compute the exact byte stride offset based on element storage type sizes
    // Every 32-bit float element takes up exactly 4 bytes of memory
    final int bytesPerElement = 4;
    final int byteOffsetForFace = face * elementsPerFace * bytesPerElement;

    try {
      // FIX: Pass the fully aligned byte offset calculation into your array view constructor
      final Float32List floatData = dataList.buffer.asFloat32List(
        byteOffsetForFace, 
        elementsPerFace,
      );
      return floatData;
    } catch (e) {
      // Fallback: If the byte offset fails alignment validation rules, parse via Uint8List
      final int byteOffsetUint8 = face * elementsPerFace;
      final Uint8List bytes = dataList.buffer.asUint8List(
        byteOffsetUint8, 
        elementsPerFace,
      );
      
      final result = Float32List(bytes.length);
      for (int i = 0; i < bytes.length; i++) {
        result[i] = bytes[i] / 255.0;
      }
      return result;
    }
  }

  Uint8List _floatArrayToHalfBytes(Float32List source) {
    final result = Uint8List(source.length * 2);
    int outIndex = 0;
    for (final value in source) {
      final half = _floatToHalf(value);
      result[outIndex++] = half & 0xFF;
      result[outIndex++] = (half >> 8) & 0xFF;
    }
    return result;
  }

  int _floatToHalf(double value) {
    if (value.isNaN) return 0x7E00;
    if (value == double.infinity) return 0x7C00;
    if (value == -double.infinity) return 0xFC00;

    // Use ByteData views to extract standard single-precision Float32 bits representation safely
    final bd = ByteData(4)..setFloat32(0, value);
    final bits = bd.getUint32(0);

    final sign = (value < 0.0) ? 0x8000 : 0;
    int exponent = ((bits >> 23) & 0xFF) - 127 + 15;
    int mantissa = bits & 0x7FFFFF;

    if (exponent <= 0) {
      if (exponent < -10) {
        return sign;
      } else {
        mantissa |= 0x800000;
        final shift = 14 - exponent;
        final halfMantissa = mantissa >> shift;
        return sign | (halfMantissa + ((mantissa >> (shift - 1)) & 1));
      }
    }
    if (exponent >= 0x1F) return sign | 0x7C00;

    final halfMantissa = mantissa >> 13;
    final half = sign | (exponent << 10) | halfMantissa;
    return half + ((mantissa >> 12) & 1);
  }

  int _alignRowPitch(int rowBytes) {
    const alignment = 256;
    return (rowBytes % alignment == 0) ? rowBytes : ((rowBytes ~/ alignment) + 1) * alignment;
  }

  Uint8List _padRows(Uint8List data, int rowBytes, int alignedRowBytes, int rows) {
    final padded = Uint8List(alignedRowBytes * rows);
    for (int y = 0; y < rows; y++) {
      padded.setRange(y * alignedRowBytes, y * alignedRowBytes + rowBytes, data, y * rowBytes);
    }
    return padded;
  }

  void _uploadBrdfData(gpux.GpuDevice device, gpux.GpuTexture texture, Uint8List data, int width, int height) {
    device.queue.writeTexture(
      texture: texture,
      mipLevel: 0,
      originX: 0, originY: 0, originZ: 0,
      data: data,//.asByteData(data.offsetInBytes, data.lengthInBytes).buffer.asUint8List(),
      dataOffset: 0,
      bytesPerRow: width * _brdfBytesPerPixel,
      rowsPerImage: height,
      width: width,
      height: height,
      depthOrArrayLayers: 1,
    );
  }

  Uint8List _fallbackBrdfData(int width, int height) {
    final data = Float32List(width * height * 2);
    for (int i = 0; i < width * height; i++) {
      data[i * 2] = 0.0;
      data[i * 2 + 1] = 1.0;
    }
    return data.buffer.asUint8List();
  }
}

// ==========================================
// MAP RECYCLING LOOKUP DATA HELPERS
// ==========================================

class _FaceMipKey {
  final int face;
  final int level;
  const _FaceMipKey(this.face, this.level);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FaceMipKey && runtimeType == other.runtimeType && face == other.face && level == other.level;

  @override
  int get hashCode => face.hashCode ^ level.hashCode;
}

class _MipChainResult {
  final int mipCount;
  final Map<_FaceMipKey, Uint8List> faceMipData;
  final int totalBytes;
  const _MipChainResult(this.mipCount, this.faceMipData, this.totalBytes);
}

class GpuResourceRegistry {
  final List<gpux.GpuTexture> _textures = [];
  void trackTexture(gpux.GpuTexture t) => _textures.add(t);
  void disposeAll() {
    for (final t in _textures) {
      try { t.destroy(); } catch (_) {}
    }
  }
  void reset() => _textures.clear();
}
