import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_gpux/flutter_gpux.dart';
import 'package:three_js_core/three_js_core.dart';
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
import 'WebGPUBufferManager.dart';
import 'WebGPUEnvironmentManager.dart';
import 'WebGPUMaterialTextureManager.dart';
import 'WebGPUPipeline.dart';
import 'WebGPURenderPassManager.dart';
import '../../lighting/SceneLightingUniforms.dart';
import '../material/MaterialDescriptionRegistry.dart';

class WebGPURenderer extends Renderer {
  WebGPURenderer(this.frame);

  GpuFrame frame;

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

  // Feature 020 Managers (T020)
  WebGPUBufferManager? _bufferManager;
  WebGPURenderPassManager? _renderPassManager;

  // Rendering lifecycle state variables
  WebGPUPipeline? _currentPipeline;
  int _frameCount = 0;
  int _triangleCount = 0;
  int _drawCallCount = 0;
  int _drawIndexInFrame = 0;

  // Geometry buffer cache and uniform managers
  late final GeometryBufferCache _geometryCache = GeometryBufferCache(deviceProvider: () => _device, statsTracker: _statsTracker);
  late final UniformBufferManager _uniformManager = UniformBufferManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  // Cache lookups
  final Map<PipelineKey, WebGPUPipeline> _pipelineCacheMap = {};

  // Canvas context configurations defaults
  GpuTextureFormat _canvasFormat = GpuTextureFormat.bgra8Unorm;

  // Depth-stencil target GPU attachments resources references
  GpuTexture? _depthTexture;
  GpuTextureView? _depthTextureView;
  int _depthTextureWidth = 0;
  int _depthTextureHeight = 0;
  int _depthTextureBytes = 0;

  Color actualClearColor = Color(0.0, 0.0, 0.0, 1.0);

  RendererCapabilities? _rendererCapabilities;

  // Viewport mapping configurations variables
  late Vector4 _viewport = Vector4(0, 0, frame.width.toDouble(), frame.height.toDouble());

  /// T033: Debug flag for verbose frame logging
  bool enableFrameLogging = false;

  // Renderer interface property overrides
  final BackendType backend = BackendType.webgpu;

  @override
  RendererCapabilities get capabilities => _rendererCapabilities ?? _createDefaultCapabilities();

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
  Future<Result<void>> initialize(RendererConfig config) async {
    // For WebGPU, surface rendering canvas binding constraints are pre-configured
    return _initializeInternal();
  }

  /// Internal hardware driver setup loop using cross-platform async sequences.
  Future<Result<void>> _initializeInternal() async {
    try {
      print('T033: Starting WebGPU renderer initialization...');
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
          print('T033: ⚠️ WebGPU device lost: $info');
          _contextLossRecovery.handleContextLoss();
        } catch (e) {
          print('T033: Error handling device loss routine: $e');
        }
      });

      // Browser bug presentation layer fallback workarounds are handled implicitly 
      // by the multi-platform canvas context abstraction wrapper layer.
      print('T033: Configuring canvas context surface presentation pipeline...');
      
      // Fixed: context configuration is managed per frame target view inside flutter_gpux/gpuweb_js
      _canvasFormat = GpuTextureFormat.bgra8Unorm;

      print('T033: Rebuilding depth attachments buffers targets...');
      _ensureDepthTexture(frame.width, frame.height);

      print('T033: Allocating sub-system tracking memory buffer pools...');
      _bufferPool = BufferPool(_device);
      _bufferManager = WebGPUBufferManager(_device);
      
      _uniformManager.onDeviceReady(_device);
      _materialTextureManager.onDeviceReady(_device);

      print('T033: Resolving adapter limits capabilities profiles...');
      _rendererCapabilities = _createCapabilities(_adapter!);
      print('T033: Capabilities detected: maxTextureSize=${_rendererCapabilities!.maxTextureSize}');

      // Execute internal backend architecture text module checks
      print('T033: Validating WGSL shader compilation pipelines components...');
      final probeResult = await _validateWgslSupport(_device);
      if (probeResult is ErrorResult) {
        print('T033: WGSL validation failed, aborting sequence: ${probeResult.message}');
        _cleanupPartialInit();
        return Result.error(probeResult.message);
      }

      _isInitialized = true;
      print('T033: WebGPU renderer completed setup in ${stopwatch.elapsedMilliseconds}ms');
      return const Result.success(null);
    } catch (e, stack) {
      print('T033: ❌ FATAL CRASH during renderer initialization: $e');
      print('T033: Trace: $stack');
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
      print('RAW-CLEAR-TEST: Submitted red clear commands buffer. Presentation works if viewport is red.');
    } catch (e) {
      print('RAW-CLEAR-TEST: FAILED: $e');
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
      print('T033: Exception tracking during internal WGSL validation: $e');
      return Result.error('WGSL shader validation threw unexpected exception: ${e.toString()}', e);
    }
  }

  /// Clean up intermediate resources allocated during an initialization failure cycle.
  void _cleanupPartialInit() {
    try {
      _bufferManager = null;
      _renderPassManager = null;
      
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
      print('T033: Error executing validation failure cleanup routine sequence: $e');
    }
  }

  void dispose() {
    _renderPassManager = null;
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
    _bufferManager = null;
    
    if (_depthTexture != null && _depthTextureBytes > 0) {
      _statsTracker.recordTextureDisposed(_depthTextureBytes);
      _depthTextureBytes = 0;
    }
    
    _depthTexture?.destroy();
    _depthTexture = null;
    _depthTextureView = null;
    _depthTextureWidth = 0;
    _depthTextureHeight = 0;
    _contextLossRecovery.clear();
    
    _adapter = null;
    
    _presentationCanvas = null;
    _rendererCapabilities = null;
    _currentPipeline = null;
    
    _drawIndexInFrame = 0;
    _drawCallCount = 0;
    _triangleCount = 0;
    _frameCount = 0;
    _isInitialized = false;
    _statsTracker.reset();
  }
  void render(Object3D scene, Camera camera){}

  GpuRenderPipeline? _pipeline;
  GpuBuffer? _vertexBuffer;
  GpuBuffer? _uniformBuffer;
  GpuBindGroup? _bindGroup;
  double _rotation = 0.0;

  void _ensureResourcesInitialized(GpuDevice device, GpuTextureFormat canvasFormat) {
    if (_pipeline != null) return;

    final vertexData = Float32List.fromList([
       0.0,  0.5, 0.0,  1.0, 0.0, 0.0, // Top Vertex
      -0.5, -0.5, 0.0,  0.0, 1.0, 0.0, // Bottom Left
       0.5, -0.5, 0.0,  0.0, 0.0, 1.0, // Bottom Right
    ]);

    _vertexBuffer = device.createBuffer(
      label: 'Vertex Data Buffer',
      size: vertexData.lengthInBytes,
      usage: GpuBufferUsage.vertex,
      mappedAtCreation: true,
    );
    _vertexBuffer!.getMappedRange().asFloat32List().setAll(0, vertexData);
    _vertexBuffer!.unmap();

    _uniformBuffer = device.createBuffer(
      label: 'Rotation Uniform Buffer',
      size: 16,
      usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
    );

    const wgslShaderCode = '''
      struct Uniforms {
          rotation: f32,
      }
      @group(0) @binding(0) var<uniform> u: Uniforms;

      struct VertexInput {
          @location(0) pos: vec3<f32>,
          @location(1) color: vec3<f32>,
      }
      struct VertexOutput {
          @builtin(position) position: vec4<f32>,
          @location(0) color: vec3<f32>,
      }

      @vertex fn vs_main(in: VertexInput) -> VertexOutput {
          var out: VertexOutput;
          let s = sin(u.rotation);
          let c = cos(u.rotation);
          let rotX = in.pos.x * c - in.pos.y * s;
          let rotY = in.pos.x * s + in.pos.y * c;
          out.position = vec4<f32>(rotX, rotY, in.pos.z, 1.0);
          out.color = in.color;
          return out;
      }

      @fragment fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
          return vec4<f32>(in.color, 1.0);
      }
    ''';

    final shaderModule = device.createShaderModule(
      wgslShaderCode,
      label: 'Shader Module Source',
    );

    // Fixed: Uses list array syntax matching your local GpuBindGroupLayout layout
    final bindGroupLayout = device.createBindGroupLayout(
      [
        GpuBindGroupLayoutEntry.buffer(
          binding: 0,
          visibility: GpuShaderStage.vertex,
        ),
      ],
      label: 'Uniforms Bind Layout',
    );

    _bindGroup = device.createBindGroup(
      label: 'Uniforms Material Bind Group',
      layout: bindGroupLayout,
      entries: [
        GpuBindGroupEntry.buffer(binding: 0, buffer: _uniformBuffer!),
      ],
    );

    // Fixed: Pass layout array straight to pipeline constructor wrapper
    final pipelineLayout = device.createPipelineLayout([bindGroupLayout]);

    _pipeline = device.createRenderPipeline(
      GpuRenderPipelineDescriptor(
        label: 'Triangle Render Pipeline',
        layout: pipelineLayout,
        vertexModule: shaderModule,
        vertexEntryPoint: 'vs_main',
        vertexBuffers: [
          GpuVertexBufferLayout(
            arrayStride: 6 * 4,
            attributes: const [
              GpuVertexAttribute(shaderLocation: 0, format: GpuVertexFormat.float32x3, offset: 0),
              GpuVertexAttribute(shaderLocation: 1, format: GpuVertexFormat.float32x3, offset: 3 * 4),
            ],
          ),
        ],
        fragmentModule: shaderModule,
        fragmentEntryPoint: 'fs_main',
        colorTargets: [GpuColorTargetState(format: canvasFormat)],
        primitiveTopology: GpuPrimitiveTopology.triangleList,
        cullMode: GpuCullMode.none,
      ),
    );
  }
  void render2(Object3D scene, Camera camera, GpuFrame frame) {
    // 1. Lazy initialize GPU resources using the device provided by the GpuFrame context
    // Fixed: Passing frame.device and pulling canvas format out cleanly
    _ensureResourcesInitialized(frame.device, frame.format);

    // 2. Animate and update uniform data using the Uint8List buffer view
    _rotation += 0.01;
    final uniformsData = Float32List.fromList([_rotation, 0.0, 0.0, 0.0]);
    
    // Fixed: Converting Float32List to Uint8List for buffer submission compatibility
    frame.device.queue.writeBuffer(
      _uniformBuffer!,
      uniformsData.buffer.asUint8List(),
    );

    // 3. Allocate execution command encoder with direct label positional syntax
    final commandEncoder = frame.device.createCommandEncoder(
      label: 'Main Command Encoder',
    );

    // 4. Begin render pass using GpuColorAttachment structures matching your local package definitions
    final renderPass = commandEncoder.beginRenderPass(
      label: 'Primary Render Pass',
      colorAttachments: [
        GpuColorAttachment(
          view: frame.targetView, // Fixed: Extracted correctly from the native frame context loop
          loadOp: GpuLoadOp.clear,
          clearValue: const GpuColor(0.05, 0.05, 0.1, 1.0),
          storeOp: GpuStoreOp.store,
        ),
      ],
    );

    // 5. Bind Graphics Pipelines and buffers
    renderPass.setPipeline(_pipeline!);
    renderPass.setVertexBuffer(0, _vertexBuffer!);
    renderPass.setBindGroup(0, _bindGroup!);
    
    // Fixed: Invoking named properties according to your parameter signature limits
    renderPass.draw(
      vertexCount: 3, 
      instanceCount: 1, 
      firstVertex: 0, 
      firstInstance: 0,
    );
    renderPass.end();

    // 6. Finalize commands and push right out onto the device frame timeline queue channel
    final commandBuffer = commandEncoder.finish();
    frame.device.queue.submit([commandBuffer]);
  }

  void render1(Object3D scene, Camera camera, GpuFrame frame) {
    // Validate that the system hardware and frame target state are healthy before evaluating instructions
    if (!_isInitialized) {
      print('T033: Renderer not initialized, cannot render');
      //return;
    }

    _statsTracker.frameStart();
    _statsTracker.recordIBLConvolution(IBLConvolutionProfiler.snapshot());
    _statsTracker.recordIBLMaterial(0.0, 0);

    final bool diag = _frameCount < _diagFrames;

    if (enableFrameLogging) {
      print('T033: [Frame $_frameCount] Starting render...');
    }

    try {
      _triangleCount = 0;
      _drawCallCount = 0;
      _drawIndexInFrame = 0;

      // Execute standard scene matrix world transformations
      scene.updateMatrixWorld(true);
      
      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Updating camera matrices...');
      }
      camera.updateMatrixWorld();
      camera.updateProjectionMatrix();

      // Multiply camera matrices using the engine matrix models math package
      final projectionViewMatrix = Matrix4()
        ..setFrom(camera.projectionMatrix)
        ..multiply(camera.matrixWorldInverse);

      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Creating frustum for culling...');
      }
      final frustum = Frustum()..setFromMatrix(projectionViewMatrix);

      // Fetch the active frame target view attachment out from the canvas context layer
      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Getting current texture from swap chain...');
      }

      _ensureDepthTexture(frame.width, frame.height);
      final depthView = _depthTextureView;
      
      if (depthView == null && diag) {
        print('⚠️ Depth texture unavailable; rendering without depth buffer');
      }

      // Allocate the execution timeline command encoder directly via the device instance
      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Creating command encoder...');
      }
      final commandEncoder = frame.device.createCommandEncoder(label: 'Main Command Encoder');

      // Feature 020 Render Pass instantiation wrapper pipeline
      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Initializing RenderPassManager...');
      }
      _renderPassManager = WebGPURenderPassManager(commandEncoder)..enableDiagnostics = diag;

      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Beginning render pass (clearColor=[${actualClearColor.red}, ${actualClearColor.green}, ${actualClearColor.blue}])...');
      }

      // Build specification attachment maps using gpux model descriptors arrays blocks
      // final GpuRenderPassEncoder renderPass = commandEncoder.beginRenderPass(
      //     label: 'Primary Render Pass',
      //     colorAttachments: [
      //       GpuColorAttachment(
      //         view: frame.targetView,
      //         loadOp: GpuLoadOp.clear,
      //         clearValue: GpuColor(
      //           scene.background.red, 
      //           scene.background.green, 
      //           scene.background.blue, 
      //           clearAlpha
      //         ),
      //         storeOp: GpuStoreOp.store,
      //       ),
      //     ],
      //     depthStencilAttachment: depthView != null
      //         ? GpuDepthStencilAttachment(
      //             view: depthView,
      //             depthLoadOp: GpuLoadOp.clear,
      //             depthClearValue: 1.0,
      //             depthStoreOp: GpuStoreOp.store,
      //           )
      //         : null,
      // );
final GpuRenderPassEncoder renderPass = commandEncoder.beginRenderPass(
  label: 'Main Render Pass',
  colorAttachments: [
    GpuColorAttachment(
      view: frame.targetView,
      loadOp: GpuLoadOp.clear,
      clearValue: GpuColor(0.2, 0.2, 0.2, 1.0), // Dark Grey
      storeOp: GpuStoreOp.store,
    ),
  ],
  depthStencilAttachment: null, // Isolate depth attachment issues
);
      if (diag) {
        print('RENDER[$_frameCount]: beginRenderPass OK');
      }

      // Extract light descriptors transformations data properties out from scene graph
      final sceneBrdf = scene.userData['environmentBrdfLut'] as Texture2D?;
      final lightingUniforms = collectSceneLightingUniforms(scene);
      final environmentBinding = _environmentManager.prepare(scene.environment as CubeTexture?, sceneBrdf);

      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Traversing scene graph and rendering meshes...');
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
        print('RENDER[$_frameCount]: meshes rendered=$_drawCallCount, triangles=$_triangleCount, first=$firstMeshName, last=$lastMeshName');
      }

      // Close and seal execution descriptors arrays loops steps blocks
      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Ending render pass...');
      }
      renderPass.end();

      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Finishing command encoder...');
      }
      final commandBuffer = commandEncoder.finish();

      if (enableFrameLogging) {
        print('T033: [Frame $_frameCount] - Submitting command buffer to GPU...');
      }
      
      // Submit arrays parameters to native execution stream queue directly off the logical device channel reference
      frame.device.queue.submit([commandBuffer]);
      
      if (diag) {
        print('RENDER[$_frameCount]: submitted successfully via device queue timeline channel');
      }

      // Blit presentation layers workaround blocks logic goes here if active...
      _frameCount++;
    } catch (e, stack) {
      print('T033: ❌ ERROR during execution frame loop lifecycle trace cycle: $e');
      print(stack);
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
      print('Warning: Material ${descriptor.key} requires texture bindings but none were prepared; skipping mesh');
      return;
    }
  }

  // Extract layout configurations structurally across buffers streams list
  final bufferLayouts = buffers.vertexStreams.map((e) => e.layout).toList();

  final pipeline = _getOrCreateZeroUniform3dPipeline(_device, bufferLayouts);
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

  // 3. Acquire Uniform Bind Group
  final bindGroup = _uniformManager.bindGroup();
  if (bindGroup == null) return;

  final int dynamicOffset = _uniformManager.dynamicOffset(_drawIndexInFrame);
  renderPass.setBindGroup(0, bindGroup, dynamicOffsets: [dynamicOffset]);

  // // Bind additional custom shader pipeline groups
  // _bindAdditionalGroups(descriptor, materialTextureBinding, environmentBinding, renderPass);

  // final Float32List matrixData = Float32List(88);
  // final projStorage = camera.projectionMatrix.storage;
  // final viewStorage = camera.matrixWorldInverse.storage;
  // final modelStorage = mesh.matrixWorld.storage;

  // // Transpose column-major on-the-fly to row-major for WebGPU vector alignment [INDEX]
  // for (int i = 0; i < 16; i++) {
  //   matrixData[i] = projStorage[i];
  //   matrixData[16 + i] = viewStorage[i];
  //   matrixData[32 + i] = modelStorage[i];
  // }

  // // Lazy instantiate a clean 192-byte GPU Buffer on the first frame
  // if (_manualUniformBuffer == null) {
  //   _manualUniformBuffer = _device.createBuffer(
  //     size: 512 * 100,
  //     usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
  //     label: 'Manual Sphere Uniform Buffer',
  //   );

  //   // Compile a local bind group pointing strictly to this buffer
  //   final uniformEntry = GpuBindGroupLayoutEntry.buffer(
  //     binding: 0,
  //     visibility: GpuShaderStage.vertex,
  //     type: GpuBufferBindingType.uniform,
  //     hasDynamicOffset: true,
  //     minBindingSize: 352,
  //   );
  //   final GpuBindGroupLayout groupLayout = _device.createBindGroupLayout([uniformEntry]);

  //   _manualBindGroup = _device.createBindGroup(
  //     layout: groupLayout,
  //     entries: [
  //       GpuBufferBinding(
  //         binding: 0,
  //         buffer: _manualUniformBuffer!,
  //         offset: 0,
  //         size: 352,
  //       ),
  //     ],
  //   );
  // }

  // final int testDynamicOffset = 0; 
  // // Upload your freshly calculated matrix data뷰 directly to the native hardware stream queue
  // // Use your working framework upload function format, or native queue method:
  // final byteData = matrixData.buffer.asByteData(matrixData.offsetInBytes, matrixData.lengthInBytes);
  // _device.queue.writeBuffer(_manualUniformBuffer!, byteData.buffer.asUint8List(), bufferOffset: 0);

  // // Bind our local safe bind group with no dynamic offsets array
  // if (_manualBindGroup != null) {
  //   renderPass.setBindGroup(0, _manualBindGroup!, dynamicOffsets: [testDynamicOffset]);
  // }

  // 4. DRAW
  final int instanceCount = buffers.instanceCount > 0 ? buffers.instanceCount : 1;
  if (buffers.indexBuffer != null && buffers.indexCount > 0) {
    renderPass.setIndexBuffer(buffers.indexBuffer!, buffers.indexFormat);
    renderPass.drawIndexed(indexCount: buffers.indexCount, instanceCount: instanceCount);
  } else {
    renderPass.draw(vertexCount: buffers.vertexCount, instanceCount: instanceCount);
  }

  _drawCallCount++;
  _drawIndexInFrame++;
}

  void _renderMesh1(
    Mesh mesh,
    Camera camera,
    GpuRenderPassEncoder renderPass,
    EnvironmentBinding? environmentBinding,
    SceneLightingUniforms lightingUniforms,
  ) {
    final int maxMeshesPerFrame = UniformBufferManager.maxMeshesPerFrame;
    if (_drawIndexInFrame >= maxMeshesPerFrame) return;

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
        print('Warning: Material ${descriptor.key} requires texture bindings but none were prepared; skipping mesh');
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

    final frameInfo = FrameDebugInfo(frameCount: _frameCount, drawCallCount: _drawCallCount);
    if (!_uniformManager.updateUniforms(
      mesh: mesh,
      camera: camera,
      drawIndex: _drawIndexInFrame,
      frameInfo: frameInfo,
      enableDiagnostics: enableFrameLogging,
      materialUniforms: materialUniforms,
    )) return;

  // ====================================================================
    // 1. Bind Render Pipeline
    renderPass.setPipeline(pipeline);

    // 2. Bind Vertex Buffers slots
    for (int slot = 0; slot < buffers.vertexStreams.length; slot++) {
      renderPass.setVertexBuffer(slot, buffers.vertexStreams[slot].buffer);
    }

    // 3. Acquire Uniform Bind Group
    final bindGroup = _uniformManager.bindGroup();
    if (bindGroup == null) return;

    final int dynamicOffset = _uniformManager.dynamicOffset(_drawIndexInFrame);
    renderPass.setBindGroup(0, bindGroup, dynamicOffsets: [dynamicOffset]);

    // Bind additional custom shader pipeline groups
    _bindAdditionalGroups(descriptor, materialTextureBinding, environmentBinding, renderPass);

    // 5. TRIGGER DRAWING
    final int instanceCount = buffers.instanceCount > 0 ? buffers.instanceCount : 1;
    if (buffers.indexBuffer != null && buffers.indexCount > 0) {
      renderPass.setIndexBuffer(buffers.indexBuffer!, buffers.indexFormat);
      renderPass.drawIndexed(indexCount: buffers.indexCount, instanceCount: instanceCount);
    } else {
      renderPass.draw(vertexCount: buffers.vertexCount, instanceCount: instanceCount);
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
      final texture = material?.map;
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
      if (material?.map != null && hasUv) {
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

      if (material?.normalMap != null && hasUv) {
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
          print('Warning: Normal map assigned to ${material?.name} but geometry lacks tangents; falling back to vertex normals.');
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
    _ensureDepthTexture(width, height);
  }

GpuRenderPipeline _getOrCreateZeroUniform3dPipeline(GpuDevice device, List<GpuVertexBufferLayout?> vertexLayouts) {
  if (_zeroUniform3dPipeline != null) return _zeroUniform3dPipeline!;

  const String vertexWgsl = '''
    struct Uniforms {
      projectionMatrix: mat4x4<f32>, // 64 bytes
      viewMatrix: mat4x4<f32>,       // 64 bytes
      modelMatrix: mat4x4<f32>,      // 64 bytes
      
      // Padding slots to scale your shader description up to match your 352-byte uniform manager allocation exactly
      padding0: vec4<f32>,           // baseColor (16 bytes)
      padding1: vec4<f32>,           // pbrParams (16 bytes)
      padding2: vec4<f32>,           // cameraPosition (16 bytes)
      padding3: vec4<f32>,           // ambientColor (16 bytes)
      padding4: vec4<f32>,           // fogColor (16 bytes)
      padding5: vec4<f32>,           // fogParams (16 bytes)
      padding6: vec4<f32>,           // mainLightDirection (16 bytes)
      padding7: vec4<f32>,           // mainLightColor (16 bytes)
      padding8: vec4<f32>,           // morphInfluences0 (16 bytes)
      padding9: vec4<f32>,           // morphInfluences1 (16 bytes)
    }
    @group(0) @binding(0) var<uniform> uniforms: Uniforms;


    struct VertexInput {
      @location(0) position: vec3<f32>,
    }

    @vertex
    fn vs_main(input: VertexInput) -> @builtin(position) vec4<f32> {
      // Standard Column-Major perspective matrix multiplication order
      let worldPosition = uniforms.modelMatrix * vec4<f32>(input.position, 1.0);
      let viewPosition = uniforms.viewMatrix * worldPosition;
      return uniforms.projectionMatrix * viewPosition;
    }
  ''';

  const String fragmentWgsl = '''
    @fragment
    fn fs_main() -> @location(0) vec4<f32> {
      return vec4<f32>(1.0, 1.0, 1.0, 1.0); // Solid White 3D Sphere
    }
  ''';

  // FIXED: Explicitly build a native framework layout blueprint matching our 192-byte block
  final uniformEntry = GpuBindGroupLayoutEntry.buffer(
    binding: 0,
    visibility: GpuShaderStage.vertex,
    type: GpuBufferBindingType.uniform,
    hasDynamicOffset: true, // Keep false to ensure absolute static stability
    minBindingSize: 352,    // 3 matrices * 64 bytes
  );

  final GpuBindGroupLayout group0Layout = device.createBindGroupLayout(
    [uniformEntry],
    label: 'Inline Sphere Group Layout',
  );

  final GpuPipelineLayout explicitLayout = device.createPipelineLayout(
    [group0Layout],
    label: 'Inline Sphere Master Layout',
  );

  _zeroUniform3dPipeline = device.createRenderPipeline(GpuRenderPipelineDescriptor(
    label: 'Responsive 3D Camera Sphere Pipeline',
    layout: explicitLayout, // FIXED: Using an explicit layout prevents reflection bugs!
    vertexModule: device.createShaderModule( vertexWgsl),
    vertexEntryPoint: 'vs_main',
    vertexBuffers: vertexLayouts,
    fragmentModule: device.createShaderModule( fragmentWgsl),
    fragmentEntryPoint: 'fs_main',
    colorTargets: [
      GpuColorTargetState(
        format: GpuTextureFormat.bgra8Unorm,
        writeMask: GpuColorWrite.all,
      ),
    ],
    primitiveTopology: GpuPrimitiveTopology.triangleList,
    frontFace: GpuFrontFace.ccw,
    cullMode: GpuCullMode.none,
    depthStencil: null,
  ));

  return _zeroUniform3dPipeline!;
}

GpuBuffer? _manualUniformBuffer;
GpuBindGroup? _manualBindGroup;
GpuRenderPipeline? _zeroUniform3dPipeline;
GpuRenderPipeline? _constant3dPipeline;

GpuRenderPipeline _getOrCreateConstant3dPipeline(GpuDevice device, List<GpuVertexBufferLayout?> vertexLayouts, Map<String, double> matrixConstants) {
  // We recreate the pipeline descriptor dynamically to ingest the fresh frame constants
  const String vertexWgsl = '''
    // Declare 32 explicit pipeline constants to construct our 3D transformation matrices
    @id(0) const r0c0: f32 = 1.0; @id(1) const r0c1: f32 = 0.0; @id(2) const r0c2: f32 = 0.0; @id(3) const r0c3: f32 = 0.0;
    @id(4) const r1c0: f32 = 0.0; @id(5) const r1c1: f32 = 1.0; @id(6) const r1c2: f32 = 0.0; @id(7) const r1c3: f32 = 0.0;
    @id(8) const r2c0: f32 = 0.0; @id(9) const r2c1: f32 = 0.0; @id(10) const r2c2: f32 = 1.0; @id(11) const r2c3: f32 = 0.0;
    @id(12) const r3c0: f32 = 0.0; @id(13) const r3c1: f32 = 0.0; @id(14) const r3c2: f32 = 0.0; @id(15) const r3c3: f32 = 1.0;

    @id(16) const p0c0: f32 = 1.0; @id(17) const p0c1: f32 = 0.0; @id(18) const p0c2: f32 = 0.0; @id(19) const p0c3: f32 = 0.0;
    @id(20) const p1c0: f32 = 0.0; @id(21) const p1c1: f32 = 1.0; @id(22) const p1c2: f32 = 0.0; @id(23) const p1c3: f32 = 0.0;
    @id(24) const p2c0: f32 = 0.0; @id(25) const p2c1: f32 = 0.0; @id(26) const p2c2: f32 = 1.0; @id(27) const p2c3: f32 = 0.0;
    @id(28) const p3c0: f32 = 0.0; @id(29) const p3c1: f32 = 0.0; @id(30) const p3c2: f32 = 0.0; @id(31) const p3c3: f32 = 1.0;

    struct VertexInput {
      @location(0) position: vec3<f32>,
    }

    @vertex
    fn vs_main(input: VertexInput) -> @builtin(position) vec4<f32> {
      let modelViewMatrix = mat4x4<f32>(
        vec4<f32>(r0c0, r0c1, r0c2, r0c3),
        vec4<f32>(r1c0, r1c1, r1c2, r1c3),
        vec4<f32>(r2c0, r2c1, r2c2, r2c3),
        vec4<f32>(r3c0, r3c1, r3c2, r3c3)
      );

      let projectionMatrix = mat4x4<f32>(
        vec4<f32>(p0c0, p0c1, p0c2, p0c3),
        vec4<f32>(p1c0, p1c1, p1c2, p1c3),
        vec4<f32>(p2c0, p2c1, p2c2, p2c3),
        vec4<f32>(p3c0, p3c1, p3c2, p3c3)
      );

      // standard column-major transform
      let worldSpacePos = modelViewMatrix * vec4<f32>(input.position, 1.0);
      return projectionMatrix * worldSpacePos;
    }
  ''';

  const String fragmentWgsl = '''
    @fragment
    fn fs_main() -> @location(0) vec4<f32> {
      return vec4<f32>(1.0, 1.0, 1.0, 1.0); 
    }
  ''';

  return device.createRenderPipeline(GpuRenderPipelineDescriptor(
    label: 'Constant 3D Pipeline',
    layout: null, 
    vertexModule: device.createShaderModule(vertexWgsl),
    vertexEntryPoint: 'vs_main',
    vertexConstants: matrixConstants, // Inject properties here
    vertexBuffers: vertexLayouts,
    fragmentModule: device.createShaderModule(fragmentWgsl),
    fragmentEntryPoint: 'fs_main',
    colorTargets: [
      GpuColorTargetState(
        format: GpuTextureFormat.bgra8Unorm,
        writeMask: GpuColorWrite.all,
      ),
    ],
    primitiveTopology: GpuPrimitiveTopology.triangleList,
    frontFace: GpuFrontFace.ccw,
    cullMode: GpuCullMode.none,
    depthStencil: null,
  ));
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

    final rpd = RenderPipelineDescriptor(
      vertexShader: shaderSource.vertexSource,
      fragmentShader: shaderSource.fragmentSource,
      vertexLayouts: vertexLayouts,
      primitiveTopology: renderState.topology,
      cullMode: renderState.cullMode,
      frontFace: renderState.frontFace,
      depthStencilState: depthState,
      colorTarget: ColorTargetDescriptor(format: GpuTextureFormat.bgra8Unorm, writeMask: ColorWriteMask.all),
    );

    final cacheKey = PipelineKey.fromDescriptor(rpd);

    // Cache lookup check
    if (_pipelineCacheMap.containsKey(cacheKey)) {
      final cached = _pipelineCacheMap[cacheKey]!;
      if (cached.isReady) {
        return cached.getPipeline();
      }
    }

    print('Creating new pipeline for ${resolved.descriptor.key}');
    final pipeline = WebGPUPipeline(gpuDevice, rpd);

    try {
      final layoutByGroup = <int, GpuBindGroupLayout>{};
      
      // 1. BUILD EXPLICIT UNIFORM BIND GROUP LAYOUT FOR GROUP 0
      final uniformEntry = GpuBindGroupLayoutEntry.buffer(
        binding: 0,
        visibility: GpuShaderStage.vertex | GpuShaderStage.fragment,
        type: GpuBufferBindingType.uniform,
        hasDynamicOffset: true, // MUST remain true to support multi-mesh rendering strides
        minBindingSize: 352,    // Matches the exact WGSL Uniforms struct declaration footprint (88 floats * 4 bytes)
      );
      layoutByGroup[0] = gpuDevice.createBindGroupLayout([uniformEntry], label: 'Uniform Group 0 Layout');

      // 2. MAP COMPLIANT MATERIAL TEXTURE LAYOUT GROUPS
      if (materialBinding != null) {
        final textureGroups = <int>{};
        textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.albedoMap));
        textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.normalMap));
        textureGroups.addAll(resolved.descriptor.bindingGroups(MaterialBindingSource.volumeTexture));
        for (final group in textureGroups) {
          layoutByGroup[group] = materialBinding.layout;
        }
      }

      if (resolved.descriptor.requiresBinding(MaterialBindingSource.environmentPrefilter)) {
        final environmentLayout = environmentBinding?.layout;
        if (environmentLayout != null) {
          final envGroups = resolved.descriptor.bindingGroups(MaterialBindingSource.environmentPrefilter);
          for (final group in envGroups) {
            layoutByGroup[group] = environmentLayout;
          }
        }
      }

      // Sort and compile the pipeline layout list array
      final sortedKeys = layoutByGroup.keys.toList()..sort();
      final extraLayouts = sortedKeys.map((key) => layoutByGroup[key]!).toList();
      
      final GpuPipelineLayout pipelineLayout = gpuDevice.createPipelineLayout(
        extraLayouts,
        label: '${resolved.descriptor.key}-layout',
      );

      final creationResult = pipeline.create(pipelineLayout);
      if (creationResult == -1) {
        print('Pipeline creation failed: ${creationResult}');
        return null;
      }

      _pipelineCacheMap[cacheKey] = pipeline;
      return pipeline.getPipeline();

    } catch (e) {
      print('Pipeline creation exception trace: $e');
      return null;
    }
  }


  BufferHandle _createVertexBufferViaManager(Float32List vertices) {
    return _bufferManager!.createVertexBuffer(vertices);
  }

  BufferHandle _createIndexBufferViaManager(Uint32List indices) {
    return _bufferManager!.createIndexBuffer(indices);
  }

  BufferHandle _createUniformBufferViaManager(int sizeBytes) {
    return _bufferManager!.createUniformBuffer(sizeBytes);
  }

  void _ensureDepthTexture(int width, int height) {
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
        width: width, height: height, depthOrArrayLayers: 1,
        format: GpuTextureFormat.depth24Plus,
        usage: GpuTextureUsage.renderAttachment,
      );

      _depthTexture = texture;
      _depthTextureView = texture.createView();
      _depthTextureWidth = width;
      _depthTextureHeight = height;

      const int bytesPerPixel = 4; // DEPTH24_PLUS uniform approximation tracking layout bounds
      _depthTextureBytes = width * height * bytesPerPixel;
      _statsTracker.recordTextureCreated(_depthTextureBytes);
    } catch (e) {
      print('Failed to create depth texture target: $e');
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