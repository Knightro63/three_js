import 'dart:typed_data';
import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../material/material_description_registry.dart';
import 'render_stats_tracker.dart';
import 'buffer.dart'; // To interface with Mesh, Camera, Vector3, etc.

class FrameDebugInfo {
  final int frameCount;
  final int drawCallCount;

  const FrameDebugInfo({
    required this.frameCount,
    required this.drawCallCount,
  });
}

class UniformBufferManager {
  // Static Constants replacing Kotlin's companion object block
  static const int maxMeshesPerFrame = 200;
  static const int _uniformAlignment = 256;
  
  // Maps dynamically to the underlying MaterialDescriptorRegistry specifications
  static final int objectBytes = MaterialDescriptorRegistry.uniformBlockSizeBytes();
  static final int uniformSizePerMesh = ((objectBytes + _uniformAlignment - 1) ~/ _uniformAlignment) * _uniformAlignment;
  static final int uniformBufferSize = maxMeshesPerFrame * uniformSizePerMesh;

  final gpux.GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;

  GpuBuffer? _uniformBuffer;

  gpux.GpuBindGroupLayout? _bindGroupLayout;
  gpux.GpuPipelineLayout? _pipelineLayout;
  gpux.GpuBindGroup? _cachedBindGroup;
  int _uniformBufferSizeBytes = 0;
  List<gpux.GpuBindGroupLayout> _extraLayoutsCache = const [];

  UniformBufferManager({
    required gpux.GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  void onDeviceReady(gpux.GpuDevice device) {
    _ensureLayouts(device);
    _ensureUniformBuffer(device);
  }

  bool updateUniforms({
    required Float32List materialData,
    required Float32List sceneData,
    required int drawIndex,
  }) {
    final gpuDevice = _deviceProvider();
    if (gpuDevice == null) return false;

    _ensureUniformBuffer(gpuDevice);
    final bufferInstance = _uniformBuffer;
    if (bufferInstance == null) {
      console.warning("WARNING: Uniform buffer unavailable; skipping mesh");
      return false;
    }

    // 1. Calculate combined float storage sizing
    final int totalRawFloats = sceneData.length + materialData.length;
    
    // Pad the storage size up to your framework's expected 512-byte dynamic block stride boundary
    final int alignedFloatCount = ((totalRawFloats / 128).ceil() * 128);
    final Float32List uniformData = Float32List(alignedFloatCount);
    uniformData.setAll(0, sceneData);
    uniformData.setAll(sceneData.length, materialData);// Material data starts at offset 32

    // Indices 64 to 127 remain empty padding floats to complete your required 512-byte block stride
    final offset = dynamicOffset(drawIndex);
    final byteLength = alignedFloatCount * 4;
    
    if (offset + byteLength > uniformBufferSize) return false;

    // Upload the complete float stream into the WebGPU queue structure
    bufferInstance.upload(uniformData, offset: offset);
    return true;
  }

  gpux.GpuBindGroup? bindGroup() {
    final cached = _cachedBindGroup;
    if (cached != null) return cached;

    final gpuDevice = _deviceProvider();
    if (gpuDevice == null) return null;

    _ensureLayouts(gpuDevice);
    _ensureUniformBuffer(gpuDevice);

    final layout = _bindGroupLayout;
    final internalBuffer = _uniformBuffer?.getBuffer();
    if (layout == null || internalBuffer == null) return null;

    final bindGroup = gpuDevice.createBindGroup(
      layout: layout,
      entries: [
        gpux.GpuBindGroupEntry.buffer(
          binding: 0,
          buffer: internalBuffer,
          offset: 0,
          size: UniformBufferManager.uniformSizePerMesh,   // 512 bytes objectBytes,
        ),
      ],
      label: "Uniform Bind Group (Dynamic Offsets)",
    );
    _cachedBindGroup = bindGroup;
    return bindGroup;
  }

  gpux.GpuPipelineLayout? pipelineLayout([List<gpux.GpuBindGroupLayout> extraLayouts = const []]) {
    final gpuDevice = _deviceProvider();
    if (gpuDevice == null) return null;

    _ensureLayouts(gpuDevice);

    // List deep comparison checking
    if (_pipelineLayout != null && _areLayoutListsEqual(_extraLayoutsCache, extraLayouts)) {
      return _pipelineLayout;
    }

    final coreLayout = _bindGroupLayout;
    if (coreLayout == null) return null;

    final layouts = [coreLayout, ...extraLayouts];

    _pipelineLayout = gpuDevice.createPipelineLayout(
      layouts,
      label: "Uniform Pipeline Layout (Dynamic Offsets)",
    );
    _extraLayoutsCache = extraLayouts;
    return _pipelineLayout;
  }

  int dynamicOffset(int drawIndex) => drawIndex * uniformSizePerMesh;

  void dispose() {
    _cachedBindGroup = null;
    _bindGroupLayout = null;
    _pipelineLayout = null;
    _extraLayoutsCache = const [];
    
    if (_uniformBuffer != null && _uniformBufferSizeBytes > 0) {
      _statsTracker?.recordBufferDeallocated(_uniformBufferSizeBytes);
      _uniformBufferSizeBytes = 0;
    }
    
    _uniformBuffer?.dispose();
    _uniformBuffer = null;
  }

  void _ensureLayouts(gpux.GpuDevice device) {
    _bindGroupLayout ??= _createUniformBindGroupLayout(device);
  }

  void _ensureUniformBuffer(gpux.GpuDevice device) {
    if (_uniformBuffer != null) return;

    final buffer = GpuBuffer(
      device,
      BufferDescriptor(
        size: uniformBufferSize,
        usage: gpux.GpuBufferUsage.uniform | gpux.GpuBufferUsage.copyDst,
        label: "Uniform Buffer (Multi-Mesh, $maxMeshesPerFrame max)",
      ),
    );

    try {
      buffer.create();
      _uniformBuffer = buffer;
      _cachedBindGroup = null;
      _uniformBufferSizeBytes = uniformBufferSize;
      _statsTracker?.recordBufferAllocated(_uniformBufferSizeBytes);
    } catch (e) {
      console.error("ERROR: Failed to create uniform buffer: ${e.toString()}");
      _uniformBuffer = null;
    }
  }

  gpux.GpuBindGroupLayout _createUniformBindGroupLayout(gpux.GpuDevice device) {
    return device.createBindGroupLayout(
      [
        gpux.GpuBufferBindingLayout(
          binding: 0,
          visibility: gpux.GpuShaderStage.vertex | gpux.GpuShaderStage.fragment,
          type: gpux.GpuBufferBindingType.uniform,
          hasDynamicOffset: true,
          minBindingSize: objectBytes,
        ),
      ],
      label: "Uniform Bind Group Layout (Dynamic Offsets)",
    );
  }

  bool _areLayoutListsEqual(List<gpux.GpuBindGroupLayout> a, List<gpux.GpuBindGroupLayout> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class SceneUniformData {
  final int lightCount;
  final Float32List cameraPosition;
  final Float32List ambientColor;
  final Float32List fogColor;
  final Float32List fogParams;
  final Float32List lightDirection;
  final Float32List lightColor;

  const SceneUniformData({
    required this.cameraPosition,
    required this.ambientColor,
    required this.fogColor,
    required this.fogParams,
    required this.lightDirection,
    required this.lightColor,
    required this.lightCount,
  });

  static Float32List updateUniforms({
    required Camera camera,
    required Scene scene,
    List<Light>? activeLights, 
  }) {
    final lightsList = activeLights ?? const [];
    final int totalCount = lightsList.length;

    // Calculate and synchronize absolute viewing camera transformation states
    camera.updateMatrixWorld();
    //camera.matrixWorldInverse.setFrom(camera.matrixWorld).invert();
    
    final projMatrix = camera.projectionMatrix.storage;
    final viewMatrix = camera.matrixWorldInverse.storage;

    // Allocate 128 elements to preserve your 512-byte dynamic storage buffer layout bounds
    final uniformData = Float32List(48+(16*16));

    // [Offsets 0-15]: Copy 4x4 Camera Projection Matrix (64 bytes)
    for (int i = 0; i < 16; i++) {
      uniformData[i] = projMatrix[i];
      uniformData[16 + i] = viewMatrix[i];
    }

    // [Offsets 32-35]: Camera World Position Vector (Moved completely out of material scope)
    uniformData[32] = camera.position.x;
    uniformData[33] = camera.position.y;
    uniformData[34] = camera.position.z;
    uniformData[35] = totalCount.toDouble(); // Alignment padding flag

    // [Offsets 36-39]: Global Ambient Color Vector
    //final Color ambient = scene.background == Color()?scene.background:Color();
    uniformData[36] = 0;
    uniformData[37] = 0;
    uniformData[38] = 0;
    uniformData[39] = 0;

    // [Offsets 40-43]: Environmental Fog Color Vector
    final fogColor = scene.fog?.color ?? Color();
    uniformData[40] = fogColor.red;
    uniformData[41] = fogColor.green;
    uniformData[42] = fogColor.blue;
    uniformData[43] = fogColor.alpha;

    // [Offsets 44-47]: Environmental Fog Range Density Parameters
    uniformData[44] = scene.fog?.isFogExp2 == false?scene.fog?.near ?? 0.0 : 0.0;
    uniformData[45] = scene.fog?.isFogExp2 == false?scene.fog?.far ?? 0.0 : 0.0;
    uniformData[46] = (scene.fog?.isFogExp2 == true? scene.fog?.density: 0.0) ?? 0.0;
    uniformData[47] = scene.fog?.isFogExp2 == true?1.0:0.0;

    // 2. Loop explicitly over the exact user-defined array length
    for (int i = 0; i < totalCount; i++) {
      final int baseOffset = 48 + (i * 16); 
      final Light light = lightsList[i];
      double typeToken = 1.0; // Default directional

      if (light is AmbientLight) typeToken = 6.0;
      else if (light is PointLight) typeToken = 2.0;
      else if (light is SpotLight) typeToken = 3.0;
      else if (light is HemisphereLight) typeToken = 4.0;
      else if (light is RectAreaLight) typeToken = 5.0;

      // Vector 1: Position and Type Token
      uniformData[baseOffset]     = light.position.x;
      uniformData[baseOffset + 1] = light.position.y;
      uniformData[baseOffset + 2] = light.position.z;
      uniformData[baseOffset + 3] = typeToken;

      // Vector 2: Primary Color and Intensity
      uniformData[baseOffset + 4] = light.color?.red ?? 1.0;
      uniformData[baseOffset + 5] = light.color?.green ?? 1.0;
      uniformData[baseOffset + 6] = light.color?.blue ?? 1.0;
      uniformData[baseOffset + 7] = light.intensity;

      // Vector 3: Attenuation Parameters
      uniformData[baseOffset + 8]  = light.distance ?? 0.0;
      uniformData[baseOffset + 9]  = light.decay ?? 2.0;
      uniformData[baseOffset + 10] = light.angle ?? 0.0;
      uniformData[baseOffset + 11] = light.penumbra ?? 0.0;

      // Vector 4: Extended Dimensions / Ground Colors
      if (typeToken == 4.0 && light.groundColor != null) {
        uniformData[baseOffset + 12] = light.groundColor!.red;
        uniformData[baseOffset + 13] = light.groundColor!.green;
        uniformData[baseOffset + 14] = light.groundColor!.blue;
      } 
      else if (typeToken == 5.0) {
        uniformData[baseOffset + 12] = light.width ?? 1.0;
        uniformData[baseOffset + 13] = light.height ?? 1.0;
        uniformData[baseOffset + 14] = 0.0;
      } 
      else {
        uniformData[baseOffset + 12] = 0.0;
        uniformData[baseOffset + 13] = 0.0;
        uniformData[baseOffset + 14] = 0.0;
      }
      uniformData[baseOffset + 15] = 0.0; 
    }

    return uniformData;
  }
}

class MaterialUniformData {
  final List<Plane> clippingPlanes;
  final Color? baseColor;       // r, g, b, opacity
  final Color? emissiveColor;   // r, g, b
  final double emissiveIntensity;
  final double roughness;
  final double metalness;
  final double envIntensity;
  final int prefilterMipCount;
  final bool flatShading;
  final double alphaTest;

  // Blinn-Phong & General Configs
  final double shininess;
  final bool wireframe;

  // MeshPhysicalMaterial Specifics
  final double clearcoat;
  final double clearcoatRoughness;
  final Color? specularColor;  // r, g, b
  final double specularIntensity;
  final double ior;
  final Color? sheenColor;     // r, g, b
  final double sheen;
  final double sheenRoughness;
  final double reflectivity;
  final double transmission;
  final double attenuationDistance;
  final Color? attenuationColor; // r, g, b

  // Map Scaling Factors
  final double bumpScale;
  final double lightMapIntensity;
  final double aoMapIntensity;

  final double rotation;

  // Line & Dash Material Specifics
  final double linewidth;
  final double dashSize;
  final double gapSize;
  final double scale;
  final String linecap;                  // 0 = Round, 1 = Square, 2 = Butt
  final String linejoin;                 // 0 = Round, 1 = Bevel,  2 = Miter

  const MaterialUniformData({
    required this.baseColor,
    this.emissiveColor,
    this.emissiveIntensity = 1.0,
    required this.roughness,
    required this.metalness,
    required this.envIntensity,
    required this.prefilterMipCount,
    required this.flatShading,
    this.alphaTest = 0.0,
    this.shininess = 30.0,
    this.wireframe = false,
    this.clearcoat = 0.0,
    this.clearcoatRoughness = 0.0,
    this.specularColor,
    this.specularIntensity = 1.0,
    this.ior = 1.5,
    this.sheenColor,
    this.sheen = 0.0,
    this.sheenRoughness = 1.0,
    this.reflectivity = 0.5,
    this.transmission = 0.0,
    this.attenuationDistance = 0.0,
    this.attenuationColor,
    this.bumpScale = 1.0,
    this.lightMapIntensity = 1.0,
    this.aoMapIntensity = 1.0,
    this.linewidth = 1.0,
    this.dashSize = 0.0,
    this.gapSize = 0.0,
    this.scale = 1.0,
    this.linecap = 'square',
    this.linejoin = 'bevel',
    this.rotation = 0.0,
    required this.clippingPlanes,
  });

  // Line Cap Integer Constants
  final int lineCapRound = 0;
  final int lineCapSquare = 1;
  final int lineCapButt = 2;

  /// Maps WebGL linecap strings ('round', 'square', 'butt') to integer tokens.
  int mapLineCap(String? cap) {
    if (cap == null) return lineCapRound;
    
    // Clean string inputs to handle accidental case variances
    final normalized = cap.toLowerCase().trim();
    
    if (normalized == 'square') return lineCapSquare;
    if (normalized == 'butt') return lineCapButt;
    
    return lineCapRound; // Default WebGL fallback
  }

  // Line Join Integer Constants
  final int lineJoinRound = 0;
  final int lineJoinBevel = 1;
  final int lineJoinMiter = 2;

  /// Maps WebGL linejoin strings ('round', 'bevel', 'miter') to integer tokens.
  int mapLineJoin(String? join) {
    if (join == null) return lineJoinRound;
    
    final normalized = join.toLowerCase().trim();
    
    if (normalized == 'bevel') return lineJoinBevel;
    if (normalized == 'miter') return lineJoinMiter;
    
    return lineJoinRound; // Default WebGL fallback
  }

  Float32List updateUniforms({
    required Object3D mesh,
    required 
  }) {
    // 1. Synchronize and fetch latest absolute scene transform matrices
    mesh.updateMatrixWorld();
    final modelMatrix = mesh.matrixWorld.storage;

    // Total size: 16 (model) + 16 (features) + 56 (material properties) = 88 floats (352 bytes)
    // This layout perfectly matches our Uniforms struct mapping.
    final uniformData = Float32List(112);

    // ========================================================
    // 1. MODEL MATRIX (Offsets 0 - 15)
    // ========================================================
    for (int i = 0; i < 16; i++) {
      uniformData[i] = modelMatrix[i];
      uniformData[16 + i] = 0.0;
    }
    
    // ========================================================
    // 3. MATERIAL PROPERTIES (Offsets 32 - 87)
    // Using an explicit starting point ensures alignment offsets never overlap!
    // ========================================================
    const int start = 16;

    // [Offsets 32-35]: Albedo Base Color channels
  
    uniformData[start + 0] = baseColor?.red ?? 1.0;
    uniformData[start + 1] = baseColor?.green ?? 1.0;
    uniformData[start + 2] = baseColor?.blue ?? 1.0;
    uniformData[start + 3] = baseColor?.alpha ?? 1.0;

    // [Offsets 36-39]: Emissive Color RGB channels + Multiplier Intensity
    uniformData[start + 4] = emissiveColor?.red ?? 0.0;
    uniformData[start + 5] = emissiveColor?.green ?? 0.0;
    uniformData[start + 6] = emissiveColor?.blue ?? 0.0;
    uniformData[start + 7] = this.emissiveIntensity;

    // [Offsets 40-43]: Core PBR Properties Vector (Roughness, Metalness, Shading, Alpha)
    uniformData[start + 8]  = this.roughness;
    uniformData[start + 9]  = this.metalness;
    uniformData[start + 10] = (this.flatShading) ? 1.0 : 0.0;
    uniformData[start + 11] = this.alphaTest;

    // [Offsets 44-47]: Surface Modification Parameters (Shininess, Clearcoat details, Wireframe)
    uniformData[start + 12] = this.shininess;
    uniformData[start + 13] = this.clearcoat;
    uniformData[start + 14] = this.clearcoatRoughness;
    uniformData[start + 15] = (this.wireframe) ? 1.0 : 0.0;

    // [Offsets 48-51]: Map Intensities + Environment Multiplier
    uniformData[start + 16] = this.bumpScale;
    uniformData[start + 17] = this.envIntensity;
    uniformData[start + 18] = this.lightMapIntensity;
    uniformData[start + 19] = this.aoMapIntensity;

    // [Offsets 52-55]: Phong Specular Color Override + Index of Refraction (IOR)
    if (specularColor != null) {
      uniformData[start + 20] = specularColor!.red * specularIntensity;
      uniformData[start + 21] = specularColor!.green * specularIntensity;
      uniformData[start + 22] = specularColor!.blue * specularIntensity;
    } else {
      uniformData[start + 20] = specularIntensity;
      uniformData[start + 21] = specularIntensity;
      uniformData[start + 22] = specularIntensity;
    }
    uniformData[start + 23] = this.ior;

    // [Offsets 56-59]: Physical Sheen Color channels + General Intensity
    if (sheenColor != null) {
      uniformData[start + 24] = sheenColor!.red;
      uniformData[start + 25] = sheenColor!.green;
      uniformData[start + 26] = sheenColor!.blue;
    } 
    uniformData[start + 27] = this.sheen;

    // [Offsets 60-63]: Advanced Physical Material Metrics
    uniformData[start + 28] = this.sheenRoughness;
    uniformData[start + 29] = this.reflectivity;
    uniformData[start + 30] = this.attenuationDistance;
    uniformData[start + 31] = this.transmission;

    // [Offsets 64-67]: Attenuation Color RGB + Environment Prefilter Mip Count
    if (attenuationColor != null) {
      uniformData[start + 32] = attenuationColor!.red;
      uniformData[start + 33] = attenuationColor!.green;
      uniformData[start + 34] = attenuationColor!.blue;
    } 

    uniformData[start + 35] = (this.prefilterMipCount).toDouble();

    // [Offsets 68-71]: Primary Line Topology & Geometry Dimensions
    uniformData[start + 36] = this.linewidth;
    uniformData[start + 37] = this.dashSize;
    uniformData[start + 38] = this.mapLineCap(linecap).toDouble();
    uniformData[start + 39] = this.mapLineJoin(linejoin).toDouble();

    // [Offsets 72-75]: Extended Line Segment Settings
    uniformData[start + 40] = this.gapSize;
    uniformData[start + 41] = this.scale;
    uniformData[start + 42] = ColorSpace.srgb.index.toDouble(); // colorspace
    uniformData[start + 43] = this.rotation;

    // [Offsets 76-83]: Morph Target Animation Influences (8 Sequential Targets)
    // morphInfluences0 takes up offsets 76-79, morphInfluences1 takes up offsets 80-83
    final List<double>? morphInfluenceSource = mesh.morphTargetInfluences;
    if (morphInfluenceSource != null) {
      for (int i = 0; i < 8; i++) {
        uniformData[start + 44 + i] = i < morphInfluenceSource.length ? morphInfluenceSource[i] : 0.0;
      }
    }

    // Reserve float index slots for 3 planes (3 planes * 4 floats per plane = 12 floats total)
    // Float offset index 40 to 51:
    for (int i = 0; i < 6; i++) {
      final int planeOffset = start + 52 + (i * 4);
      if (i < clippingPlanes.length) {
        final plane = clippingPlanes[i];
        uniformData[planeOffset + 0] = plane.normal.x;
        uniformData[planeOffset + 1] = plane.normal.y;
        uniformData[planeOffset + 2] = plane.normal.z;
        uniformData[planeOffset + 3] = plane.constant;
      } else {
        // Zero out unassigned slots so they don't clip your geometry
        uniformData[planeOffset + 0] = 0.0;
        uniformData[planeOffset + 1] = 0.0;
        uniformData[planeOffset + 2] = 0.0;
        uniformData[planeOffset + 3] = 0.0;
      }
    }
    print(clippingPlanes);
    uniformData[111] = clippingPlanes.length.toDouble();

    return uniformData;
  }
}