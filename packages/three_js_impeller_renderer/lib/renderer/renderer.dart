import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/frame_attachments.dart';
import 'package:three_js_impeller_renderer/renderer/geometry/geometry_descriptor.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_converter.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';
import 'package:three_js_impeller_renderer/renderer/pipeline.dart';
import 'package:three_js_impeller_renderer/renderer/render_pass_manager.dart';
import 'package:three_js_impeller_renderer/renderer/render_target.dart';
import 'package:three_js_impeller_renderer/renderer/shaders.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_animation.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_clipping.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_properties.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_render_list.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_render_lists.dart';
import 'package:three_js_impeller_renderer/renderer/three_js_rendering/gpu_render_states.dart';
import 'package:three_js_impeller_renderer/renderer/uniform_buffer_manager.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

class ImpellerRendererParameters{
  double width;
  double height;
  bool stencil;
  //bool antialias;
  bool alpha;
  int clearColor;
  int sampleCount;
  double clearAlpha;
  bool logarithmicDepthBuffer;
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  PowerPreference powerPreference;
  bool reverseDepthBuffer;
  bool failIfMajorPerformanceCaveat;
  bool depth = true;
  Precision precision;
  XRManager Function(ImpellerRenderer renderer, dynamic gl)? xr;

  ImpellerRendererParameters({
    required this.width,
    required this.height,
    required this.sampleCount,
    this.stencil = true,
    //this.antialias = false,
    this.alpha = false,
    this.clearAlpha = 1.0,
    this.clearColor = 0x000000,
    this.logarithmicDepthBuffer = false,
    this.depth = true,
    this.premultipliedAlpha = true,
    this.preserveDrawingBuffer = false,
    this.powerPreference = PowerPreference.defaultp,
    this.failIfMajorPerformanceCaveat = false,
    this.reverseDepthBuffer = false,
    this.precision = Precision.highp,
    this.xr,
  });

  factory ImpellerRendererParameters.fromMap(Map<String,dynamic> map){
    return ImpellerRendererParameters(
      width: map["width"].toDouble(),
      height: map["height"].toDouble(),
      depth: map["depth"] ?? true,
      stencil: map["stencil"] ?? true,
      sampleCount: map["sampleCount"] ?? 1,
      //antialias: map["antialias"] ?? false,
      premultipliedAlpha: map["premultipliedAlpha"] ?? true,
      preserveDrawingBuffer: map["preserveDrawingBuffer"] ?? false,
      powerPreference: map["powerPreference"] ?? "default",
      failIfMajorPerformanceCaveat: map["failIfMajorPerformanceCaveat"] ?? false,
      alpha: map["alpha"] ?? false,
      xr: map["xr"],
      precision: map['precision'],
      reverseDepthBuffer: map['reverseDepthBuffer']
    );
  }
}

class ImpellerRenderer extends Renderer{
  ImpellerRendererParameters parameters;
  
  static const int _maxMorphTargets = 8;
  static const int _diagFrames = 3;

  late XRManager Function(ImpellerRenderer renderer, dynamic frame)? _setXR;

  late double _width;
  late double _height;
  int _sampleCount = 1;

  double get width => _width;
  double get height => _height;

  // Depth-stencil target GPU attachments resources references
  gpu.Texture? _depthTexture;
  gpu.Texture? _msaaColorTexture;
  Color actualClearColor = Color(0.0, 0.0, 0.0, 1.0);

  List<Plane> clippingPlanes = [];

  // Viewport mapping configurations variables
  late Vector4 _viewport = Vector4(0, 0, width.toDouble(), height.toDouble());
  late Vector4 _scissor = Vector4(0, 0, width.toDouble(), height.toDouble());
  
  final _currentViewport = Vector4.identity();
  final _currentScissor = Vector4.identity();

  /// T033: Debug flag for verbose frame logging
  bool enableFrameLogging = false;
  GpuRenderPassManager? _renderPassManager;

  final GpuAnimation animation = GpuAnimation();
  final GpuProperties properties = GpuProperties();
  late final GpuClipping clipping = GpuClipping(properties);
  GpuRenderState? currentRenderState;
  final GpuRenderStates renderStates = GpuRenderStates();

  GpuRenderList? currentRenderList;
  late GpuRenderLists renderLists;
  List<GpuRenderList> renderListStack = [];
  List<GpuRenderState> renderStateStack = [];

  Function? _opaqueSort;
  Function? _transparentSort;
  double _pixelRatio = 1;

  int _currentActiveCubeFace = 0;
  int _currentActiveMipmapLevel = 0;
  ImpellerRenderTarget? _currentRenderTarget;

  late gpu.Texture depthTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient, width.toInt(), height.toInt(),
    sampleCount: _sampleCount,
    format: gpu.gpuContext.defaultDepthStencilFormat,
    enableRenderTargetUsage: true,
    coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture
  );

  late gpu.Texture msaaColorTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.deviceTransient, width.toInt(), height.toInt(),
    sampleCount: _sampleCount, // MUST match your pipeline sample count!
  );

  late gpu.Texture renderTexture = gpu.gpuContext.createTexture(
    gpu.StorageMode.devicePrivate, width.toInt(), height.toInt(),
    sampleCount: 1,
    enableRenderTargetUsage: true,
    enableShaderReadUsage: true,
    coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture
  );

  ui.Image? image;
  
  final _vector4 = Vector4();
  final _frustum = Frustum();
  final projScreenMatrix = Matrix4.identity();

  bool _clippingEnabled = false;
  bool _localClippingEnabled = false;
  bool localClippingEnabled = false;

  double clearAlpha = 1.0;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isGpu => true;
  bool get msaaActive => _msaaColorTexture != null;
  int get dynamicSampleCount => msaaActive ? 4 : 1;

  // Rendering lifecycle state variables
  int _frameCount = 0;
  int _triangleCount = 0;
  int _drawCallCount = 0;
  int _drawIndexInFrame = 0;

  //late final GeometryBufferCache _geometryCache = GeometryBufferCache(deviceProvider: () => _device, statsTracker: _statsTracker);
  //late final UniformBufferManager _uniformManager = UniformBufferManager(deviceProvider: () => _device, statsTracker: _statsTracker);

  ImpellerRenderer(this.parameters){
    _width = this.parameters.width;
    _height = this.parameters.height;
    _sampleCount = this.parameters.sampleCount;

    renderLists = GpuRenderLists();

    _setXR = null;

    xr = _setXR?.call(this,null) ?? XRManager(this, null);
    xr.init();
		xr.addEventListener( 'sessionstart', onXRSessionStart );
		xr.addEventListener( 'sessionend', onXRSessionEnd );
  }

  void _setTextures(int width, int height){
    depthTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient, width, height,
      sampleCount: _sampleCount,
      format: gpu.gpuContext.defaultDepthStencilFormat,
      enableRenderTargetUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture
    );

    msaaColorTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient, width.toInt(), height.toInt(),
      sampleCount: _sampleCount, // MUST match your pipeline sample count!
    );

    renderTexture= gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate, width, height,
      enableRenderTargetUsage: true,
      enableShaderReadUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture
    );
  }

  void onXRSessionStart(event) {
    animation.stop();
  }

  void onXRSessionEnd(event) {
    animation.start();
  }

  @override
  double getTargetPixelRatio() => _currentRenderTarget == null ? _pixelRatio : 1.0;
  Vector2 getSize(Vector2 target){
    return target.setValues(width.toDouble(), height.toDouble());
  }
  void setSize(double width, double height, [bool updateStyle = false]) {
    if ( xr.isPresenting ) {
      console.warning( 'WebGLRenderer: Can\'t change size while VR device is presenting.' );
      return;
    }

    _width = width;
    _height = height;
    _setTextures(width.toInt(), height.toInt());
    setViewport(0, 0, width, height);
  }
  @override
  dynamic getContext(){

  }
  @override
  double getPixelRatio(){
    return _pixelRatio;
  }
  @override
  double getClearAlpha(){
    return 1.0;
  }
  @override
  void setClearAlpha(double alpha){

  }
  void setScissor(double x, double y, double width, double height){
    _scissor.setValues(x, y, width, height);
    _currentScissor.setFrom(_scissor);
    _currentScissor.scale(_pixelRatio);
    _currentScissor.floor();
  }
  void setScissorTest(bool test){

  }
  @override
  void setViewport(double x, double y, double width, double height){

  }
  @override
  Vector4 getViewport(Vector4 target){
    return target.setFrom(_viewport);
  }
  @override
  Vector4 getCurrentViewport(Vector4 target){
    return target.setFrom(_currentViewport);
  }
  @override
  void dispose(){
    
  }
  @override
  void clear([bool color = true, bool depth = true, bool stencil = true]){

  }
  @override
  void setClearColor(Color color, [double alpha = 1.0]){

  }
  @override
  Color getClearColor(Color target) {
    target.setFrom(Color());//background.getClearColor());
    return target;
  }

  @override
  void render(Object3D scene, Camera camera){
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
    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    _renderPassManager ??= GpuRenderPassManager();

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
    _renderPassManager!.beginRenderPass(
      commandBuffer,
      clearColorFeature020,
      GpuFramebufferAttachments(
        colorView: _sampleCount>1?msaaColorTexture:renderTexture,
        depthView: depthTexture,
        resolveView: _sampleCount>1?renderTexture:null
      )
    );
    final renderPass = _renderPassManager!.getPassEncoder;
  
    final sceneBrdf = (scene.background is Color || scene.background == null)?null:scene.background;
    final environmentBinding = null;
    // _environmentManager.prepare(
    //   scene.environment,
    //   sceneBrdf
    // );

    if (_clippingEnabled) clipping.beginShadows();
    final shadowsArray = currentRenderState!.state.shadowsArray;
    //shadowMap.render(shadowsArray, scene, camera);
    if (_clippingEnabled) clipping.endShadows();


    final lights = currentRenderList?.lights;
    final opaqueObjects = currentRenderList?.opaque ?? [];
    final transmissiveObjects = currentRenderList?.transmissive ?? [];
    final transparentObjects = currentRenderList?.transparent ?? [];

    console.info('RENDER: Sorting complete. Lights: ${lights?.length}, Opaque: ${opaqueObjects.length}, Transparent: ${transmissiveObjects.length}');

    // 1. COLLECT LIGHTS AND GENERATE UNIFORMS
    final sceneData = SceneUniformData.updateUniforms(
      camera: camera,
      scene: scene as Scene,
      activeLights: lights
    );

    if(camera is ArrayCamera){
      final List<Camera> subCameras = camera.cameras;
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
          vpX = vp.x * width;
          vpY = vp.y * height;
          vpW = vp.z * width;
          vpH = vp.w * height;
        }

        // 2. 💡 THE CRITICAL FIX: Flip the Y coordinate from Three.js Bottom-Left over to WebGPU Top-Left!
        // Equation: WebGpuY = FrameHeight - SubCameraY - SubCameraHeight
        double webGpuY = height - vpY - vpH;

        // 3. HARDWARE BOUNDS CLAMP: Keep every single pixel safely within the render target texture boundaries
        // Ensure the width and height don't exceed absolute limits
        vpW = vpW.clamp(1.0, width);
        vpH = vpH.clamp(1.0, height);
        vpX = vpX.clamp(0.0, width - vpW);
        webGpuY = webGpuY.clamp(0.0, height - vpH);

        // 4. Submit the perfectly contained dimensions safely to the GPU
        renderPass.setViewport(gpu.Viewport(x: vpX.toInt(), y: webGpuY.toInt(), width: vpW.toInt(), height:vpH.toInt(), depthRange: gpu.DepthRange(zNear: 0.0, zFar: 1.0)));
        renderPass.setScissor(gpu.Scissor(x:vpX.toInt(), y:webGpuY.toInt(), width:vpW.toInt(), height:vpH.toInt()));
        // =====

        // Update matrices specifically for this sub-view camera perspective position
        subCamera.updateMatrixWorld(true);

        for (final o in opaqueObjects) {
          _renderMesh(o, subCamera, sceneData, renderPass, environmentBinding);
        }
        for (final o in transmissiveObjects) {
          _renderMesh(o, subCamera, sceneData, renderPass, environmentBinding);
        }
        for (final o in transparentObjects) {
          _renderMesh(o, subCamera, sceneData, renderPass, environmentBinding);
        }
      }
    }
    else{
      for (final o in opaqueObjects) {
        _renderMesh(o, camera, sceneData, renderPass, environmentBinding);
      }
      for (final o in transmissiveObjects) {
        _renderMesh(o, camera, sceneData, renderPass, environmentBinding);
      }
      for (final o in transparentObjects) {
        _renderMesh(o, camera, sceneData, renderPass, environmentBinding);
      }
    }
    commandBuffer.submit();
    
    renderListStack.removeLast();

    if (renderListStack.isNotEmpty) {
      currentRenderList = renderListStack[renderListStack.length - 1];
    } 
    else {
      currentRenderList = null;
    }

    image = renderTexture.asImage();
    _drawIndexInFrame = 0;
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
          object.updateMatrix();
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
    RenderItem? item,
    Camera camera,
    Float32List sceneData,
    gpu.RenderPass pass,
    dynamic environmentBinding,
  ) {
    if (item == null) return;

    // 1. Frame-bound layout and allocation guards
    final int maxMeshesPerFrame = 200;
    if (_drawIndexInFrame >= maxMeshesPerFrame) return;

    // Force absolute parent-child matrix updates
    if (camera.matrixWorldInverse.storage[0] == 0.0 && camera.matrixWorldInverse.storage[5] == 0.0) {
      camera.matrixWorldInverse.setFrom(camera.matrixWorld).invert();
    }
    
    final object = item.object!;
    final geometry = item.geometry;
    if (geometry == null) return;
    final material = item.material;
    if (material == null) return;
    
    final resolved = MaterialDescriptorRegistry.resolve(material, object)!;
    final renderState = resolved.renderState;
    final String pipelineHash = '${resolved.vertex.hashCode}_${resolved.fragment.hashCode}_${renderState.uuid}';
    if(_cachedPipeline[pipelineHash] == null || resolved.renderState != _cachedPipeline[pipelineHash]?.descriptor.renderState){
      _cachedPipeline[pipelineHash] = GpuPipeline(
        gpu.gpuContext, 
        RenderPipelineDescriptor(
          vertexShader: resolved.vertex, 
          fragmentShader: resolved.fragment, 
          //vertexLayouts: vertexLayouts, 
          renderState: renderState,
        )
      );
    }

    pass.clearBindings(); 
    _cachedPipeline[pipelineHash]!.bind(pass);

    MaterialDescriptor mdescriptor = resolved.descriptor;
    final Float32List materialData = MaterialConverter.convert(material, camera).updateUniforms(object);
    final String geomHash = '${geometry.uuid}_${material.uuid}';
    if(_cachedGeometry[geomHash] == null || mdescriptor != _cachedPipeline[geomHash]?.descriptor){
      _cachedGeometry[geomHash] = GeometryBindings(
        gpu.gpuContext, 
        object,
        geometry,
        material,
        mdescriptor
      );
    }

    _cachedGeometry[geomHash]!.bind(
      pass,
      resolved.vertex,
      resolved.fragment,
      sceneData,
      materialData,
    );

    pass.draw();

    _drawCallCount++;
    _drawIndexInFrame++;
  }

  Map<String,GpuPipeline> _cachedPipeline = {};
  Map<String,GeometryBindings> _cachedGeometry = {};

  @override
  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]){

  }
  @override
  void readRenderTargetPixels(RenderTarget renderTarget, int x, int y, int width, int height, TypedData buffer, [int? activeCubeFaceIndex]){

  }
  @override
  void copyFramebufferToTexture(Vector? position, Texture? texture, {int level = 0}){

  }
  @override
  void renderBufferDirect(Camera camera,Object3D? scene,BufferGeometry geometry, Material material,Object3D object,Map<String, dynamic>? group){

  }
  @override
  ImpellerRenderTarget? getRenderTarget(){
    return _currentRenderTarget;
  }
}


