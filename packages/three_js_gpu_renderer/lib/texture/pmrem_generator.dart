import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import '../renderer/texture_types.dart'; 
import 'package:three_js_math/three_js_math.dart'; 

final _origin = Vector3();

class PMREMGeneratorOptions{
  int size;
  late final Vector3 position;
  final int? sampleCount;
  final int? roughnessLevels;

  PMREMGeneratorOptions({
    Vector3? position,
    this.size = 256,
    this.sampleCount,
    this.roughnessLevels,
  }){
    this.position = position ?? _origin;
  }
}

/// PMREMGenerator - Pre-filtered Mipmap Roughness Environment Map Generator.
///
/// Produces filtered cube maps suitable for physically based lighting by
/// importance sampling the source environment with a GGX distribution.
class PMREMGenerator {
  final dynamic renderer;

  late int _lodMax;
  late int _cubeSize;

  static const int _defaultCubeSize = 256;
  static const int _defaultRoughnessLevels = 6;

  PMREMGenerator(this.renderer){
    _lodMax = 0;
    _cubeSize = 0;
  }

  /// Generates a pre-filtered PMREM directly from a live 3D Scene graph.
  ///
  /// [scene] The Three.js target scene containing your environment objects.
  /// [cubeSize] The desired resolution for each rendered face.
  RenderTarget fromScene(
    Scene scene, {
    double sigma = 0,
    double near = 0.1,
    double far = 100,
    PMREMGeneratorOptions? options,
  }) {
    options ??= PMREMGeneratorOptions();
    _setSize(options.size);

    final int cubeSize = options.size;
    final int sampleCount = options.sampleCount ?? 256;
    final int roughnessLevels = options.roughnessLevels ?? _defaultRoughnessLevels;

    // 1. Instantiate the 6 perspective virtual camera projections matching the cube orientations
    final List<PerspectiveCamera> faceCameras = List.generate(6, (_) {
      return PerspectiveCamera(90.0, 1.0, near, far);
    });

    // Configure the look-at transforms across all 6 target cardinal axis faces
    faceCameras[0].quaternion.setFromAxisAngle(Vector3(0, 1, 0), -math.pi / 2); // POSITIVE_X
    faceCameras[1].quaternion.setFromAxisAngle(Vector3(0, 1, 0), math.pi / 2);  // NEGATIVE_X
    faceCameras[2].quaternion.setFromAxisAngle(Vector3(1, 0, 0), math.pi / 2);  // POSITIVE_Y
    faceCameras[3].quaternion.setFromAxisAngle(Vector3(1, 0, 0), -math.pi / 2); // NEGATIVE_Y
    faceCameras[4].quaternion.setFromAxisAngle(Vector3(0, 1, 0), 0);            // POSITIVE_Z
    faceCameras[5].quaternion.setFromAxisAngle(Vector3(0, 1, 0), math.pi);       // NEGATIVE_Z

    final List<Uint8List> facesRawData = List.generate(6, (_) => Uint8List(cubeSize * cubeSize * 4));

    // 2. Loop through and execute your custom renderPass pipelines per face context
    for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
      final camera = faceCameras[faceIdx];
      camera.updateMatrixWorld();

      // INTEGRATION NOTE: Use your existing gpux pass architecture to render 
      // the scene from the camera look-at onto your offscreen texture pipeline targets.
      // E.g., renderer.renderSceneToBuffer(scene, camera, facesRawData[faceIdx]);
      
      _renderSceneToBufferFallback(scene, camera, facesRawData[faceIdx], cubeSize);
    }

    // 3. Wrap raw byte frame arrays safely into a standard three_js_core CubeTexture
    final List<ImageElement> faceImages = List.generate(6, (index) {
      return ImageElement(data: facesRawData[index], width: cubeSize, height: cubeSize);
    });

    final capturedCubeTexture = CubeTexture(faceImages)
      ..name = "\${scene.name ?? 'scene'}_captured_cube";

    // 4. Adjust initial filtering behavior if a custom radial sigma blur is passed
    // If sigma > 0, you can scale or mutate the internal sample counts dynamically to blur inputs
    final effectiveSampleCount = sigma > 0 ? (sampleCount * (1.0 + sigma)).round() : sampleCount;

    return RenderTarget(
      3 * math.max(_cubeSize, 16 * 7), 
      4 * _cubeSize
    )..texture = fromCubeMap(
      cubeTexture: capturedCubeTexture,
      sampleCount: effectiveSampleCount,
      roughnessLevels: roughnessLevels,
    );
  }

  /// Private placeholder mapping data states straight down to your texture pass hooks
  void _renderSceneToBufferFallback(Scene scene, Camera camera, Uint8List targetBuffer, int size) {
    // If you haven't wired up texture mapping extraction logic from gpux frame commands yet,
    // this acts as an allocation trace layout loop.
  }

  void _setSize(int cubeSize) {
    _lodMax = MathUtils.log2(cubeSize.toDouble()).floor();
    _cubeSize = math.pow(2, _lodMax).toInt();
  }

  /// Generate a pre-filtered environment map from an existing cube texture.
  ///
  /// [cubeTexture] Source texture (must contain data for all six faces).
  /// [sampleCount] Number of samples per texel used for integration.
  /// [roughnessLevels] Number of roughness levels to generate (≥ 1).
  CubeTexture fromCubeMap({
    required CubeTexture cubeTexture,
    int sampleCount = 256,
    int roughnessLevels = _defaultRoughnessLevels,
  }) {
    assert(cubeTexture.images != null && cubeTexture.images.length == 6, "Cube texture must have data for all faces");
    assert(sampleCount > 0, "sampleCount must be > 0 (was \$sampleCount)");
    assert(roughnessLevels > 0, "roughnessLevels must be > 0 (was \$roughnessLevels)");

    final int baseSize = cubeTexture.image?.width ?? _defaultCubeSize;
    final int clampedLevels = roughnessLevels.clamp(1, 1 + _log2Floor(baseSize));
    final List<List<Uint8List>> mipData = [];
    int currentSize = baseSize;

    for (int level = 0; level < clampedLevels; level++) {
      final double roughness = clampedLevels == 1 
          ? 0.0 
          : math.pow(level / (clampedLevels - 1), 2.0).toDouble();
          
      final List<Uint8List> levelData = _prefilterLevel(
        cubeTexture: cubeTexture,
        targetSize: currentSize,
        roughness: roughness,
        sampleCount: roughness == 0.0 ? 1 : sampleCount,
      );
      mipData.add(levelData);

      if (currentSize > 1) {
        currentSize = math.max(1, currentSize ~/ 2);
      }
    }

    final List<Uint8List> baseLevel = mipData.first;
    final List<ImageElement> faceImages = List.generate(6, (index) {
      return ImageElement(
        data: baseLevel[index],
        width: baseSize,
        height: baseSize,
      );
    });

    final result = CubeTexture(faceImages)
      ..name = "\${cubeTexture.name}_pmrem"
      ..generateMipmaps = mipData.length > 1;

    if (mipData.length > 1) {
      result.mipmaps = List.generate(mipData.length - 1, (level) {
        final levelBuffers = mipData[level + 1];
        return List.generate(6, (faceIdx) => ImageElement(
          data: levelBuffers[faceIdx],
          width: math.max(1, baseSize >> (level + 1)),
          height: math.max(1, baseSize >> (level + 1)),
        ));
      });
    }

    result.needsUpdate = true;
    return result;
  }

  /// Convert an equirectangular texture to a cube map and pre-filter it.
  ///
  /// [texture] Equirectangular 2D texture (Texture2D required).
  /// [cubeSize] Desired cube face resolution.
  CubeTexture fromEquirectangular({
    required dynamic texture,
    int cubeSize = _defaultCubeSize,
    int sampleCount = 256,
    int roughnessLevels = _defaultRoughnessLevels,
  }) {
    if (texture is! Texture2D) {
      throw ArgumentError("PMREMGenerator expects a Texture2D for equirectangular input");
    }
    
    final source = texture;
    final List<Uint8List> faces = List.generate(6, (_) => Uint8List(cubeSize * cubeSize * 4));

    for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
      final Uint8List target = faces[faceIdx];
      for (int y = 0; y < cubeSize; y++) {
        for (int x = 0; x < cubeSize; x++) {
          final double u = (x + 0.5) / cubeSize;
          final double v = (y + 0.5) / cubeSize;
          final Vector3 direction = _faceTexelDirection(faceIdx, u, v);
          final Vector3 color = _sampleEquirectangular(source, direction);
          final int index = (y * cubeSize + x) * 4;

          target[index] = (color.x.clamp(0.0, 1.0) * 255.0).round();
          target[index + 1] = (color.y.clamp(0.0, 1.0) * 255.0).round();
          target[index + 2] = (color.z.clamp(0.0, 1.0) * 255.0).round();
          target[index + 3] = 255;
        }
      }
    }

    final List<ImageElement> faceImages = List.generate(6, (index) {
      return ImageElement(data: faces[index], width: cubeSize, height: cubeSize);
    });

    final cubeTexture = CubeTexture(faceImages)..name = "\${texture.name}_cubemap";

    return fromCubeMap(
      cubeTexture: cubeTexture,
      sampleCount: sampleCount,
      roughnessLevels: roughnessLevels,
    );
  }

  /// Generate GGX importance sampling directions for a given roughness.
  List<Vector3> generateGGXSamples(double roughness, int sampleCount) {
    assert(sampleCount > 0, "sampleCount must be > 0 (was \$sampleCount)");
    final List<Vector3> samples = List.generate(sampleCount, (_) => Vector3(), growable: true);
    final double clampedRoughness = roughness.clamp(0.0, 1.0).clamp(1e-4, 1.0);

    for (int i = 0; i < sampleCount; i++) {
      final Vector2 xi = _hammersley(i, sampleCount);
      samples[i] = _importanceSampleGGX(xi, clampedRoughness);
    }
    return samples;
  }

  /// Compute third-order spherical harmonics coefficients from the cube map.
  SphericalHarmonics3 generateSphericalHarmonics({
    required CubeTexture cubeTexture,
    int sampleCount = 1024,
  }) {
    assert(sampleCount > 0, "sampleCount must be > 0 (was \$sampleCount)");
    final List<Vector3> coefficients = List.generate(9, (_) => Vector3(0.0, 0.0, 0.0));
    final double weight = (4.0 * math.pi) / sampleCount;

    for (var direction in _uniformSampleDirections(sampleCount)) {
      final Vector3 color = _sampleCubeTexture(cubeTexture, direction);
      final Float32List basis = _shBasis(direction);
      for (int i = 0; i < coefficients.length; i++) {
        final Vector3 contribution = color.clone().scale(basis[i] * weight);
        coefficients[i].add(contribution);
      }
    }
    
    // Pass the matching 9-coefficient Vector3 array directly to SphericalHarmonics3
    return SphericalHarmonics3().set(coefficients);
  }

  void dispose() {
    // No GPU allocations are owned directly by PMREMGenerator.
  }
  List<Uint8List> _prefilterLevel({
    required CubeTexture cubeTexture,
    required int targetSize,
    required double roughness,
    required int sampleCount,
  }) {
    final List<Uint8List> levelData = List.generate(6, (_) => Uint8List(targetSize * targetSize * 4));

    for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
      final Uint8List target = levelData[faceIdx];
      for (int y = 0; y < targetSize; y++) {
        for (int x = 0; x < targetSize; x++) {
          final double u = (x + 0.5) / targetSize;
          final double v = (y + 0.5) / targetSize;
          final Vector3 direction = _faceTexelDirection(faceIdx, u, v);
          
          final Vector3 color = roughness <= 0.0
              ? _sampleCubeTexture(cubeTexture, direction)
              : _prefilterColor(cubeTexture, direction, roughness, sampleCount);

          final int index = (y * targetSize + x) * 4;
          target[index] = (color.x.clamp(0.0, 1.0) * 255.0).round();
          target[index + 1] = (color.y.clamp(0.0, 1.0) * 255.0).round();
          target[index + 2] = (color.z.clamp(0.0, 1.0) * 255.0).round();
          target[index + 3] = 255;
        }
      }
    }
    return levelData;
  }

  Vector3 _prefilterColor(
    CubeTexture cubeTexture,
    Vector3 direction,
    double roughness,
    int sampleCount,
  ) {
    final Vector3 normal = direction.clone().normalize();
    final basis = _createTangentBasis(normal);
    final Vector3 tangent = basis.tangent;
    final Vector3 bitangent = basis.bitangent;
    final Vector3 normalizedNormal = basis.normal;

    final List<Vector3> samples = generateGGXSamples(roughness, sampleCount);
    double totalWeight = 0.0;
    final Vector3 result = Vector3(0.0, 0.0, 0.0);

    for (var sample in samples) {
      final Vector3 worldSample = _toWorldSpace(sample, tangent, bitangent, normalizedNormal);
      final double ndotl = normalizedNormal.dot(worldSample).clamp(0.0, double.maxFinite);

      if (ndotl > 0.0) {
        final Vector3 color = _sampleCubeTexture(cubeTexture, worldSample).scale(ndotl);
        result.add(color);
        totalWeight += ndotl;
      }
    }
    return totalWeight > 0.0 ? result.divideScalar(totalWeight) : result;
  }

  Vector3 _faceTexelDirection(int faceIdx, double u, double v) {
    final double nx = 2.0 * u - 1.0;
    final double ny = 2.0 * v - 1.0;
    late final Vector3 direction;

    switch (faceIdx) {
      case 0: // POSITIVE_X
        direction = Vector3(1.0, -ny, -nx);
        break;
      case 1: // NEGATIVE_X
        direction = Vector3(-1.0, -ny, nx);
        break;
      case 2: // POSITIVE_Y
        direction = Vector3(nx, 1.0, ny);
        break;
      case 3: // NEGATIVE_Y
        direction = Vector3(nx, -1.0, -ny);
        break;
      case 4: // POSITIVE_Z
        direction = Vector3(nx, -ny, 1.0);
        break;
      case 5: // NEGATIVE_Z
        direction = Vector3(-nx, -ny, -1.0);
        break;
      default:
        direction = Vector3();
    }
    return direction.normalize();
  }

  Vector3 _sampleEquirectangular(Texture texture, Vector3 direction) {
    final int width = texture.image?.width ?? 1;
    final int height = texture.image?.height ?? 1;
    final dynamic sourceData = texture.image?.data;

    if (sourceData == null) {
      throw StateError("Texture \${texture.name} has no pixel buffer data");
    }

    final Vector3 dir = direction.clone().normalize();
    final double phi = _atan2Safe(dir.z, dir.x);
    final double theta = math.acos(dir.y.clamp(-1.0, 1.0));
    final double u = ((phi / (2.0 * math.pi)) + 1.0) % 1.0;
    final double v = theta / math.pi;

    final int x = ((u * (width - 1)).round()).clamp(0, width - 1);
    final int y = ((v * (height - 1)).round()).clamp(0, height - 1);
    final int index = (y * width + x) * 4;

    if (sourceData is Float32List) {
      return Vector3(sourceData[index], sourceData[index + 1], sourceData[index + 2]);
    } else if (sourceData is Uint8List) {
      return Vector3(
        sourceData[index] / 255.0,
        sourceData[index + 1] / 255.0,
        sourceData[index + 2] / 255.0,
      );
    }
    return Vector3();
  }

  Vector3 _sampleCubeTexture(CubeTexture cubeTexture, Vector3 direction) {
    final Vector3 dir = direction.clone().normalize();
    final double absX = dir.x.abs();
    final double absY = dir.y.abs();
    final double absZ = dir.z.abs();
    
    int faceIdx = 0;
    double u = 0.0;
    double v = 0.0;

    if (absX >= absY && absX >= absZ) {
      if (dir.x > 0) {
        faceIdx = 0; 
        u = -dir.z / dir.x;
        v = -dir.y / dir.x;
      } else {
        faceIdx = 1; 
        u = dir.z / dir.x;
        v = -dir.y / dir.x;
      }
    } else if (absY >= absZ) {
      if (dir.y > 0) {
        faceIdx = 2; 
        u = dir.x / dir.y;
        v = dir.z / dir.y;
      } else {
        faceIdx = 3; 
        u = dir.x / dir.y;
        v = -dir.z / dir.y;
      }
    } else {
      if (dir.z > 0) {
        faceIdx = 4; 
        u = dir.x / dir.z;
        v = -dir.y / dir.z;
      } else {
        faceIdx = 5; 
        u = -dir.x / dir.z;
        v = -dir.y / dir.z;
      }
    }

    final double texU = (u + 1.0) * 0.5;
    final double texV = (v + 1.0) * 0.5;
    
    final List<dynamic> imagesList = cubeTexture.images;
    final dynamic faceImage = imagesList[faceIdx];
    final int size = faceImage.width ?? _defaultCubeSize;
    final dynamic data = faceImage.data;
    
    final int texX = (texU * (size - 1)).round().clamp(0, size - 1);
    final int texY = (texV * (size - 1)).round().clamp(0, size - 1);
    final int pixelIndex = (texY * size + texX) * 4;

    if (data is Float32List) {
      return Vector3(data[pixelIndex], data[pixelIndex + 1], data[pixelIndex + 2]);
    } else if (data is Uint8List) {
      return Vector3(
        data[pixelIndex] / 255.0,
        data[pixelIndex + 1] / 255.0,
        data[pixelIndex + 2] / 255.0,
      );
    }
    return Vector3();
  }

  Vector2 _hammersley(int i, int n) {
    return Vector2(i / n, _radicalInverseVdC(i));
  }

  Vector3 _importanceSampleGGX(Vector2 xi, double roughness) {
    final double alpha = roughness * roughness;
    final double phi = 2.0 * math.pi * xi.x;
    final double cosTheta = math.sqrt((1.0 - xi.y) / (1.0 + (alpha * alpha - 1.0) * xi.y));
    final double sinTheta = math.sqrt(1.0 - cosTheta * cosTheta);

    final double x = math.cos(phi) * sinTheta;
    final double y = math.sin(phi) * sinTheta;
    final double z = cosTheta;
    return Vector3(x, y, z).normalize();
  }

  _TangentBasis _createTangentBasis(Vector3 normal) {
    final Vector3 n = normal.clone().normalize();
    final Vector3 up = n.z.abs() < 0.999 ? Vector3(0.0, 0.0, 1.0) : Vector3(1.0, 0.0, 0.0);
    final Vector3 tangent = Vector3().cross2(up, n).normalize();
    final Vector3 bitangent = Vector3().cross2(n, tangent).normalize();
    return _TangentBasis(tangent, bitangent, n);
  }

  Vector3 _toWorldSpace(Vector3 sample, Vector3 tangent, Vector3 bitangent, Vector3 normal) {
    return Vector3(
      sample.x * tangent.x + sample.y * bitangent.x + sample.z * normal.x,
      sample.x * tangent.y + sample.y * bitangent.y + sample.z * normal.y,
      sample.x * tangent.z + sample.y * bitangent.z + sample.z * normal.z,
    ).normalize();
  }

  double _radicalInverseVdC(int bits) {
    int b = bits;
    b = (b << 16) | ((b >> 16) & 0xFFFF);
    b = ((b & 0x55555555) << 1) | (((b & 0xAAAAAAAA) >> 1) & 0x7FFFFFFF);
    b = ((b & 0x33333333) << 2) | (((b & 0xCCCCCCCC) >> 2) & 0x3FFFFFFF);
    b = ((b & 0x0F0F0F0F) << 4) | (((b & 0xF0F0F0F0) >> 4) & 0x0FFFFFFF);
    b = ((b & 0x00FF00FF) << 8) | (((b & 0xFF00FF00) >> 8) & 0x00FFFFFF);
    return b.toUnsigned(32) * 2.3283064365386963e-10;
  }

  List<Vector3> _uniformSampleDirections(int sampleCount) {
    final List<Vector3> directions = List.generate(sampleCount, (_) => Vector3(), growable: true);
    final double increment = math.pi * (3.0 - math.sqrt(5.0));
    final double offset = 2.0 / sampleCount;

    for (int i = 0; i < sampleCount; i++) {
      final double y = i * offset - 1.0 + offset / 2.0;
      final double r = math.sqrt(1.0 - y * y);
      final double phi = i * increment;
      final double x = math.cos(phi) * r;
      final double z = math.sin(phi) * r;
      directions[i] = Vector3(x, y, z).normalize();
    }
    return directions;
  }

  Float32List _shBasis(Vector3 direction) {
    final double x = direction.x;
    final double y = direction.y;
    final double z = direction.z;
    return Float32List.fromList([
      0.282095,
      0.488603 * y,
      0.488603 * z,
      0.488603 * x,
      1.092548 * x * y,
      1.092548 * y * z,
      0.315392 * (3.0 * z * z - 1.0),
      1.092548 * x * z,
      0.546274 * (x * x - y * y),
    ]);
  }

  int _log2Floor(int value) {
    int result = 0;
    int current = value;
    while (current > 1) {
      current ~/= 2;
      result++;
    }
    return result;
  }

  double _atan2Safe(double y, double x) {
    final double angle = math.atan2(y, x);
    return angle < 0.0 ? angle + 2.0 * math.pi : angle;
  }
}

class _TangentBasis {
  final Vector3 tangent;
  final Vector3 bitangent;
  final Vector3 normal;
  _TangentBasis(this.tangent, this.bitangent, this.normal);
}
