import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_gpux/flutter_gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_clipping.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_properties.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_render_list.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_render_lists.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_render_states.dart';
import '../material/material_converter.dart';
import 'frame_attachments.dart';
import 'render_pass_manager.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../lighting/ibl/ibl_convolution_profiler.dart';
import '../../shader/material_shader_library.dart';
import '../renderer_capabilities.dart';
import '../renderer_config.dart';
import '../geometry/geometry_descriptor.dart';
import '../geometry/geometry_metadata_helpers.dart';
import 'buffer_pool.dart';
import 'context_loss_recovery.dart';
import 'geometry_buffer_cache.dart';
import 'pipeline_cache.dart';
import 'render_stats_tracker.dart';
import 'uniform_buffer_manager.dart';
import 'environment_manager.dart';
import 'material_texture_manager.dart';
import 'pipeline.dart';
import 'three_js_rendering/gpu_animation.dart';
import '../material/material_description_registry.dart';

class GpuRenderer extends Renderer {
  late gpux.GpuFrame frame;
  final GpuAnimation animation = GpuAnimation();
  final GpuProperties properties = GpuProperties();
  late final GpuClipping clipping = GpuClipping(properties);
  GpuRenderState? currentRenderState;
  final GpuRenderStates renderStates = GpuRenderStates();

  // Linux presentation workaround tracks
  dynamic _presentationCanvas;

  static const int _maxMorphTargets = 8;
  static const int _diagFrames = 3;

  final _statsTracker = RenderStatsTracker();
  late XRManager Function(GpuRenderer renderer, dynamic frame)? _setXR;

  // // Core Gpu components bound directly to the gpux package framework
  gpux.GpuDevice get _device => frame.device;
  gpux.GpuAdapter? _adapter;

  // Component managers (Using late initialization mirroring Kotlin's lateinit)
  PipelineCache? _pipelineCache;
  BufferPool? _bufferPool;
  
  final _contextLossRecovery = ContextLossRecovery();
  late final GpuEnvironmentManager _environmentManager = GpuEnvironmentManager(deviceProvider: () => _device, statsTracker: _statsTracker);
  late final GpuMaterialTextureManager _materialTextureManager = GpuMaterialTextureManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  // Rendering lifecycle state variables
  int _frameCount = 0;
  int _triangleCount = 0;
  int _drawCallCount = 0;
  int _drawIndexInFrame = 0;

  // Geometry buffer cache and uniform managers
  late final GeometryBufferCache _geometryCache = GeometryBufferCache(deviceProvider: () => _device, statsTracker: _statsTracker);
  late final UniformBufferManager _uniformManager = UniformBufferManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  // Cache lookups
  final Map<PipelineKey, GpuPipeline> _pipelineCacheMap = {};

  // Depth-stencil target GPU attachments resources references
  gpux.GpuTexture? _depthTexture;
  gpux.GpuTextureView? _depthTextureView;
  int _depthTextureWidth = 0;
  int _depthTextureHeight = 0;
  int _depthTextureBytes = 0;

  gpux.GpuTexture? _msaaColorTexture;
  gpux.GpuTextureView? _msaaColorTextureView;
  int _msaaColorWidth = 0;
  int _msaaColorHeight = 0;

  Color actualClearColor = Color(0.0, 0.0, 0.0, 1.0);

  RendererCapabilities? _rendererCapabilities;
  List<Plane> clippingPlanes = [];

  // Viewport mapping configurations variables
  late Vector4 _viewport = Vector4(0, 0, frame.width.toDouble(), frame.height.toDouble());
  late Vector4 _scissor = Vector4(0, 0, frame.width.toDouble(), frame.height.toDouble());
  
  final _currentViewport = Vector4.identity();
  final _currentScissor = Vector4.identity();

  /// T033: Debug flag for verbose frame logging
  bool enableFrameLogging = false;

  // @override
  // RendererCapabilities get capabilities => _rendererCapabilities ?? _createDefaultCapabilities();
  late RendererConfig config;
  GpuRenderPassManager? _renderPassManager;

  GpuRenderList? currentRenderList;
  late GpuRenderLists renderLists;
  List<GpuRenderList> renderListStack = [];
  List<GpuRenderState> renderStateStack = [];

  Function? _opaqueSort;
  Function? _transparentSort;
  double _pixelRatio = 1;

  int _currentActiveCubeFace = 0;
  int _currentActiveMipmapLevel = 0;
  RenderTarget? _currentRenderTarget;
  
  final _vector4 = Vector4();
  final _frustum = Frustum();
  final projScreenMatrix = Matrix4.identity();

  bool _clippingEnabled = false;
  bool _localClippingEnabled = false;
  bool localClippingEnabled = false;

  RenderStats get stats => _statsTracker.getStats();
  double clearAlpha = 1.0;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isGpu => true;
  bool get msaaActive => _msaaColorTextureView != null;
  int get dynamicSampleCount => msaaActive ? 4 : 1;

  @override
  double getTargetPixelRatio() => _currentRenderTarget == null ? _pixelRatio : 1.0;

  GpuRenderer(){
    _setXR = null;
  }

  RendererCapabilities _createDefaultCapabilities() {
    return RendererCapabilities(
      supportsCompute: true,
      supportsMultisampling: true,
    );
  }

  /// Maps hardware limits queried from the official GpuAdapter onto the capabilities model.
  RendererCapabilities _createCapabilities(gpux.GpuAdapter adapter) {
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
  Future<Result<void>> init(gpux.GpuFrame frame, RendererConfig config) async {
    renderLists = GpuRenderLists();
    this.frame = frame;
    this.config = config;

    xr = _setXR?.call(this,frame) ?? XRManager(this, frame);
    xr.init();
		xr.addEventListener( 'sessionstart', onXRSessionStart );
		xr.addEventListener( 'sessionend', onXRSessionEnd );

    // For Gpu, surface rendering canvas binding constraints are pre-configured
    return _initializeInternal();
  }

  /// Internal hardware driver setup loop using cross-platform async sequences.
  Future<Result<void>> _initializeInternal() async {
    try {
      console.info('T033: Starting Gpu renderer initialization...');
      final stopwatch = Stopwatch()..start();

      // 1. Instantiate the cross-platform hardware facade
      final gpu = gpux.Gpu();

      // 2. Request physical hardware adapter reference
      final requestedAdapter = await gpu.requestAdapter(
        gpux.GpuRequestAdapterOptions(
        powerPreference: gpux.GpuPowerPreference.highPerformance,
      ));
      _adapter = requestedAdapter;

      // Device loss recovery callback hooks integration
      _device.lost.then((info) {
        try {
          console.warning('T033: ⚠️ Gpu device lost: $info');
          _contextLossRecovery.handleContextLoss();
        } catch (e) {
          console.error('T033: Error handling device loss routine: $e');
        }
      });

      // Browser bug presentation layer fallback workarounds are handled implicitly 
      // by the multi-platform canvas context abstraction wrapper layer.
      console.info('T033: Configuring canvas context surface presentation pipeline...');
      console.info('T033: Rebuilding depth attachments buffers targets...');
      _ensureDepthTexture(frame.width, frame.height, sampleCount: dynamicSampleCount);

      console.info('T033: Allocating sub-system tracking memory buffer pools...');
      _bufferPool = BufferPool(_device);
      
      _uniformManager.onDeviceReady(_device);
      _materialTextureManager.onDeviceReady(_device);

      console.info('T033: Resolving adapter limits capabilities profiles...');
      _rendererCapabilities = _createCapabilities(_adapter!);
      console.info('T033: Capabilities detected: maxTextureSize=${_rendererCapabilities!.maxTextureSize}');

      // Execute internal backend architecture text module checks
      console.info('T033: Validating WGSL shader compilation pipelines components...');

      _isInitialized = true;
      console.info('T033: Gpu renderer completed setup in ${stopwatch.elapsedMilliseconds}ms');
      return const Result.success(null);
    } catch (e, stack) {
      console.error('T033: ❌ FATAL CRASH during renderer initialization: $e');
      console.error('T033: Trace: $stack');
      return Result.error('Renderer initialization failed: ${e.toString()}', e);
    }
  }
  
  /// Submits a raw, zero-dependency render pass clearing the canvas to red.
  /// Used to directly audit if back-buffer context presentation bindings are healthy.
  void clear([bool color = true, bool depth = true, bool stencil = true]) {
    try {
      final rawEncoder = _device.createCommandEncoder();

      // Build explicit structural attachment descriptor array map
      final rawPass = rawEncoder.beginRenderPass(
        colorAttachments: [
          gpux.GpuColorAttachment(
            view: frame.targetView,
            loadOp: gpux.GpuLoadOp.clear,
            clearValue: const gpux.GpuColor(1.0, 0.0, 0.0, 1.0), // Fully opaque pure Red
            storeOp: gpux.GpuStoreOp.store,
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
  void resize(double width, double height) {
    setSize(width, height, false);
  }

  @override
  Vector2 getSize(Vector2 target){
    return target.setValues(frame.width.toDouble(), frame.height.toDouble());
  }
  void setSize(double width, double height, [bool updateStyle = false]) {
    if ( xr.isPresenting ) {
      console.warning( 'WebGLRenderer: Can\'t change size while VR device is presenting.' );
      return;
    }
    frame.width = width.toInt();
    frame.height = height.toInt();
    
    if (_presentationCanvas != null) {
      _presentationCanvas!.width = width;
      _presentationCanvas!.height = height;
    }

    setViewport(0, 0, width, height);
  }
  dynamic getContext(){

  }
  double getPixelRatio(){
    return _pixelRatio;
  }

  double getClearAlpha(){
    return clearAlpha;
  }
  void setClearAlpha(double alpha){
    clearAlpha = alpha;
  }

  void setScissor(double x, double y, double width, double height){
    _scissor.setValues(x, y, width, height);
    _currentScissor.setFrom(_scissor);
    _currentScissor.scale(_pixelRatio);
    _currentScissor.floor();
  }

  void setScissorTest(bool test){

  }
  void setOpaqueSort(Function? method) {
    _opaqueSort = method;
  }

  void setTransparentSort(Function? method) {
    _transparentSort = method;
  }

  void setViewport(double x, double y, double width, double height){
    _viewport.setValues(x, y, width, height);
    _currentViewport.setFrom(_viewport);
    _currentViewport.scale(_pixelRatio);
    _currentViewport.floor();
  }
  Vector4 getViewport(Vector4 target){
    return target.setFrom(_viewport);
  }
  Vector4 getCurrentViewport(Vector4 target){
    return target.setFrom(_currentViewport);
  }

  @override
  void setOutputColorSpace(String colorSpace ) {
    super.setOutputColorSpace(colorSpace);
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

  bool materialNeedsLights(Material material) {
    return material is MeshLambertMaterial ||
        material is MeshToonMaterial ||
        material is MeshPhongMaterial ||
        material is MeshStandardMaterial ||
        material is ShadowMaterial ||
        (material is ShaderMaterial && material.lights == true);
  }

  @override
  int getActiveCubeFace() {
    return _currentActiveCubeFace;
  }

  @override
  int getActiveMipmapLevel() {
    return _currentActiveMipmapLevel;
  }

  RenderTarget? getRenderTarget(){
    return _currentRenderTarget;
  }

  void dispose() {
    _environmentManager.dispose();
    renderLists.dispose();
    currentRenderList?.dispose();
    for(final stack in renderListStack){
      stack.dispose();
    }
    renderListStack.clear();

    for (final pipeline in _pipelineCacheMap.values) {
      pipeline.dispose();
    }
    _pipelineCacheMap.clear();
    
    // Handled cleanly via standard null conditional statements
    _pipelineCache?.clear();
    _bufferPool?.dispose();
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
    clipping.dispose();
    clippingPlanes.clear();
    _statsTracker.reset();
  }

  void Function(double)? onAnimationFrameCallback;

  void onAnimationFrame(double time) {
    if (onAnimationFrameCallback != null) onAnimationFrameCallback!(time);
  }

  void onXRSessionStart(event) {
    animation.stop();
  }

  void onXRSessionEnd(event) {
    animation.start();
  }

  @override
  void render(Object3D scene, Camera camera) {
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
    
    //try {
      _triangleCount = 0;
      _drawCallCount = 0;
      _drawIndexInFrame = 0;
      
      if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
      if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
      //camera.updateProjectionMatrix();

      if ( xr.enabled && xr.isPresenting ) {
        if (xr.cameraAutoUpdate) xr.updateCamera( camera );
        if(kIsWeb) camera = xr.getCamera();
      }

      if (scene is Scene) {
        scene.onBeforeRender?.call(renderer: this, scene: scene, camera: camera, renderTarget: _currentRenderTarget);
      }

      currentRenderState = renderStates.get(scene, renderCallDepth: renderStateStack.length);
      currentRenderState!.init(camera);

      renderStateStack.add(currentRenderState!);

      _ensureDepthTexture(frame.width, frame.height, sampleCount: dynamicSampleCount);

      final textureView = frame.targetView;
      final msaaColorView = _msaaColorTextureView ?? textureView;
      final depthView = _depthTextureView;

      final commandEncoder = frame.device.createCommandEncoder(label: 'Main Command Encoder');
      _renderPassManager = GpuRenderPassManager(commandEncoder);

      late final FramebufferHandle framebufferHandle;
      if (depthView != null) {
        framebufferHandle = FramebufferHandle(
          GpuFramebufferAttachments(
            colorView: msaaColorView,
            depthView: depthView,
            resolveView: msaaActive ? textureView : null,
          )
        );
      } 
      else {
        framebufferHandle = FramebufferHandle(msaaColorView);
      }

      //ensureSceneGeometryHasUVs(scene); 

      projScreenMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);
      _frustum.setFromMatrix(projScreenMatrix);

      _localClippingEnabled = localClippingEnabled;
      _clippingEnabled = clipping.init(clippingPlanes, _localClippingEnabled);

      currentRenderList = renderLists.get(scene, renderListStack.length);
      currentRenderList!.init();

      renderListStack.add(currentRenderList!);

      if ( xr.enabled && xr.isPresenting) {
        final depthSensingMesh = xr.getDepthSensingMesh();
        if ( depthSensingMesh != null ) {
          projectObject( depthSensingMesh, camera, - double.maxFinite.toInt(), this.sortObjects );
        }
      }

      projectObject(scene, camera, 0, sortObjects);

      currentRenderList!.finish();

      if (sortObjects) {
        currentRenderList!.sort(_opaqueSort, _transparentSort);
      }

      final Color clearColorFeature020 = Color(
        scene.background is Color? scene.background.red: actualClearColor.red,
        scene.background is Color? scene.background.green: actualClearColor.green,
        scene.background is Color? scene.background.blue: actualClearColor.blue,
        clearAlpha
      );
      
      _renderPassManager!.beginRenderPass(clearColor: clearColorFeature020, framebuffer: framebufferHandle);
      final renderPass = _renderPassManager!.getPassEncoder()!;

      final sceneBrdf = (scene.background is Color || scene.background == null)?null:scene.background;
      final environmentBinding = _environmentManager.prepare(
        scene.environment,
        sceneBrdf
      );

      if (_clippingEnabled) clipping.beginShadows();
      final shadowsArray = currentRenderState!.state.shadowsArray;
      //shadowMap.render(shadowsArray, scene, camera);
      if (_clippingEnabled) clipping.endShadows();


      final lights = currentRenderList?.lights;
      final opaqueObjects = currentRenderList?.opaque ?? [];
		  final transmissiveObjects = currentRenderList?.transmissive ?? [];
      final transparentObjects = currentRenderList?.transparent ?? [];

      if (diag) {
        console.info('RENDER[$_frameCount]: Sorting complete. Lights: ${lights?.length}, Opaque: ${opaqueObjects.length}, Transparent: ${transmissiveObjects.length}');
      }

      // 1. COLLECT LIGHTS AND GENERATE UNIFORMS
      final sceneData = SceneUniformData.updateUniforms(
        camera: camera,
        scene: scene as Scene,
        activeLights: lights
      );

      // =========================================================================
      // 💡 ARRAY CAMERA CORE ROUTING DETERMINATION
      // =========================================================================
      // Check if the camera is an ArrayCamera containing sub-cameras
      final List<Camera> subCameras = (camera is ArrayCamera) ? (camera as ArrayCamera).cameras : [camera];

      for (final subCamera in subCameras) {
        // Look up viewport dimensions configured on the Dart side for this sub-camera
        // Three.js sets a camera.viewport property containing (x, y, width, height) relative bounds multipliers [0.0 to 1.0]
        final Vector4 vp = subCamera.viewport ?? Vector4(0, 0, 1, 1);
          
        double vpX = vp.x;
        double vpY = vp.y;
        double vpW = vp.z;
        double vpH = vp.w;

        // 1. Detect if the values are normalized percentage scales [0.0 - 1.0]
        if (vp.z <= 1.0) {
          vpX = vp.x * frame.width;
          vpY = vp.y * frame.height;
          vpW = vp.z * frame.width;
          vpH = vp.w * frame.height;
        }

        // 2. 💡 THE CRITICAL FIX: Flip the Y coordinate from Three.js Bottom-Left over to WebGPU Top-Left!
        // Equation: WebGpuY = FrameHeight - SubCameraY - SubCameraHeight
        double webGpuY = frame.height - vpY - vpH;

        // 3. HARDWARE BOUNDS CLAMP: Keep every single pixel safely within the render target texture boundaries
        // Ensure the width and height don't exceed absolute limits
        vpW = vpW.clamp(1.0, frame.width.toDouble());
        vpH = vpH.clamp(1.0, frame.height.toDouble());
        
        // Ensure the origin points leave enough room so (origin + width/height) never overruns the frame bounds
        vpX = vpX.clamp(0.0, frame.width.toDouble() - vpW);
        webGpuY = webGpuY.clamp(0.0, frame.height.toDouble() - vpH);

        // 4. Submit the perfectly contained dimensions safely to the GPU
        renderPass.setViewport(vpX, webGpuY, vpW, vpH, minDepth: 0.0, maxDepth:  1.0);
        renderPass.setScissorRect(vpX.toInt(), webGpuY.toInt(), vpW.toInt(), vpH.toInt());
        // =====

        // Update matrices specifically for this sub-view camera perspective position
        subCamera.updateMatrixWorld();
        
        // Compute specialized scene uniform blocks for THIS perspective frame view path
        final sceneData = SceneUniformData.updateUniforms(
          camera: subCamera,
          scene: scene,
          activeLights: lights
        );

        // Back-to-Front depth sorting calculation relative to THIS sub-camera position
        // final cameraWorldPos = subCamera.position;
        // transparentMeshes.sort((a, b) {
        //   final aWorldPos = Vector3().setFromMatrixPosition(a.matrixWorld);
        //   final bWorldPos = Vector3().setFromMatrixPosition(b.matrixWorld);
        //   return cameraWorldPos.distanceToSquared(bWorldPos).compareTo(cameraWorldPos.distanceToSquared(aWorldPos));
        // });

        for (final o in opaqueObjects) {
          _renderMesh(o.object, subCamera, sceneData, renderPass, environmentBinding);
        }
        for (final o in transmissiveObjects) {
          _renderMesh(o.object, subCamera, sceneData, renderPass, environmentBinding);
        }
        for (final o in transparentObjects) {
          _renderMesh(o.object, subCamera, sceneData, renderPass, environmentBinding);
        }
      }
      // =========================================================================
      
      renderPass.end();
      final commandBuffer = commandEncoder.finish();
      frame.device.queue.submit([commandBuffer]);
      _frameCount++;
      
    // } catch (e, stack) {
    //   console.error('T033: ❌ ERROR during execution frame loop lifecycle trace cycle: $e');
    //   console.error(stack);
    // }

    renderListStack.removeLast();

    if (renderListStack.isNotEmpty) {
      currentRenderList = renderListStack[renderListStack.length - 1];
    } 
    else {
      currentRenderList = null;
    }
  }

  void projectObject(Object3D object, Camera camera, int groupOrder, bool sortObjects) {
    if (!object.visible) return;
    final visible = object.layers.test(camera.layers);
    if (visible) {
      if (object is Group) {
        groupOrder = object.renderOrder;
      } 
      else if (object is LOD) {
        dynamic u = object;
        if (object.autoUpdate == true) u.update(camera);
      } 
      else if (object is Light) {
        currentRenderList!.pushLight(object);

        if (object.castShadow) {
          currentRenderList!.pushShadow(object);
        }
      } 
      else if (object is Sprite) {
        if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
          if (sortObjects) {
            _vector4.setFromMatrixPosition(object.matrixWorld).applyMatrix4(projScreenMatrix);
          }

          //BufferGeometry geometry = objects.update(object);
          final material = object.material;

          if (material != null && material.visible) {
            currentRenderList!.push(object, null, material, groupOrder, _vector4.z, null);
          }
        }
      }
      else if (object is Mesh || object is Line || object is Points) {
        // if (object is SkinnedMesh) {
        //   // update skeleton only once in a frame
        //   if (object.skeleton!.frame != info.render["frame"]) {
        //     object.skeleton!.update();
        //     object.skeleton!.frame = info.render["frame"]!;
        //   }
        // }

        // print("object: ${object.type} ${!object.frustumCulled} ${_frustum.intersectsObject(object)} ");

        if ( !object.frustumCulled || _frustum.intersectsObject(object)) {
          final geometry = object.geometry;//objects.update(object);
          final material = object.material;

          if (sortObjects) {
            if (object.boundingSphere != null ) {
              if (object.boundingSphere == null ) object.computeBoundingSphere();
              _vector4.setFrom(object.boundingSphere!.center );
            } 
            else {
              if ( geometry?.boundingSphere == null ) geometry?.computeBoundingSphere();
              _vector4.setFrom( geometry!.boundingSphere!.center );
            }
            _vector4..applyMatrix4(object.matrixWorld)..applyMatrix4(projScreenMatrix);
          }

          if (material is GroupMaterial) {
            final groups = geometry?.groups;

            if (groups != null && groups.isNotEmpty) {
              for (int i = 0, l = groups.length; i < l; i++) {
                Map<String, dynamic> group = groups[i];
                final groupMaterial = material.children[group["materialIndex"]];

                if (groupMaterial.visible) {
                  currentRenderList!.push(object, geometry, groupMaterial, groupOrder, _vector4.z, group);
                }
              }
            } 
            else {
              if (material.visible && material.children.isNotEmpty) {
                currentRenderList!.push(object, geometry, material.children[0], groupOrder, _vector4.z, null);
              }
            }
          } 
          else if (material != null && material.visible) {
            currentRenderList!.push(object, geometry, material, groupOrder, _vector4.z, null);
          }
        }
      }
    }

    final children = object.children;

    for (int i = 0, l = children.length; i < l; i++) {
      projectObject(children[i], camera, groupOrder, sortObjects);
    }
  }

  void _renderMesh(
    Object3D? mesh,
    Camera camera,
    Float32List sceneData,
    gpux.GpuRenderPassEncoder renderPass,
    EnvironmentBinding? environmentBinding,
  ) {
    if(mesh == null) return; 
    final int maxMeshesPerFrame = UniformBufferManager.maxMeshesPerFrame;
    if (_drawIndexInFrame >= maxMeshesPerFrame) return;

    // 1. Force absolute parent-child matrix updates
    mesh.updateMatrixWorld();
    if (camera.matrixWorldInverse.storage[0] == 0.0 && camera.matrixWorldInverse.storage[5] == 0.0) {
      camera.matrixWorldInverse.setFrom(camera.matrixWorld).invert();
    }

    final geometry = mesh.geometry;
    if (geometry == null) return;

    final material = mesh.material;
    if (material == null) return;

    final resolvedDescriptor = MaterialDescriptorRegistry.resolve(material, mesh);
    if (resolvedDescriptor == null) return;
    final descriptor = resolvedDescriptor.descriptor;

    late final MaterialUniformData materialUniforms = MaterialConverter.convert(material, camera, environmentBinding?.mipCount);

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

    if (!_uniformManager.updateUniforms(
      drawIndex: _drawIndexInFrame,
      materialData: materialUniforms.updateUniforms(mesh: mesh),
      sceneData: sceneData,
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
    gpux.GpuRenderPassEncoder renderPass,
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
        
        // Bind exactly once to stop Gpu slot mutation crashes!
        renderPass.setBindGroup(primaryEnvGroupSlot, rawGroup);
      }
    }
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

    // FIX: Explicitly assign an index offset of 3 for BOTH standard and phong lit materials
    // basic: color@0 -> next = 1
    // phong: color@0, worldPosition@1, worldNormal@2 -> next = 3
    // meshStandard: worldNormal@0, viewDir@1, albedo@2 -> next = 3
    int varyingLocation = 
    materialKey == 'material.pbr'?7:
    (
      
      materialKey == 'material.shadow' || 
      materialKey == 'material.matcap'
    )?4:(
      materialKey == 'material.phong' ||
      materialKey == 'material.toon'  || 
      materialKey == 'material.lineDashed'
    ) ? 3 : 
    (
      materialKey == 'material.distance' ||
      materialKey == 'material.basic'
    ) ? 2 : 1;

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
      
      if (materialKey == 'material.pbr') {
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

    if (material is MeshStandardMaterial) {
      if (material.map != null && hasUv) {
        final textureBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
        final samplerBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
        if (textureBinding != null && samplerBinding != null) {
          fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialAlbedoTexture: texture_2d<f32>;');
          fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialAlbedoSampler: sampler;');
          fragmentInitExtra.writeln('  let albedoSample = textureSample(materialAlbedoTexture, materialAlbedoSampler, input.uv);');
          fragmentInitExtra.writeln('  baseColor = clamp(baseColor * albedoSample.rgb, vec3<f32>(0.0), vec3<f32>(1.0));');
          
          if (material.transparent == true) {
            fragmentInitExtra.writeln('  alphaOverride = uniforms.baseColor.a * albedoSample.a;');
          }
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
            fragmentInitExtra.writeln('  let baseNormal = N; // MeshStandard uses N globally');
            fragmentInitExtra.writeln('  let tangent = normalize(input.tangent.xyz);');
            fragmentInitExtra.writeln('  let bitangent = normalize(cross(baseNormal, tangent)) * input.tangent.w;');
            fragmentInitExtra.writeln('  let tbn = mat3x3<f32>(tangent, bitangent, baseNormal);');
            fragmentInitExtra.writeln('  N = normalize(tbn * mappedNormal);');
            
            if (material.transparent == true) {
              fragmentInitExtra.writeln('  alphaOverride = uniforms.baseColor.a * albedoSample.a;');
            }
            usesNormalMap = true;
          }
        } else {
          print('Warning: Normal map assigned to ${material.name} but geometry lacks tangents; falling back to vertex normals.');
        }
      }
    } 
    else {
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
          
          if (material?.transparent == true) {
            fragmentInitExtra.writeln('  alphaOverride = uniforms.baseColor.a * albedoSample.a;');
          }
          usesVolumeMap = true;
        }
      } 
      else if (texture != null) {
        final textureBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.texture2d);
        final samplerBinding = findBinding(MaterialBindingSource.albedoMap, MaterialBindingType.sampler);
        if (textureBinding != null && samplerBinding != null) {
          fragmentBindings.writeln('  @group(${textureBinding.group}) @binding(${textureBinding.binding}) var materialAlbedoTexture: texture_2d<f32>;');
          fragmentBindings.writeln('  @group(${samplerBinding.group}) @binding(${samplerBinding.binding}) var materialAlbedoSampler: sampler;');
          fragmentInitExtra.writeln('  var correctedUv = input.uv;');
          fragmentInitExtra.writeln('  correctedUv.x = 1.0 + correctedUv.x;');
          fragmentInitExtra.writeln('  correctedUv.y = 1.0 + correctedUv.y;');
          fragmentInitExtra.writeln('  let albedoSample = textureSampleLevel(materialAlbedoTexture, materialAlbedoSampler, correctedUv, 0.0);');          
          fragmentInitExtra.writeln('  color = clamp(color * albedoSample.rgb, vec3<f32>(0.0), vec3<f32>(1.0));');
          
          // 4. FIX: Overwrite alphaOverride with your true combined transparency scale math!
          if (material?.transparent == true) {
            fragmentInitExtra.writeln('  alphaOverride = uniforms.baseColor.a * albedoSample.a;');
          }
          
          usesAlbedoMap = true;
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
  
  gpux.GpuRenderPipeline? _getOrCreatePipeline(
    ResolvedMaterialDescriptor resolved,
    MaterialShaderDescriptor shaderDescriptor,
    EnvironmentBinding? environmentBinding,
    MaterialTextureBinding? materialBinding,
    List<gpux.GpuVertexBufferLayout> vertexLayouts,
  ) {
    final gpuDevice = _device;
    final shaderSource = MaterialShaderGenerator.compile(shaderDescriptor);
    final renderState = resolved.renderState;

    final DepthStencilStateDescriptor? depthState = renderState.depthTest ? DepthStencilStateDescriptor(
      format: renderState.depthFormat,
      depthWriteEnabled: true,//renderState.depthWrite,
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
        mask: gpux.GpuColorWrite.all, 
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
      final pipeline = GpuPipeline(gpuDevice, pipelineDescriptor);
      _pipelineCacheMap[cacheKey] = pipeline;

      try {
        final layoutByGroup = <int, gpux.GpuBindGroupLayout>{};

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

  void _ensureMsaaColorTexture(int width, int height, gpux.GpuTextureFormat format) {
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
        usage: gpux.GpuTextureUsage.renderAttachment | gpux.GpuTextureUsage.textureBinding, 
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
        format: gpux.GpuTextureFormat.depth24Plus,
        usage: gpux.GpuTextureUsage.renderAttachment,
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

  late final gpux.GpuTexture whitePlaceholderTexture;
  late final gpux.GpuTexture bluePlaceholderTexture;
  late final gpux.GpuSampler defaultSampler;
  
  void initPlaceholders(gpux.GpuDevice device) {
    // 1. Create a 1x1 solid white texture view for Albedo/Roughness maps
    whitePlaceholderTexture = device.createTexture(
      label: 'material.white_placeholder',
      width: 1, height: 1, depthOrArrayLayers: 1,
      format: gpux.GpuTextureFormat.rgba8Unorm,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
    );
    device.queue.writeTexture(
      texture: whitePlaceholderTexture, 
      data: Uint8List.fromList([255, 255, 255, 255]), // White pixel
      bytesPerRow: 256,
      width: 1,
      rowsPerImage: 1
    );

    // 2. Create a 1x1 flat blue texture view for Normal map fallbacks vector [0, 0, 1]
    bluePlaceholderTexture = device.createTexture(
      label: 'material.blue_placeholder',
      width: 1, height: 1, depthOrArrayLayers: 1,
      format: gpux.GpuTextureFormat.rgba8Unorm,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.copyDst,
    );
    device.queue.writeTexture(
      texture: bluePlaceholderTexture, 
      data: Uint8List.fromList([128, 128, 255, 255]), // Neutral normal vector
      bytesPerRow: 256,
      width: 1,
      rowsPerImage: 1
    );

    defaultSampler = device.createSampler(
      addressModeU: gpux.GpuAddressMode.clampToEdge,
      addressModeV: gpux.GpuAddressMode.clampToEdge,
      addressModeW: gpux.GpuAddressMode.clampToEdge,
      magFilter: gpux.GpuFilterMode.nearest,
      minFilter: gpux.GpuFilterMode.nearest,
      mipmapFilter: gpux.GpuMipmapFilterMode.nearest,
      label: 'material.placeholder_sampler',
    );
  }

  void ensureSceneGeometryHasUVs(Object3D rootObject) {
    rootObject.traverse((obj) {
      if (obj is Mesh) {
        final geometry = obj.geometry;
        if (geometry == null) return;

        // Check if UV coordinates are already loaded and filled; if so, skip calculation
        if (geometry.attributes['uv'] != null) return;

        final positionAttribute = geometry.attributes['position'];
        if (positionAttribute == null) return;

        final int vertexCount = positionAttribute.count;
        final Float32List uvs = Float32List(vertexCount * 2);

        int uvIdx = 0;
        for (int i = 0; i < vertexCount; i++) {
          // Extract raw 3D positions for this specific vertex
          final double x = positionAttribute.getX(i)?.toDouble() ?? 0.0;
          final double y = positionAttribute.getY(i)?.toDouble() ?? 0.0;
          final double z = positionAttribute.getZ(i)?.toDouble() ?? 0.0;

          // Normalize the vector relative to a bounding sphere footprint
          final double radius = math.sqrt(x * x + y * y + z * z);
          if (radius == 0.0) {
            uvs[uvIdx++] = 0.0;
            uvs[uvIdx++] = 0.0;
            continue;
          }

          final double nx = x / radius;
          final double ny = y / radius;
          final double nz = z / radius;

          // Reconstruct Spherical Projection Coordinates (Equirectangular)
          final double u = 0.5 + (math.atan2(nz, nx) / (2 * math.pi));
          final double v = 0.5 - (math.asin(ny) / math.pi);

          uvs[uvIdx++] = u;
          uvs[uvIdx++] = v;
        }

        // Inject the calculated coordinate arrays directly into your BufferGeometry
        geometry.setAttributeFromString('uv', Float32BufferAttribute(uvs, 2));
      }
    });
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