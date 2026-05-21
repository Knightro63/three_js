import 'dart:typed_data';
import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import '../material/MaterialDescriptionRegistry.dart';
import 'RenderStatsTracker.dart';
import 'WebGPUBuffer.dart'; // To interface with Mesh, Camera, Vector3, etc.

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
  static const int _maxMorphTargets = 8;
  
  // Maps dynamically to the underlying MaterialDescriptorRegistry specifications
  static final int objectBytes = MaterialDescriptorRegistry.uniformBlockSizeBytes();
  static final int uniformSizePerMesh = ((objectBytes + _uniformAlignment - 1) ~/ _uniformAlignment) * _uniformAlignment;
  static final int uniformBufferSize = maxMeshesPerFrame * uniformSizePerMesh;

  static final Float32List _defaultBaseColor = Float32List.fromList([1.0, 1.0, 1.0, 1.0]);
  static final Float32List _defaultAmbient = Float32List.fromList([0.0, 0.0, 0.0, 1.0]);
  static final Float32List _defaultFogColor = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);
  static final Float32List _defaultFogParams = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);
  static final Float32List _defaultLightDirection = Float32List.fromList([0.0, -1.0, 0.0, 0.0]);
  static final Float32List _defaultLightColor = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);

  final GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;

  WebGPUBuffer? _uniformBuffer;
  GpuBindGroupLayout? _bindGroupLayout;
  GpuPipelineLayout? _pipelineLayout;
  GpuBindGroup? _cachedBindGroup;
  int _uniformBufferSizeBytes = 0;
  List<GpuBindGroupLayout> _extraLayoutsCache = const [];

  UniformBufferManager({
    required GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  void onDeviceReady(GpuDevice device) {
    _ensureLayouts(device);
    _ensureUniformBuffer(device);
  }

  bool updateUniforms({
    required Mesh mesh,
    required Camera camera,
    required int drawIndex,
    required FrameDebugInfo frameInfo,
    required bool enableDiagnostics,
    MaterialUniformData? materialUniforms,
  }) {
    final gpuDevice = _deviceProvider();
    if (gpuDevice == null) return false;

    _ensureUniformBuffer(gpuDevice);
    final bufferInstance = _uniformBuffer;
    if (bufferInstance == null) {
      print("WARNING: Uniform buffer unavailable; skipping mesh");
      return false;
    }

    final projMatrix = camera.projectionMatrix.storage;
    final viewMatrix = camera.matrixWorldInverse.storage;
    final modelMatrix = mesh.matrixWorld.storage;

    if (enableDiagnostics && frameInfo.frameCount < 3 && frameInfo.drawCallCount < 2) {
      _logMatrices(frameInfo, camera, projMatrix, viewMatrix, modelMatrix);
    }

    // Allocate 88 sequential floats mirroring std140 layout bounds block memory packing
    final uniformData = Float32List(88);
    for (int i = 0; i < 16; i++) {
      uniformData[i] = projMatrix[i];
      uniformData[16 + i] = viewMatrix[i];
      uniformData[32 + i] = modelMatrix[i];
    }

    final baseColor = materialUniforms?.baseColor ?? _defaultBaseColor;
    uniformData[48] = baseColor.length > 0 ? baseColor[0] : 1.0;
    uniformData[49] = baseColor.length > 1 ? baseColor[1] : 1.0;
    uniformData[50] = baseColor.length > 2 ? baseColor[2] : 1.0;
    uniformData[51] = baseColor.length > 3 ? baseColor[3] : 1.0;

    uniformData[52] = materialUniforms?.roughness ?? 1.0;
    uniformData[53] = materialUniforms?.metalness ?? 0.0;
    uniformData[54] = materialUniforms?.envIntensity ?? 1.0;
    uniformData[55] = (materialUniforms?.prefilterMipCount ?? 1).toDouble();

    final cameraPosition = materialUniforms?.cameraPosition ?? 
        Float32List.fromList([camera.position.x, camera.position.y, camera.position.z]);
    uniformData[56] = cameraPosition.length > 0 ? cameraPosition[0] : camera.position.x;
    uniformData[57] = cameraPosition.length > 1 ? cameraPosition[1] : camera.position.y;
    uniformData[58] = cameraPosition.length > 2 ? cameraPosition[2] : camera.position.z;
    uniformData[59] = cameraPosition.length > 3 ? cameraPosition[3] : 1.0;

    final ambientColor = materialUniforms?.ambientColor ?? _defaultAmbient;
    uniformData[60] = ambientColor.length > 0 ? ambientColor[0] : 0.0;
    uniformData[61] = ambientColor.length > 1 ? ambientColor[1] : 0.0;
    uniformData[62] = ambientColor.length > 2 ? ambientColor[2] : 0.0;
    uniformData[63] = ambientColor.length > 3 ? ambientColor[3] : 1.0;

    final fogColor = materialUniforms?.fogColor ?? _defaultFogColor;
    uniformData[64] = fogColor.length > 0 ? fogColor[0] : 0.0;
    uniformData[65] = fogColor.length > 1 ? fogColor[1] : 0.0;
    uniformData[66] = fogColor.length > 2 ? fogColor[2] : 0.0;
    uniformData[67] = fogColor.length > 3 ? fogColor[3] : 0.0;

    final fogParams = materialUniforms?.fogParams ?? _defaultFogParams;
    uniformData[68] = fogParams.length > 0 ? fogParams[0] : 0.0;
    uniformData[69] = fogParams.length > 1 ? fogParams[1] : 0.0;
    uniformData[70] = fogParams.length > 2 ? fogParams[2] : 0.0;
    uniformData[71] = fogParams.length > 3 ? fogParams[3] : 0.0;

    final mainLightDirection = materialUniforms?.mainLightDirection ?? _defaultLightDirection;
    uniformData[72] = mainLightDirection.length > 0 ? mainLightDirection[0] : 0.0;
    uniformData[73] = mainLightDirection.length > 1 ? mainLightDirection[1] : -1.0;
    uniformData[74] = mainLightDirection.length > 2 ? mainLightDirection[2] : 0.0;
    uniformData[75] = mainLightDirection.length > 3 ? mainLightDirection[3] : 0.0;

    final mainLightColor = materialUniforms?.mainLightColor ?? _defaultLightColor;
    uniformData[76] = mainLightColor.length > 0 ? mainLightColor[0] : 0.0;
    uniformData[77] = mainLightColor.length > 1 ? mainLightColor[1] : 0.0;
    uniformData[78] = mainLightColor.length > 2 ? mainLightColor[2] : 0.0;
    uniformData[79] = mainLightColor.length > 3 ? mainLightColor[3] : 0.0;

    // Morph Target Influences parsing step
    final List<double> morphInfluenceSource = mesh.morphTargetInfluences;// ?? (mesh.userData["morphTargetInfluences"] as List<double>?) ?? const [];
        
    for (int i = 0; i < _maxMorphTargets; i++) {
      uniformData[80 + i] = i < morphInfluenceSource.length ? morphInfluenceSource[i] : 0.0;
    }

    final offset = dynamicOffset(drawIndex);
    if (offset + objectBytes > uniformBufferSize) {
      print("ERROR: T021 CRITICAL: Buffer overflow prevented! Offset=$offset exceeds size=$uniformBufferSize");
      return false;
    }

    bufferInstance.upload(uniformData, offset: offset);
    return true;
  }

  GpuBindGroup? bindGroup() {
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
        GpuBindGroupEntry.buffer(
          binding: 0,
          buffer: internalBuffer,
          offset: 0,
          size: objectBytes,
        ),
      ],
      label: "Uniform Bind Group (Dynamic Offsets)",
    );
    _cachedBindGroup = bindGroup;
    return bindGroup;
  }

  GpuPipelineLayout? pipelineLayout([List<GpuBindGroupLayout> extraLayouts = const []]) {
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

  void _ensureLayouts(GpuDevice device) {
    if (_bindGroupLayout == null) {
      _bindGroupLayout = _createUniformBindGroupLayout(device);
    }
  }

  void _ensureUniformBuffer(GpuDevice device) {
    if (_uniformBuffer != null) return;

    final buffer = WebGPUBuffer(
      device,
      BufferDescriptor(
        size: uniformBufferSize,
        usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
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
      print("ERROR: Failed to create uniform buffer: ${e.toString()}");
      _uniformBuffer = null;
    }
  }

  GpuBindGroupLayout _createUniformBindGroupLayout(GpuDevice device) {
    return device.createBindGroupLayout(
      [
        GpuBufferBindingLayout(
          binding: 0,
          visibility: GpuShaderStage.vertex | GpuShaderStage.fragment,
          type: GpuBufferBindingType.uniform,
          hasDynamicOffset: true,
          minBindingSize: objectBytes,
        ),
      ],
      label: "Uniform Bind Group Layout (Dynamic Offsets)",
    );
  }

  bool _areLayoutListsEqual(List<GpuBindGroupLayout> a, List<GpuBindGroupLayout> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _logMatrices(
    FrameDebugInfo frameInfo,
    Camera camera,
    Float32List projMatrix,
    Float32List viewMatrix,
    Float32List modelMatrix,
  ) {
    print("T021 Frame ${frameInfo.frameCount}, Draw ${frameInfo.drawCallCount}:");
    print(" Projection matrix:");
    print("  [${projMatrix[0]}, ${projMatrix[4]}, ${projMatrix[8]}, ${projMatrix[12]}]");
    print("  [${projMatrix[1]}, ${projMatrix[5]}, ${projMatrix[9]}, ${projMatrix[13]}]");
    print("  [${projMatrix[2]}, ${projMatrix[6]}, ${projMatrix[10]}, ${projMatrix[14]}]");
    print("  [${projMatrix[3]}, ${projMatrix[7]}, ${projMatrix[11]}, ${projMatrix[15]}]");
    print(" View matrix:");
    print("  [${viewMatrix[0]}, ${viewMatrix[4]}, ${viewMatrix[8]}, ${viewMatrix[12]}]");
    print("  [${viewMatrix[1]}, ${viewMatrix[5]}, ${viewMatrix[9]}, ${viewMatrix[13]}]");
    print("  [${viewMatrix[2]}, ${viewMatrix[6]}, ${viewMatrix[10]}, ${viewMatrix[14]}]");
    print("  [${viewMatrix[3]}, ${viewMatrix[7]}, ${viewMatrix[11]}, ${viewMatrix[15]}]");
    print(" Model matrix:");
    print("  [${modelMatrix[0]}, ${modelMatrix[4]}, ${modelMatrix[8]}, ${modelMatrix[12]}]");
    print("  [${modelMatrix[1]}, ${modelMatrix[5]}, ${modelMatrix[9]}, ${modelMatrix[13]}]");
    print("  [${modelMatrix[2]}, ${modelMatrix[6]}, ${modelMatrix[10]}, ${modelMatrix[14]}]");
    print("  [${modelMatrix[3]}, ${modelMatrix[7]}, ${modelMatrix[11]}, ${modelMatrix[15]}]");
    print(" Camera pos: (${camera.position.x}, ${camera.position.y}, ${camera.position.z})");
    print(" Camera rot: (${camera.rotation.x}, ${camera.rotation.y}, ${camera.rotation.z})");
  }
}

class MaterialUniformData {
  final Float32List baseColor;
  final double roughness;
  final double metalness;
  final double envIntensity;
  final int prefilterMipCount;
  final Float32List cameraPosition;
  final Float32List ambientColor;
  final Float32List fogColor;
  final Float32List fogParams;
  final Float32List mainLightDirection;
  final Float32List mainLightColor;

  const MaterialUniformData({
    required this.baseColor,
    required this.roughness,
    required this.metalness,
    required this.envIntensity,
    required this.prefilterMipCount,
    required this.cameraPosition,
    required this.ambientColor,
    required this.fogColor,
    required this.fogParams,
    required this.mainLightDirection,
    required this.mainLightColor,
  });
}