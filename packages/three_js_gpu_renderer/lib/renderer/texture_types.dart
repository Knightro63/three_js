import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// 2D Texture implementation
class Texture2D extends Texture {
  Texture2D({
    required this.width,
    required this.height,
    this.format = RGBAFormat,//TextureFormat.rgba8,
    this.filter = TextureFilter.linear,
    this.generateMipmaps = false,
    String textureName = 'Texture2D',
  }) :name = textureName;
  
  final String name;
  final int format;
  final TextureFilter filter;
  final bool generateMipmaps;

  final int width;
  final int height;

  @override
  bool needsUpdate = true;
  int version = 0;

  Float32List? _data;

  void setData(Float32List data) {
    _data = Float32List.fromList(data);
    needsUpdate = true;
    version += 1;
  }

  Uint8List? getData() => _data != null ? _data!.buffer.asUint8List() : null;
  Float32List? getFloatData() => _data != null ? Float32List.fromList(_data!) : null;

  @override
  void dispose() {
    _data = null;
  }
}

/// Cube texture for environment mapping
class CubeTextureImpl extends CubeTexture {
  CubeTextureImpl({
    required this.size,
    this.format = RGBAFormat,//TextureFormat.rgba8,
    this.filter = TextureFilter.linear,
    this.generateMipmaps = false,
    String textureName = 'CubeTexture',
  })  : id = _generateId(),
        name = textureName,
        _faces = List.generate(6, (_) => <int, Float32List>{});

  @override
  final int id;

  final String name;
  final int size;
  final int format;
  final TextureFilter filter;
  final bool generateMipmaps;

  @override
  bool needsUpdate = true;
  int version = 0;
  int get width => size;
  int get height => size;

  // List of maps representing each of the 6 faces and their respective mip levels
  final List<Map<int, Float32List>> _faces;

  void setData(Float32List data) {
    final faceSize = size * size * 4;
    for (int i = 0; i < 6; i++) {
      final start = i * faceSize;
      final end = (i + 1) * faceSize;
      _faces[i][0] = data.sublist(start, end);
    }
    needsUpdate = true;
    version += 1;
  }

  void setFaceData(CubeFace face, Float32List data, {int mip = 0}) {
    _faces[face.index][mip] = Float32List.fromList(data);
    needsUpdate = true;
    version += 1;
  }

  void setFaceDataByIndex(int faceIndex, Float32List data, {int mip = 0}) {
    setFaceData(CubeFace.values[faceIndex], data, mip: mip);
  }

  Float32List? getFaceData(CubeFace face, {int mip = 0}) {
    final faceData = _faces[face.index][mip];
    return faceData != null ? Float32List.fromList(faceData) : null;
  }

  Float32List? getFaceFloatData(CubeFace face, {int mip = 0}) => getFaceData(face, mip: mip);

  int maxMipLevel() {
    int maxLevel = 0;
    for (final faceMap in _faces) {
      if (faceMap.isNotEmpty) {
        maxLevel = math.max(maxLevel, faceMap.keys.reduce(math.max));
      }
    }
    return maxLevel;
  }

  @override
  void dispose() {
    for (final faceMap in _faces) {
      faceMap.clear();
    }
  }

  static int _nextId = 0;
  static int _generateId() => ++_nextId;
}

/// Cube face enumeration
enum CubeFace {
  positiveX,
  negativeX,
  positiveY,
  negativeY,
  positiveZ,
  negativeZ,
}

/// Texture filtering modes
enum TextureFilter {
  nearest,
  linear,
  nearestMipmapNearest,
  linearMipmapNearest,
  nearestMipmapLinear,
  linearMipmapLinear,
}

/// Texture wrapping modes
enum TextureWrap {
  repeat,
  clampToEdge,
  mirroredRepeat,
}
