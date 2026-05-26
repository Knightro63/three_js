import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_gpux/flutter_gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/renderer/webgpu/WebGPUFrameAttachments.dart';
import 'package:three_js_gpu/renderer/webgpu/WebGPURenderPassManager.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../lighting/ibl/IBLConvolutionProfiler.dart';
import '../../lighting/ibl/PrefilterMipSelector.dart';
import '../../shader/MaterialShaderLibrary.dart';
import '../BackendType.dart';
import '../RendererCapabilities.dart';
import '../RendererConfig.dart';
import '../TextureTypes.dart';
import '../geometry/GeometryDescriptor.dart';
import '../geometry/GeometryMetadataHelpers.dart';
import 'BufferPool.dart';
import 'ContextLossRecovery.dart';
import 'GeometryBufferCache.dart';
import 'PipelineCache.dart';
import 'RenderStatsTracker.dart';
import 'UniformBufferManager.dart';
import 'WebGPUEnvironmentManager.dart';
import 'WebGPUMaterialTextureManager.dart';
import 'WebGPUPipeline.dart';
import '../../lighting/SceneLightingUniforms.dart';
import '../material/MaterialDescriptionRegistry.dart';

class WebGPURenderer extends Renderer {
  WebGPURenderer();

  late GpuFrame frame;

  // Linux presentation workaround tracks
  dynamic _presentationCanvas;

  static const int _maxMorphTargets = 8;
  static const int _diagFrames = 3;

  final _statsTracker = RenderStatsTracker();

  // // Core WebGPU components bound directly to the gpux package framework
   GpuDevice get _device => frame.device;
  GpuAdapter? _adapter;

  // Component managers (Using late initialization mirroring Kotlin's lateinit)
  late final PipelineCache _pipelineCache;
  late final BufferPool _bufferPool;
  
  final _contextLossRecovery = ContextLossRecovery();
  late final WebGPUEnvironmentManager _environmentManager = WebGPUEnvironmentManager(deviceProvider: () => _device, statsTracker: _statsTracker);
  late final WebGPUMaterialTextureManager _materialTextureManager = WebGPUMaterialTextureManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  // Rendering lifecycle state variables
  int _frameCount = 0;
  int _triangleCount = 0;
  int _drawCallCount = 0;
  int _drawIndexInFrame = 0;

  // Geometry buffer cache and uniform managers
  late final GeometryBufferCache _geometryCache = GeometryBufferCache(deviceProvider: () => _device, statsTracker: _statsTracker);
  late final UniformBufferManager _uniformManager = UniformBufferManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  // Cache lookups
  final Map<PipelineKey, WebGPUPipeline> _pipelineCacheMap = {};

  // Depth-stencil target GPU attachments resources references
  GpuTexture? _depthTexture;
  GpuTextureView? _depthTextureView;
  int _depthTextureWidth = 0;
  int _depthTextureHeight = 0;
  int _depthTextureBytes = 0;

  GpuTexture? _msaaColorTexture;
  GpuTextureView? _msaaColorTextureView;
  int _msaaColorWidth = 0;
  int _msaaColorHeight = 0;

  Color actualClearColor = Color(0.0, 0.0, 0.0, 1.0);

  RendererCapabilities? _rendererCapabilities;

  // Viewport mapping configurations variables
  late Vector4 _viewport = Vector4(0, 0, frame.width.toDouble(), frame.height.toDouble());

  /// T033: Debug flag for verbose frame logging
  bool enableFrameLogging = false;

  // Renderer interface property overrides
  final BackendType backend = BackendType.webgpu;

  // @override
  // RendererCapabilities get capabilities => _rendererCapabilities ?? _createDefaultCapabilities();
  late RendererConfig config;
  WebGPURenderPassManager? _renderPassManager;

  RenderStats get stats => _statsTracker.getStats();
  double clearAlpha = 1.0;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isWebGPU => true;

  RendererCapabilities _createDefaultCapabilities() {
    return RendererCapabilities(
      backend: BackendType.webgpu,
      supportsCompute: true,
      supportsMultisampling: true,
    );
  }

  /// Maps hardware limits queried from the official GpuAdapter onto the capabilities model.
  RendererCapabilities _createCapabilities(GpuAdapter adapter) {
    final defaults = _createDefaultCapabilities();
    
    // gpux adapter exposing core hardware profiling limits structurally
    final limits = adapter.limits;

    // Use device name provided directly by the cross-platform adapter info packet
    final deviceName = adapter.info.device.isNotEmpty ? adapter.info.device : defaults.deviceName;
    final driverVersion = adapter.info.description.isNotEmpty ? adapter.info.description : defaults.driverVersion;

    final maxCombinedTextures = math.max(
      limits.maxSampledTexturesPerShaderStage,
      limits.maxSamplersPerShaderStage,
    );

    return RendererCapabilities(
      backend: BackendType.webgpu,
      supportsCompute: true,
      supportsMultisampling: true,
      deviceName: deviceName,
      driverVersion: driverVersion,
      maxTextureSize: limits.maxTextureDimension2d,
      maxCubeMapSize: limits.maxTextureDimension2d,
      maxVertexAttributes: limits.maxVertexAttributes,
      maxVertexUniforms: limits.maxUniformBuffersPerShaderStage,
      maxFragmentUniforms: limits.maxUniformBuffersPerShaderStage,
      maxVertexTextures: limits.maxSampledTexturesPerShaderStage,
      maxFragmentTextures: limits.maxSamplersPerShaderStage,
      maxCombinedTextures: maxCombinedTextures,
      maxTextureSize3D: limits.maxTextureDimension3d,
      maxTextureArrayLayers: limits.maxTextureArrayLayers,
      maxUniformBufferSize: limits.maxUniformBufferBindingSize,
      maxUniformBufferBindings: limits.maxBindGroups,
    );
  }

  /// Entry point matching the unified asynchronous initialization interface contract.
  Future<Result<void>> init(GpuFrame frame, RendererConfig config) async {
    this.frame = frame;
    this.config = config;
    // For WebGPU, surface rendering canvas binding constraints are pre-configured
    return _initializeInternal();
  }

  /// Internal hardware driver setup loop using cross-platform async sequences.
  Future<Result<void>> _initializeInternal() async {
    try {
      console.info('T033: Starting WebGPU renderer initialization...');
      final stopwatch = Stopwatch()..start();

      // 1. Instantiate the cross-platform hardware facade
      final gpu = Gpu();

      // 2. Request physical hardware adapter reference
      final requestedAdapter = await gpu.requestAdapter(
        GpuRequestAdapterOptions(
        powerPreference: GpuPowerPreference.highPerformance,
      ));
      _adapter = requestedAdapter;

      // Device loss recovery callback hooks integration
      _device.lost.then((info) {
        try {
          console.warning('T033: ⚠️ WebGPU device lost: $info');
          _contextLossRecovery.handleContextLoss();
        } catch (e) {
          console.error('T033: Error handling device loss routine: $e');
        }
      });

      // Browser bug presentation layer fallback workarounds are handled implicitly 
      // by the multi-platform canvas context abstraction wrapper layer.
      console.info('T033: Configuring canvas context surface presentation pipeline...');
      
      console.info('T033: Rebuilding depth attachments buffers targets...');
      _ensureDepthTexture(
        frame.width, 
        frame.height, 
        sampleCount: 1
      );

      console.info('T033: Allocating sub-system tracking memory buffer pools...');
      _bufferPool = BufferPool(_device);
      
      _uniformManager.onDeviceReady(_device);
      _materialTextureManager.onDeviceReady(_device);

      console.info('T033: Resolving adapter limits capabilities profiles...');
      _rendererCapabilities = _createCapabilities(_adapter!);
      console.info('T033: Capabilities detected: maxTextureSize=${_rendererCapabilities!.maxTextureSize}');

      // Execute internal backend architecture text module checks
      console.info('T033: Validating WGSL shader compilation pipelines components...');
      final probeResult = await _validateWgslSupport(_device);
      if (probeResult is ErrorResult) {
        console.info('T033: WGSL validation failed, aborting sequence: ${probeResult.message}');
        _cleanupPartialInit();
        return Result.error(probeResult.message);
      }

      _isInitialized = true;
      console.info('T033: WebGPU renderer completed setup in ${stopwatch.elapsedMilliseconds}ms');
      return const Result.success(null);
    } catch (e, stack) {
      console.error('T033: ❌ FATAL CRASH during renderer initialization: $e');
      console.error('T033: Trace: $stack');
      return Result.error('Renderer initialization failed: ${e.toString()}', e);
    }
  }
  /// Submits a raw, zero-dependency render pass clearing the canvas to red.
  /// Used to directly audit if back-buffer context presentation bindings are healthy.
  void diagnosticRawClear() {
    try {
      final rawEncoder = _device.createCommandEncoder();

      // Build explicit structural attachment descriptor array map
      final rawPass = rawEncoder.beginRenderPass(
        colorAttachments: [
          GpuColorAttachment(
            view: frame.targetView,
            loadOp: GpuLoadOp.clear,
            clearValue: const GpuColor(1.0, 0.0, 0.0, 1.0), // Fully opaque pure Red
            storeOp: GpuStoreOp.store,
          ),
        ],
      );
      rawPass.end();

      final cmdBuf = rawEncoder.finish();
      
      // Submit array tracking directly to the hardware device processing timeline queue
      _device.queue.submit([cmdBuf]);
      console.info('RAW-CLEAR-TEST: Submitted red clear commands buffer. Presentation works if viewport is red.');
    } catch (e) {
      console.error('RAW-CLEAR-TEST: FAILED: $e');
    }
  }

  /// Interface implementation tracking resize transformations layout adjustments.
  void resize(int width, int height) {
    setSize(width, height, false);
  }

  double getTargetPixelRatio(){
    return 1.0;
  }
  Vector2 getSize(Vector2 target){
    return target.setValues(frame.width.toDouble(), frame.height.toDouble());
  }
  dynamic getContext(){

  }
  double getPixelRatio(){
    return 1.0;
  }

  double getClearAlpha(){
    return clearAlpha;
  }
  void setClearAlpha(double alpha){
    clearAlpha = alpha;
  }

  void setViewport(double x, double y, double width, double height){
    _viewport.setValues(x, y, width, height);
  }
  Vector4 getViewport(Vector4 target){
    return target.setFrom(_viewport);
  }
  Vector4 getCurrentViewport(Vector4 target){
    return target.setFrom(_viewport);
  }
  void setOutputColorSpace(String colorSpace ) {

  }
  void clear([bool color = true, bool depth = true, bool stencil = true]){

  }
  void clearColor() {
    clear(true, false, false);
  }
  void clearDepth() {
    clear(false, true, false);
  }
  void clearStencil() {
    clear(false, false, true);
  }
  void setClearColor(Color color, [double alpha = 1.0]){
    actualClearColor = Color(color.red, color.green, color.blue, alpha);
  }
  Color getClearColor(Color target){
    return actualClearColor;
  }

  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]){

  }
  void readRenderTargetPixels(RenderTarget renderTarget, int x, int y, int width, int height, TypedData buffer, [int? activeCubeFaceIndex]) {

  }
  void copyFramebufferToTexture(Vector? position, Texture? texture, {int level = 0}){

  }
  void renderBufferDirect(Camera camera,Object3D? scene,BufferGeometry geometry,Material material,Object3D object,Map<String, dynamic>? group){

  }
  RenderTarget? getRenderTarget(){
    return null;
  }

  /// Compile a representative WGSL test shader and check for validation errors.
  /// Dual verification strategy: checkCompilationInfo() asynchronous audits.
  Future<Result<void>> _validateWgslSupport(GpuDevice device) async {
  const testShaderCode = '''
    struct Uniforms {
        modelViewProjection: mat4x4<f32>,
    }
    @group(0) @binding(0) var<uniform> uniforms: Uniforms;

    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) normal: vec3<f32>,
    }

    struct VertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) vNormal: vec3<f32>,
    }

    @vertex fn vs_main(input: VertexInput) -> VertexOutput {
        var output: VertexOutput;
        output.position = uniforms.modelViewProjection * vec4<f32>(input.position, 1.0);
        output.vNormal = input.normal;
        return output;
    }

    @fragment fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
        let light = normalize(vec3<f32>(1.0, 1.0, 1.0));
        let intensity = max(dot(normalize(input.vNormal), light), 0.0);
        return vec4<f32>(vec3<f32>(intensity), 1.0);
    }
    ''';

    try {
      // 1. Create a validation target module block
      final testModule = device.createShaderModule(
        testShaderCode,
        label: 'wgsl-validation-probe',
      );

      // 2. Fetch compile diagnostic analysis messages asynchronously from hardware
      final compilationInfo = await testModule.getCompilationInfo();
      
      // Filter mapping messages specifically seeking out structural compilation failure notices
      final errors = compilationInfo.where((msg) => msg.type == GpuCompilationMessageType.error).toList();
      
      if (errors.isNotEmpty) {
        final errorMsg = errors.map((it) => 'L${it.lineNum}:${it.linePos} ${it.message}').join('; ');
        return Result.error('WGSL shader compilation failed: $errorMsg');
      }

      return const Result.success(null);
    } catch (e) {
      console.error('T033: Exception tracking during internal WGSL validation: $e');
      return Result.error('WGSL shader validation threw unexpected exception: ${e.toString()}', e);
    }
  }

  /// Clean up intermediate resources allocated during an initialization failure cycle.
  void _cleanupPartialInit() {
    try {
      _uniformManager.dispose();
      _materialTextureManager.dispose();

      // Check allocation readiness using conditional checks
      _bufferPool.dispose();

      if (_depthTexture != null && _depthTextureBytes > 0) {
        _statsTracker.recordTextureDisposed(_depthTextureBytes);
        _depthTextureBytes = 0;
      }
      
      _depthTexture?.destroy();
      _depthTexture = null;
      _depthTextureView = null;
      _adapter = null;
      _rendererCapabilities = null;
      
      _statsTracker.reset();
    } catch (e) {
      console.error('T033: Error executing validation failure cleanup routine sequence: $e');
    }
  }

  void dispose() {
    _environmentManager.dispose();
    
    for (final pipeline in _pipelineCacheMap.values) {
      pipeline.dispose();
    }
    _pipelineCacheMap.clear();
    
    // Handled cleanly via standard null conditional statements
    _pipelineCache.clear();
    _bufferPool.dispose();
    _uniformManager.dispose();
    _geometryCache.clear();
    
    if (_depthTexture != null && _depthTextureBytes > 0) {
      _statsTracker.recordTextureDisposed(_depthTextureBytes);
      _depthTextureBytes = 0;
    }
    
    _depthTexture?.destroy();
    _msaaColorTexture?.destroy();

    _depthTexture = null;
    _depthTextureView = null;
    _depthTextureWidth = 0;
    _depthTextureHeight = 0;
    _contextLossRecovery.clear();
    
    _adapter = null;
    
    _presentationCanvas = null;
    _rendererCapabilities = null;
    
    _drawIndexInFrame = 0;
    _drawCallCount = 0;
    _triangleCount = 0;
    _frameCount = 0;
    _isInitialized = false;
    _statsTracker.reset();
  }
  void render(Object3D scene, Camera camera){}

  void render1(Object3D scene, Camera camera, GpuFrame frame) {
    // Validate that the system hardware and frame target state are healthy before evaluating instructions
    if (!_isInitialized) {
      console.info('T033: Renderer not initialized, cannot render');
      return;
    }

    _statsTracker.frameStart();
    _statsTracker.recordIBLConvolution(IBLConvolutionProfiler.snapshot());
    _statsTracker.recordIBLMaterial(0.0, 0);

    final bool diag = _frameCount < _diagFrames;

    if (enableFrameLogging) {
      console.info('T033: [Frame $_frameCount] Starting render...');
    }

    try {
      _triangleCount = 0;
      _drawCallCount = 0;
      _drawIndexInFrame = 0;

      // Execute standard scene matrix world transformations
      scene.updateMatrixWorld(true);
      
      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Updating camera matrices...');
      }
      camera.updateMatrixWorld();
      camera.updateProjectionMatrix();

      // Multiply camera matrices using the engine matrix models math package
      // final projectionViewMatrix = Matrix4()
      //   ..setFrom(camera.projectionMatrix)
      //   ..multiply(camera.matrixWorldInverse);

      // if (enableFrameLogging) {
      //   console.info('T033: [Frame $_frameCount] - Creating frustum for culling...');
      // }
      // final frustum = Frustum()..setFromMatrix(projectionViewMatrix);

      // Fetch the active frame target view attachment out from the canvas context layer
      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Getting current texture from swap chain...');
      }
      final textureView = frame.targetView;
      //_ensureMsaaColorTexture(frame.width, frame.height, frame.format);
      final bool msaaActive = _msaaColorTextureView != null;
      final int dynamicSampleCount = msaaActive ? 4 : 1;

      _ensureDepthTexture(frame.width, frame.height, sampleCount: dynamicSampleCount);

      final msaaColorView = _msaaColorTextureView ?? textureView;
      final depthView = _depthTextureView;
      
      if (depthView == null && diag) {
        console.warning('⚠️ Depth texture unavailable; rendering without depth buffer');
      }

      // Allocate the execution timeline command encoder directly via the device instance
      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Creating command encoder...');
      }
      final commandEncoder = frame.device.createCommandEncoder(label: 'Main Command Encoder');
      if (enableFrameLogging){
        console.info("T033: [Frame $_frameCount] - Creating command encoder...");
      }

      // T020: Initialize RenderPassManager for this frame
      if (enableFrameLogging){
        console.info("T033: [Frame $_frameCount] - Initializing RenderPassManager...");
      }
      _renderPassManager = WebGPURenderPassManager(commandEncoder);

      // T020: Begin render pass using manager
      if (enableFrameLogging){
        console.info("T033: [Frame $_frameCount] - Beginning render pass (clearColor=[${actualClearColor.red}, ${actualClearColor.green}, ${actualClearColor.blue}])...");
      }
      late final FramebufferHandle framebufferHandle;
      if (depthView != null) {
        framebufferHandle = FramebufferHandle(
          WebGPUFramebufferAttachments(
            colorView: msaaColorView, 
            depthView: depthView,
            resolveView: msaaActive ? textureView : null, 
          )
        );
      } 
      else {
        framebufferHandle = FramebufferHandle(msaaColorView);
      }

      final Color clearColorFeature020 = Color(
        scene.background is Color? scene.background.red: actualClearColor.red, 
        scene.background is Color? scene.background.green: actualClearColor.green,  
        scene.background is Color? scene.background.blue: actualClearColor.blue, 
        clearAlpha
      );
      _renderPassManager!.beginRenderPass(clearColor: clearColorFeature020, framebuffer: framebufferHandle);
      if (diag){
        console.info("RENDER[$_frameCount]: beginRenderPass OK, framebuffer=${framebufferHandle.handle.runtimeType}");
      }

      // Get the internal render pass encoder for legacy rendering code
      final renderPass = _renderPassManager!.getPassEncoder()!;
      if (diag){
        console.info("RENDER[$_frameCount]: passEncoder type=${renderPass.runtimeType}");
      }

      // Extract light descriptors transformations data properties out from scene graph
      final sceneBrdf = scene.userData['environmentBrdfLut'];
      final lightingUniforms = collectSceneLightingUniforms(scene);
      final environmentBinding = _environmentManager.prepare(scene.environment as CubeTexture?, sceneBrdf);

      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Traversing scene graph and rendering meshes...');
      }
      
      String? firstMeshName;
      String? lastMeshName;

      scene.traverse((obj) {
        if (obj is Mesh) {
          if (diag) {
            firstMeshName ??= obj.name;
            lastMeshName = obj.name;
          }
          _renderMesh(obj, camera, renderPass, environmentBinding, lightingUniforms);
        }
      });

      if (diag) {
        console.info('RENDER[$_frameCount]: meshes rendered=$_drawCallCount, triangles=$_triangleCount, first=$firstMeshName, last=$lastMeshName');
      }

      // Close and seal execution descriptors arrays loops steps blocks
      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Ending render pass...');
      }
      renderPass.end();

      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Finishing command encoder...');
      }
      final commandBuffer = commandEncoder.finish();

      if (enableFrameLogging) {
        console.info('T033: [Frame $_frameCount] - Submitting command buffer to GPU...');
      }
      
      // Submit arrays parameters to native execution stream queue directly off the logical device channel reference
      frame.device.queue.submit([commandBuffer]);
      
      if (diag) {
        console.info('RENDER[$_frameCount]: submitted successfully via device queue timeline channel');
      }

      // Blit presentation layers workaround blocks logic goes here if active...
      _frameCount++;
    } catch (e, stack) {
      console.error('T033: ❌ ERROR during execution frame loop lifecycle trace cycle: $e');
      console.error(stack);
    }
  }

  void _renderMesh(
    Mesh mesh,
    Camera camera,
    GpuRenderPassEncoder renderPass,
    EnvironmentBinding? environmentBinding,
    SceneLightingUniforms lightingUniforms,
  ) {
    final int maxMeshesPerFrame = UniformBufferManager.maxMeshesPerFrame;
    if (_drawIndexInFrame >= maxMeshesPerFrame) return;

    // 1. Force absolute parent-child matrix updates
    mesh.updateMatrixWorld();
    if (camera.matrixWorldInverse.storage[0] == 0.0 && camera.matrixWorldInverse.storage[5] == 0.0) {
      camera.matrixWorldInverse.setFrom(camera.matrixWorld).invert();
    }

    final geometry = mesh.geometry;
    if (geometry == null) return;

    final Float32List cameraPosition = Float32List.fromList([
      camera.position.x, 
      camera.position.y, 
      camera.position.z
    ]);

    final originalMaterial = mesh.material;
    if (originalMaterial == null) return;

    final bool hasEnvironment = environmentBinding != null;
    final material = (!hasEnvironment && originalMaterial is MeshStandardMaterial)
        ? toWebGpuBasicFallback(originalMaterial)
        : originalMaterial;

    final resolvedDescriptor = MaterialDescriptorRegistry.resolve(material);
    if (resolvedDescriptor == null) return;
    final descriptor = resolvedDescriptor.descriptor;

    late final MaterialUniformData materialUniforms;

    if (material is MeshStandardMaterial) {
      final Float32List baseColor = Float32List.fromList([
        material.color.red,
        material.color.green,
        material.color.blue,
        material.opacity,
      ]);
      final double roughness = PrefilterMipSelector.clamp01(material.roughness);

      materialUniforms = MaterialUniformData(
        baseColor: baseColor,
        roughness: roughness,
        metalness: material.metalness,
        envIntensity: hasEnvironment ? material.envMapIntensity ?? 0 : 0.0,
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: lightingUniforms.mainLightColor,
      );
      
      if (hasEnvironment) {
        _statsTracker.recordIBLMaterial(roughness, environmentBinding.mipCount);
      }
    } 
    else if (material is MeshBasicMaterial) {
      final Float32List baseColor = Float32List.fromList([
        material.color.red,
        material.color.green,
        material.color.blue,
        material.opacity,
      ]);

      materialUniforms = MaterialUniformData(
        baseColor: baseColor,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: lightingUniforms.mainLightColor,
      );
    } else {
      return;
    }

    final buildOptions = descriptor.buildGeometryOptions(geometry);
    final buffers = _geometryCache.getOrCreate(geometry: geometry, frameCount: _frameCount, options: buildOptions);
    if (buffers == null) return;

    final attributeOverrides = _buildAttributeOverrides(descriptor.key, buffers.metadata);
    final materialOverrides = _buildMaterialOverrides(material, descriptor, buffers.metadata);

    final combinedOverrides = _mergeShaderOverrides([
      descriptor.defines,
      resolvedDescriptor.shaderOverrides,
      attributeOverrides,
      materialOverrides.overrides,
    ]);

    final shaderDescriptor = descriptor.shader.withOverrides(combinedOverrides);

    MaterialTextureBinding? materialTextureBinding;
    if (materialOverrides.usesAlbedoMap || materialOverrides.usesNormalMap || materialOverrides.usesVolumeMap) {
      materialTextureBinding = _materialTextureManager.prepare(
        descriptor: descriptor,
        material: material,
        useAlbedo: materialOverrides.usesAlbedoMap,
        useNormal: materialOverrides.usesNormalMap,
        useVolume: materialOverrides.usesVolumeMap,
      );

      if (materialTextureBinding == null) {
        console.warning('Warning: Material ${descriptor.key} requires texture bindings but none were prepared; skipping mesh');
        return;
      }
    }

    // Extract layout configurations structurally across buffers streams list
    final bufferLayouts = buffers.vertexStreams.map((e) => e.layout).toList();

    final pipeline = _getOrCreatePipeline(
      resolvedDescriptor,
      shaderDescriptor,
      environmentBinding,
      materialTextureBinding,
      bufferLayouts,
    );
    if (pipeline == null) return;

    // 3. RECORD COMMAND CHANNELS
    renderPass.setPipeline(pipeline);

    for (int slot = 0; slot < buffers.vertexStreams.length; slot++) {
      renderPass.setVertexBuffer(slot, buffers.vertexStreams[slot].buffer);
    }

    final frameInfo = FrameDebugInfo(frameCount: _frameCount, drawCallCount: _drawCallCount);

    if (!_uniformManager.updateUniforms(
      mesh: mesh,
      camera: camera,
      drawIndex: _drawIndexInFrame,
      frameInfo: frameInfo,
      enableDiagnostics: enableFrameLogging,
      materialUniforms: materialUniforms,
    )) return;
    
    final bindGroup = _uniformManager.bindGroup();
    if (bindGroup == null) return;

    final int dynamicOffset = _uniformManager.dynamicOffset(_drawIndexInFrame);
    renderPass.setBindGroup(0, bindGroup, dynamicOffsets: [dynamicOffset]);

    // Bind additional custom shader pipeline groups
    _bindAdditionalGroups(descriptor, materialTextureBinding, environmentBinding, renderPass);

    // 4. DRAW
    final int instanceCount = buffers.instanceCount > 0 ? buffers.instanceCount : 1;
    if (buffers.indexBuffer != null && buffers.indexCount > 0) {
      renderPass.setIndexBuffer(buffers.indexBuffer!, buffers.indexFormat);
      renderPass.drawIndexed(indexCount: buffers.indexCount, instanceCount: instanceCount);
      final trianglesDrawn = (buffers.indexCount ~/ 3) * instanceCount;
      _triangleCount += trianglesDrawn;
    } 
    else {
      renderPass.draw(vertexCount: buffers.vertexCount, instanceCount: instanceCount);
      final trianglesDrawn = (buffers.indexCount ~/ 3) * instanceCount;
      _triangleCount += trianglesDrawn;
    }

    _drawCallCount++;
    _drawIndexInFrame++;
  }

  void _bindAdditionalGroups(
    MaterialDescriptor descriptor,
    MaterialTextureBinding? materialBinding,
    EnvironmentBinding? environmentBinding,
    GpuRenderPassEncoder renderPass,
  ) {
    if (materialBinding != null) {
      final groups = <int>{};
      groups.addAll(descriptor.bindingGroups(MaterialBindingSource.albedoMap));
      groups.addAll(descriptor.bindingGroups(MaterialBindingSource.normalMap));
      groups.addAll(descriptor.bindingGroups(MaterialBindingSource.volumeTexture));
      
      if (groups.isNotEmpty) {
        final rawGroup = materialBinding.bindGroup;
        final sortedGroups = groups.toList()..sort();
        final int primaryTextureGroupSlot = sortedGroups.first; 
        
        // Bind it exactly once to its true layout slot position!
        renderPass.setBindGroup(primaryTextureGroupSlot, rawGroup);
      }
    }

    if (environmentBinding != null) {
      final groups = <int>{};
      groups.addAll(descriptor.bindingGroups(MaterialBindingSource.environmentPrefilter));
      groups.addAll(descriptor.bindingGroups(MaterialBindingSource.environmentBrdf));
      
      if (groups.isNotEmpty) {
        final rawGroup = environmentBinding.bindGroup;
        final sortedGroups = groups.toList()..sort();
        final int primaryEnvGroupSlot = sortedGroups.first;
        
        // Bind exactly once to stop WebGPU slot mutation crashes!
        renderPass.setBindGroup(primaryEnvGroupSlot, rawGroup);
      }
    }
  }

  MeshBasicMaterial toWebGpuBasicFallback(MeshStandardMaterial material) {
    return MeshBasicMaterial()
      ..name = material.name
      ..color = material.color.clone()
      ..map = material.map
      ..transparent = material.transparent
      ..opacity = material.opacity
      ..vertexColors = material.vertexColors
      ..depthTest = material.depthTest
      ..depthWrite = material.depthWrite
      ..colorWrite = material.colorWrite
      ..side = material.side
      ..blending = material.blending
      ..wireframe = material.wireframe
      ..wireframeLinewidth = material.wireframeLinewidth
      ..needsUpdate = true;
  }

  Map<String, String> _buildAttributeOverrides(
    String materialKey,
    GeometryMetadata metadata,
  ) {
    final vertexInputExtra = StringBuffer();
    final vertexOutputExtra = StringBuffer();
    final vertexAssignExtra = StringBuffer();
    final fragmentInputExtra = StringBuffer();
    final fragmentInitExtra = StringBuffer();
    final fragmentExtra = StringBuffer();
    final fragmentBindings = StringBuffer();

    // Varying locations are independent of vertex input locations.
    // Start after the hardcoded varyings in each shader template:
    // basic: color@0 → next = 1
    // meshStandard: worldNormal@0, viewDir@1, albedo@2 → next = 3
    int varyingLocation = (materialKey == 'material.meshStandard') ? 3 : 1;

    final uv0Binding = metadata.bindingFor(GeometryAttribute.uv0);
    if (uv0Binding != null) {
      vertexInputExtra.writeln('  @location(${uv0Binding.location}) uv: vec2<f32>,');
      vertexOutputExtra.writeln('  @location($varyingLocation) uv: vec2<f32>,');
      vertexAssignExtra.writeln('  output.uv = input.uv;');
      fragmentInputExtra.writeln('  @location($varyingLocation) uv: vec2<f32>,');
      varyingLocation++;
    }

    final uv1Binding = metadata.bindingFor(GeometryAttribute.uv1);
    if (uv1Binding != null) {
      vertexInputExtra.writeln('  @location(${uv1Binding.location}) uv2: vec2<f32>,');
      vertexOutputExtra.writeln('  @location($varyingLocation) uv2: vec2<f32>,');
      vertexAssignExtra.writeln('  output.uv2 = input.uv2;');
      fragmentInputExtra.writeln('  @location($varyingLocation) uv2: vec2<f32>,');
      varyingLocation++;
    }

    final tangentBinding = metadata.bindingFor(GeometryAttribute.tangent);
    if (tangentBinding != null) {
      vertexInputExtra.writeln('  @location(${tangentBinding.location}) tangent: vec4<f32>,');
      vertexOutputExtra.writeln('  @location($varyingLocation) tangent: vec4<f32>,');
      vertexAssignExtra.writeln('  output.tangent = input.tangent;');
      fragmentInputExtra.writeln('  @location($varyingLocation) tangent: vec4<f32>,');
      varyingLocation++;
      if (materialKey == 'material.meshStandard') {
        fragmentExtra.writeln('  let tangent = normalize(input.tangent.xyz);');
        fragmentExtra.writeln('  let anisotropy = clamp(1.0 - abs(dot(normalize(input.viewDir), tangent)), 0.0, 1.0);');
        fragmentExtra.writeln('  color = color * (0.75 + 0.25 * anisotropy);');
      }
    }

    final morphPositionBindings = metadata.bindings
        .where((b) => b.attribute == GeometryAttribute.morphPosition)
        .toList()
      ..sort((a, b) => a.location.compareTo(b.location));

    final morphNormalBindings = metadata.bindings
        .where((b) => b.attribute == GeometryAttribute.morphNormal)
        .toList()
      ..sort((a, b) => a.location.compareTo(b.location));

    final int morphCount = math.min(morphPositionBindings.length, _maxMorphTargets);
    if (morphCount > 0) {
      final positionNames = <String>[];
      final normalNames = <String>[];

      for (int index = 0; index < morphCount; index++) {
        final binding = morphPositionBindings[index];
        final name = 'morphPosition$index';
        vertexInputExtra.writeln('  @location(${binding.location}) $name: vec3<f32>,');
        positionNames.add(name);
      }

      for (int index = 0; index < math.min(morphNormalBindings.length, morphCount); index++) {
        final binding = morphNormalBindings[index];
        final name = 'morphNormal$index';
        vertexInputExtra.writeln('  @location(${binding.location}) $name: vec3<f32>,');
        normalNames.add(name);
      }

      vertexAssignExtra.writeln('  var blendedPosition = position;');
      vertexAssignExtra.writeln('  var blendedNormal = normal;');

      const components = ['x', 'y', 'z', 'w'];
      for (int index = 0; index < morphCount; index++) {
        final source = (index < 4) ? 'uniforms.morphInfluences0' : 'uniforms.morphInfluences1';
        final comp = components[index % 4];
        final weightName = 'morphWeight$index';
        
        vertexAssignExtra.writeln('  let $weightName = $source.$comp;');
        vertexAssignExtra.writeln('  blendedPosition = blendedPosition + ${positionNames[index]} * $weightName;');
        
        if (index < normalNames.length) {
          vertexAssignExtra.writeln('  blendedNormal = blendedNormal + ${normalNames[index]} * $weightName;');
        }
      }
      
      vertexAssignExtra.writeln('  position = blendedPosition;');
      vertexAssignExtra.writeln('  normal = normalize(blendedNormal);');
    }

    return {
      'VERTEX_INPUT_EXTRA': vertexInputExtra.toString(),
      'VERTEX_OUTPUT_EXTRA': vertexOutputExtra.toString(),
      'VERTEX_ASSIGN_EXTRA': vertexAssignExtra.toString(),
      'FRAGMENT_INPUT_EXTRA': fragmentInputExtra.toString(),
      'FRAGMENT_INIT_EXTRA': fragmentInitExtra.toString(),
      'FRAGMENT_EXTRA': fragmentExtra.toString(),
      'FRAGMENT_BINDINGS': fragmentBindings.toString(),
    };
  }

  _MaterialOverrideResult _buildMaterialOverrides(
    Material? material,
    MaterialDescriptor descriptor,
    GeometryMetadata metadata,
  ) {
    final vertexOutputExtra = StringBuffer();
    final vertexAssignExtra = StringBuffer();
    final fragmentInputExtra = StringBuffer();
    final fragmentBindings = StringBuffer();
    final fragmentInitExtra = StringBuffer();
    final fragmentExtra = StringBuffer();

    final bool hasUv = metadata.bindingFor(GeometryAttribute.uv0) != null;
    final bool hasTangent = metadata.bindingFor(GeometryAttribute.tangent) != null;
    final bool hasUv2 = metadata.bindingFor(GeometryAttribute.uv1) != null;

    // Optimized inline addition substituting Kotlin's buildList logic
    int basicVolumeLocation = 1 + (hasUv ? 1 : 0) + (hasUv2 ? 1 : 0) + (hasTangent ? 1 : 0);

    // Helper local lookup replacing Kotlin extension property expression
    MaterialBinding? findBinding(MaterialBindingSource source, MaterialBindingType type) {
      for (final b in descriptor.bindings) {
        if (b.source == source && b.type == type) return b;
      }
      return null;
    }

    bool usesAlbedoMap = false;
    bool usesNormalMap = false;
    bool usesVolumeMap = false;

    if (material is MeshBasicMaterial) {
      final texture = material.map;
      if (texture is Data3DTexture) {
        final textureBinding = findBinding(MaterialBindingSource.volumeTexture, MaterialBindingType.texture3d);
        final samplerBinding = findBinding(MaterialBindingSource.volumeTexture, MaterialBindingType.sampler);

        if (textureBinding != null && samplerBinding != null) {
          vertexOutputExtra.writeln('  @location($basicVolumeLocation) volumeCoord: vec3<f32>,');
          vertexAssignExtra.writeln('  output.volumeCoord = clamp(position * 0.5 + vec3<f32>(0.5), vec3<f32>(0.0), vec3<f32>(1.0));');
          fragmentInputExtra.writeln('  @location($basicVolumeLocation) volumeCoord: vec3<f32>,');
          fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialVolumeTexture: texture_3d<f32>;');
          fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialVolumeSampler: sampler;');
          fragmentInitExtra.writeln('  let volumeSample = textureSample(materialVolumeTexture, materialVolumeSampler, input.volumeCoord);');
          fragmentInitExtra.writeln('  color = clamp(color * volumeSample.rgb, vec3<f32>(0.0), vec3<f32>(1.0));');
          usesVolumeMap = true;
        }
      } else if (texture != null && hasUv) {
        final textureBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
        final samplerBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.sampler);

        if (textureBinding != null && samplerBinding != null) {
          fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialAlbedoTexture: texture_2d<f32>;');
          fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialAlbedoSampler: sampler;');
          fragmentInitExtra.writeln('  let albedoSample = textureSample(materialAlbedoTexture, materialAlbedoSampler, input.uv);');
          fragmentInitExtra.writeln('  color = clamp(color * albedoSample.rgb, vec3<f32>(0.0), vec3<f32>(1.0));');
          usesAlbedoMap = true;
        }
      }
    } else if (material is MeshStandardMaterial) {
      if (material.map != null && hasUv) {
        final textureBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
        final samplerBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.sampler);

        if (textureBinding != null && samplerBinding != null) {
          fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialAlbedoTexture: texture_2d<f32>;');
          fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialAlbedoSampler: sampler;');
          fragmentInitExtra.writeln('  let albedoSample = textureSample(materialAlbedoTexture, materialAlbedoSampler, input.uv);');
          fragmentInitExtra.writeln('  baseColor = clamp(baseColor * albedoSample.rgb, vec3<f32>(0.0), vec3<f32>(1.0));');
          usesAlbedoMap = true;
        }
      }

      if (material.normalMap != null && hasUv) {
        if (hasTangent) {
          final textureBinding = findBinding(MaterialBindingSource.normalMap, MaterialBindingType.texture2d);
          final samplerBinding = findBinding(MaterialBindingSource.normalMap, MaterialBindingType.sampler);

          if (textureBinding != null && samplerBinding != null) {
            fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialNormalTexture: texture_2d<f32>;');
            fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialNormalSampler: sampler;');
            fragmentInitExtra.writeln('  let mappedNormal = textureSample(materialNormalTexture, materialNormalSampler, input.uv).xyz * 2.0 - vec3<f32>(1.0);');
            fragmentInitExtra.writeln('  let baseNormal = N;');
            fragmentInitExtra.writeln('  let tangent = normalize(input.tangent.xyz);');
            fragmentInitExtra.writeln('  let bitangent = normalize(cross(baseNormal, tangent)) * input.tangent.w;');
            fragmentInitExtra.writeln('  let tbn = mat3x3<f32>(tangent, bitangent, baseNormal);');
            fragmentInitExtra.writeln('  N = normalize(tbn * mappedNormal);');
            usesNormalMap = true;
          }
        } else {
          console.warning('Warning: Normal map assigned to ${material.name} but geometry lacks tangents; falling back to vertex normals.');
        }
      }
    }

    final overrides = <String, String>{};
    if (vertexOutputExtra.isNotEmpty) overrides['VERTEX_OUTPUT_EXTRA'] = vertexOutputExtra.toString();
    if (vertexAssignExtra.isNotEmpty) overrides['VERTEX_ASSIGN_EXTRA'] = vertexAssignExtra.toString();
    if (fragmentInputExtra.isNotEmpty) overrides['FRAGMENT_INPUT_EXTRA'] = fragmentInputExtra.toString();
    if (fragmentBindings.isNotEmpty) overrides['FRAGMENT_BINDINGS'] = fragmentBindings.toString();
    if (fragmentInitExtra.isNotEmpty) overrides['FRAGMENT_INIT_EXTRA'] = fragmentInitExtra.toString();
    if (fragmentExtra.isNotEmpty) overrides['FRAGMENT_EXTRA'] = fragmentExtra.toString();

    return _MaterialOverrideResult(
      overrides: overrides,
      usesAlbedoMap: usesAlbedoMap,
      usesNormalMap: usesNormalMap,
      usesVolumeMap: usesVolumeMap,
    );
  }

  Map<String, String> _mergeShaderOverrides(List<Map<String, String>> overrideMaps) {
    const concatKeys = {
      'VERTEX_INPUT_EXTRA',
      'VERTEX_OUTPUT_EXTRA',
      'VERTEX_ASSIGN_EXTRA',
      'FRAGMENT_INPUT_EXTRA',
      'FRAGMENT_INIT_EXTRA',
      'FRAGMENT_EXTRA',
      'FRAGMENT_BINDINGS',
    };

    // LinkedHashMap is the standard map in Dart preserving insertion order
    final result = <String, String>{};

    for (final map in overrideMaps) {
      map.forEach((key, value) {
        if (concatKeys.contains(key)) {
          final existing = result[key];
          if (existing == null || existing.isEmpty) {
            result[key] = value;
          } else if (value.isEmpty) {
            result[key] = existing;
          } else {
            final buffer = StringBuffer(existing);
            if (!existing.endsWith('\n')) {
              buffer.write('\n');
            }
            buffer.write(value);
            result[key] = buffer.toString();
          }
        } else {
          result[key] = value;
        }
      });
    }

    for (final key in concatKeys) {
      if (!result.containsKey(key)) {
        result[key] = '';
      }
    }

    return result;
  }

  void setSize(int width, int height, bool updateStyle) {
    // Update structural tracking sizes on the host target canvas view bounds
    frame.width = width;
    frame.height = height;
    
    if (_presentationCanvas != null) {
      _presentationCanvas!.width = width;
      _presentationCanvas!.height = height;
    }

    _viewport = Vector4(0, 0, width.toDouble(), height.toDouble());
    //_ensureDepthTexture(width, height, );
  }
  
  GpuRenderPipeline? _getOrCreatePipeline(
    ResolvedMaterialDescriptor resolved,
    MaterialShaderDescriptor shaderDescriptor,
    EnvironmentBinding? environmentBinding,
    MaterialTextureBinding? materialBinding,
    List<GpuVertexBufferLayout> vertexLayouts,
  ) {
    final gpuDevice = _device;
    final shaderSource = MaterialShaderGenerator.compile(shaderDescriptor);
    final renderState = resolved.renderState;

    final DepthStencilStateDescriptor? depthState = renderState.depthTest ? DepthStencilStateDescriptor(
      format: renderState.depthFormat,
      depthWriteEnabled: renderState.depthWrite,
      depthCompare: renderState.depthCompare,
    ) : null;

    final pipelineDescriptor = RenderPipelineDescriptor(
      label: resolved.descriptor.key,
      vertexShader: shaderSource.vertexSource,
      fragmentShader: shaderSource.fragmentSource,
      vertexLayouts: vertexLayouts,
      primitiveTopology: renderState.topology,
      cullMode: renderState.cullMode,
      frontFace: renderState.frontFace,
      depthStencilState: depthState,
      colorTarget: renderState.colorTarget.copyWith(format: frame.format),
      multisampleState: MultisampleStateDescriptor(
        count: 1, 
        mask: GpuColorWrite.all, 
        alphaToCoverageEnabled: false
      )
    );

    final cacheKey = PipelineKey.fromDescriptor(pipelineDescriptor);

    if (_pipelineCacheMap.containsKey(cacheKey)) {
      final cached = _pipelineCacheMap[cacheKey]!;
      if (cached.isReady) {
        return cached.getPipeline();
      }
    }

    if (!_pipelineCacheMap.containsKey(cacheKey)) {
      console.info("Creating new pipeline for ${resolved.descriptor.key}");
      final pipeline = WebGPUPipeline(gpuDevice, pipelineDescriptor);
      _pipelineCacheMap[cacheKey] = pipeline;

      try {
        final layoutByGroup = <int, GpuBindGroupLayout>{};

        if (materialBinding != null) {
          final textureGroups = <int>{};
          textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.albedoMap));
          textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.normalMap));
          textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.volumeTexture));
          
          // Match Kotlin's .filter { it > 0 } rule
          for (final group in textureGroups) {
            if (group > 0) {
              layoutByGroup[group] = materialBinding.layout;
            }
          }
        }

        if (resolved.descriptor.requiresBinding(MaterialBindingSource.environmentPrefilter)) {
          final environmentLayout = environmentBinding?.layout;
          if (environmentLayout == null) return null;

          final envGroups = resolved.descriptor.bindingGroups(MaterialBindingSource.environmentPrefilter);
          for (final group in envGroups) {
            if (group > 0) {
              layoutByGroup[group] = environmentLayout;
            }
          }
        }

        // Sort keys numerically to perfectly match Kotlin's sortedBy { it.key }.map { it.value }
        final sortedKeys = layoutByGroup.keys.toList()..sort();
        final extraLayouts = sortedKeys.map((key) => layoutByGroup[key]!).toList();

        // Delegate layout structure layout to the UniformBufferManager just like Kotlin
        final pipelineLayoutWrapper = _uniformManager.pipelineLayout(extraLayouts);
        if (pipelineLayoutWrapper == null) {
          console.info('Pipeline aborted: uniform layout not ready');
          return null;
        }

        // Trigger pipeline compilation
        int result = pipeline.create(pipelineLayoutWrapper);
        if(result == -1){
          _pipelineCacheMap.remove(cacheKey);
        }
      } catch (e) {
        console.info("Pipeline creation exception: ${e.toString()}");
        _pipelineCacheMap.remove(cacheKey);
        return null;
      }
    }

    return _pipelineCacheMap[cacheKey]?.getPipeline();
  }

  void _ensureMsaaColorTexture(int width, int height, GpuTextureFormat format) {
    if (width <= 0 || height <= 0) return;
    if (_msaaColorTexture != null && _msaaColorWidth == width && _msaaColorHeight == height) return;

    _msaaColorTexture?.destroy();

    try {
      final texture = _device.createTexture(
        label: 'MSAA Color Texture',
        width: width,
        height: height,
        depthOrArrayLayers: 1,
        format: format,
        usage: GpuTextureUsage.renderAttachment | GpuTextureUsage.textureBinding, 
        sampleCount: 4, // Explicitly match your 4x pipeline setting
      );
      _msaaColorTexture = texture;
      _msaaColorTextureView = texture.createView();
      _msaaColorWidth = width;
      _msaaColorHeight = height;
    } catch (e) {
      console.info('Failed to create MSAA color target: $e');
      _msaaColorTexture = null;
      _msaaColorTextureView = null;
      _msaaColorWidth = 0;
      _msaaColorHeight = 0;
    }
  }

  void _ensureDepthTexture(int width, int height, {int sampleCount = 1}) {
    if (width <= 0 || height <= 0) return;
    if (_depthTexture != null && _depthTextureWidth == width && _depthTextureHeight == height) return;

    if (_depthTexture != null && _depthTextureBytes > 0) {
      _statsTracker.recordTextureDisposed(_depthTextureBytes);
      _depthTextureBytes = 0;
    }

    _depthTexture?.destroy();

    // Create standard depth textures allocations natively via the device
    try {
      final texture = _device.createTexture(
        label: 'Depth Texture',
        width: width, 
        height: height, 
        depthOrArrayLayers: 1,
        format: GpuTextureFormat.depth24Plus,
        usage: GpuTextureUsage.renderAttachment,
        sampleCount: sampleCount,
      );

      _depthTexture = texture;
      _depthTextureView = texture.createView();
      _depthTextureWidth = width;
      _depthTextureHeight = height;

      const int bytesPerPixel = 4; // DEPTH24_PLUS uniform approximation tracking layout bounds
      _depthTextureBytes = width * height * bytesPerPixel;
      _statsTracker.recordTextureCreated(_depthTextureBytes);
    } catch (e) {
      console.info('Failed to create depth texture target: $e');
      _depthTexture = null;
      _depthTextureView = null;
      _depthTextureWidth = 0;
      _depthTextureHeight = 0;
      _depthTextureBytes = 0;
    }
  }
}

// Simple immutable target structure mapping Kotlin data class output values
class _MaterialOverrideResult {
  const _MaterialOverrideResult({
    required this.overrides,
    required this.usesAlbedoMap,
    required this.usesNormalMap,
    required this.usesVolumeMap,
  });

  final Map<String, String> overrides;
  final bool usesAlbedoMap;
  final bool usesNormalMap;
  final bool usesVolumeMap;
}

// Global Core Infrastructure Wrapper Result Types Definitions Utilities
abstract class Result<T> {
  const Result();
  const factory Result.success(T data) = SuccessResult<T>;
  const factory Result.error(String message, [Object? cause]) = ErrorResult<T>;
}

class SuccessResult<T> extends Result<T> {
  const SuccessResult(this.data);
  final T data;
}

class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.message, [this.cause]);
  final String message;
  final Object? cause;
}