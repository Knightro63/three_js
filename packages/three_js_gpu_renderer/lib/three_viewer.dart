import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../renderer/renderer_config.dart';
import '../renderer/gpu/renderer.dart';
import 'package:three_js_core/renderers/index.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter_gpux/flutter_gpux.dart' as gpux;

class Settings{
  Settings({
    this.useSourceTexture = false,
    this.enableShadowMap = true,
    this.autoClear = true,
    Map<String,dynamic>? renderOptions,
    this.animate = true,
    this.alpha = false,
    this.autoClearDepth = true,
    this.autoClearStencil = true,
    this.clearAlpha = 1.0,
    this.clearColor = 0x000000,
    this.localClippingEnabled = false,
    this.clippingPlanes = const [],
    this.colorSpace = ColorSpace.srgb,
    this.outputEncoding = sRGBEncoding,
    this.toneMapping = NoToneMapping,
    this.shadowMapType = PCFShadowMap,
    this.toneMappingExposure = 1.0,
    this.logarithmicDepthBuffer = false,
    this.stencil = true,
    this.xr,
    this.antialias = false,

    this.depth = true,
    this.premultipliedAlpha = true,
    this.preserveDrawingBuffer = false,
    this.powerPreference = core.PowerPreference.defaultp,
    this.failIfMajorPerformanceCaveat = false,
    this.reverseDepthBuffer = false,
    this.precision = core.Precision.highp,
    this.screenResolution,
    this.useSurfaceProducer = true
  }){
    this.renderOptions = renderOptions ?? {
      "format": RGBAFormat,
      "samples": 4
    };
  }
  
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  core.PowerPreference powerPreference;
  bool reverseDepthBuffer;
  bool failIfMajorPerformanceCaveat;
  bool depth = true;
  bool useSurfaceProducer;
  Precision precision;
  bool alpha;
  bool stencil;
  bool logarithmicDepthBuffer;
  int clearColor;
  double clearAlpha;
  bool antialias;
  XRManager Function(GpuRenderer renderer, dynamic gl)? xr;
  double? screenResolution;
  
  bool animate;
  bool useSourceTexture;
  bool enableShadowMap;
  bool autoClear;
  bool autoClearDepth;
  bool autoClearStencil;
  bool localClippingEnabled;
  late Map<String,dynamic> renderOptions;
  List<Plane> clippingPlanes;
  int outputEncoding;
  ColorSpace colorSpace;
  int toneMapping;
  int shadowMapType;
  double toneMappingExposure;
}

/// threeJs utility class. If you want to learn how to connect cannon.js with js, please look at the examples/threejs_* instead.
class ThreeJS implements gpux.GpuRenderer{
  void Function() onSetupComplete;
  ThreeJS({
    Settings? settings,
    required this.onSetupComplete, 
    required this.setup,
    this.rendererUpdate,
    this.postProcessor,
    this.windowResizeUpdate,
    Size? size,
    GpuRenderer? renderer,
    this.renderNumber = 0,
    this.loadingWidget
  }){
    this.settings = settings ?? Settings();
    _resolution = this.settings.screenResolution;
    _fixedSize = size;
  }

  int renderNumber;
  final List<VoidCallback> _listeners = [];

  Widget? loadingWidget;
  Size? _fixedSize;
  late final Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  bool visible = true;

  RenderTarget? renderTarget;
  GpuRenderer? renderer;
  final core.Clock clock = core.Clock();

  late final core.Scene scene;
  late final core.Camera camera;
  Ticker? ticker;

  double get width => screenSize!.width;
  double get height => screenSize!.height;

  Size? screenSize;
  double? _resolution;
  double get dpr => _resolution ?? 1.0;
  void setResolution(double newResolution){
    _resolution = newResolution;
  }

  bool pause = false;
  bool _disposed = false;
  bool _isRendererReady = false;
  bool isVisibleOnScreen = true;
  bool _mounted = false;
  bool get mounted => _mounted;
  bool _updating = false;
  bool get updating => _updating;

  void Function()? rendererUpdate;
  void Function(Size newSize)? windowResizeUpdate;
  void Function([double? dt])? postProcessor;
  Future<void> Function(core.Scene,core.Camera,[double? dt])? customRenderer;
  Future<void> Function(BuildContext) onWindowResize = (context) async{};
  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];
  List<Function()> disposeEvents = [];

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void toDispose(Function() event){
    disposeEvents.add(event);
  }

  void dispose(){
    if(_disposed) return;
    _disposed = true;
    ticker?.dispose();
    ticker = null;
    renderer?.dispose();
    renderer = null;
    renderTarget?.dispose();
    renderTarget = null;
    scene.dispose();
    for(final event in disposeEvents){
      event.call();
    }
    
    camera.dispose();
    events.clear();
    disposeEvents.clear();

    loadingWidget = null;
    _fixedSize = null;
    screenSize = null;

    rendererUpdate = null;
    windowResizeUpdate = null;
    postProcessor = null;
    setup = null;
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }
    
    final mqd = MediaQuery.of(context);

    screenSize = _fixedSize ?? mqd.size;
    _resolution ??= mqd.devicePixelRatio;
    
    Future.delayed(Duration(milliseconds: renderNumber*100), () async{
      await init();
    });
  }
  
  // Future<void> animate(Duration duration) async {
  //   if (!mounted || _disposed || updating || !isVisibleOnScreen || !visible) {
  //     return;
  //   }
  //   _updating = true;
  //   double dt = clock.getDelta();
    
  //   if(settings.animate){
  //     await (customRenderer?.call(scene,camera,dt) ?? render(scene,camera,dt));
  //     if(!pause){
  //       for(int i = 0; i < events.length;i++){
  //         events[i].call(dt);
  //       }
  //     }
  //   }
  //   _updating = false;
  // }

  // Future<void> render([core.Scene? scene, core.Camera? camera, double? dt]) async{
  //   if(!_mounted) return;
  //   scene ??= this.scene;
  //   camera ??= this.camera;
  //   renderer!.render(scene, camera);
  // }
  
  void executeFrameTick() {
    if (!_mounted || _disposed || _updating || !visible) return;
    _updating = true;

    double dt = clock.getDelta();

    if (settings.animate) {
      // 1. Process custom game scene update event callbacks
      if (!pause) {
        for (int i = 0; i < events.length; i++) {
          events[i].call(dt);
        }
      }

      // 2. Direct your GpuRenderer to compile down onto the active frame target texture channel
      renderer!.render(scene, camera);

      for (final listener in _listeners) {
        listener();
      }
    }

    _updating = false;
  }

//   GpuEffectComposer? _composer;

// GpuTexture? _rawSceneTexture;
// GpuTextureView? _rawSceneTextureView;
// GpuRenderPipeline? _rawFxaaPipeline;
// GpuBindGroup? _rawFxaaBindGroup;
// int _lastW = 0;
// int _lastH = 0;

// void executeFrameTick(GpuFrame frame) {
//   if (!_mounted || _disposed || _updating || !visible) return;
//   _updating = true;
  
//   double dt = clock.getDelta();
  
//   if (settings.animate) {
//     if (!pause) {
//       for (int i = 0; i < events.length; i++) {
//         events[i].call(dt);
//       }
//     }

//     // FIX: Define an explicit 2x Super-Sampling Scale Factor
//     const int superSampleScale = 2;
//     final int targetWidth = frame.width * superSampleScale;
//     final int targetHeight = frame.height * superSampleScale;

//     // 1. Manage high-density offscreen texture lifecycle manually
//     if (_rawSceneTexture == null || _lastW != targetWidth || _lastH != targetHeight) {
//       _rawSceneTexture?.destroy();
//       _lastW = targetWidth;
//       _lastH = targetHeight;
      
//       _rawSceneTexture = frame.device.createTexture(
//         label: 'Super-Sampled Scene Texture Target',
//         width: targetWidth, height: targetHeight, // 2x scaled up bounds!
//         format: frame.format,
//         usage: GpuTextureUsage.renderAttachment | GpuTextureUsage.textureBinding,
//         sampleCount: 1,
//       );
//       _rawSceneTextureView = _rawSceneTexture!.createView();
      
//       final shaderModule = frame.device.createShaderModule(
//         _fxaaCombinedShaderSource,
//         label: 'Enhanced FXAA Shader Module',
//       );
      
//       _rawFxaaPipeline = frame.device.createRenderPipeline(GpuRenderPipelineDescriptor(
//         label: 'Manual FXAA Pipeline',
//         layout: null,
//         vertexModule: shaderModule,
//         vertexEntryPoint: 'vs_main',
//         fragmentModule: shaderModule,
//         fragmentEntryPoint: 'fs_main',
//         colorTargets: [GpuColorTargetState(format: frame.format)],
//         primitiveTopology: GpuPrimitiveTopology.triangleList,
//       ));
      
//       final sampler = frame.device.createSampler(
//         magFilter: GpuFilterMode.linear, // Bilinear filtering blends pixels when downsampling
//         minFilter: GpuFilterMode.linear,
//       );
      
//       _rawFxaaBindGroup = frame.device.createBindGroup(
//         layout: _rawFxaaPipeline!.getBindGroupLayout(0),
//         entries: [
//           GpuBindGroupEntry.sampler(binding: 0, sampler: sampler),
//           GpuBindGroupEntry.textureView(binding: 1, view: _rawSceneTextureView!),
//         ],
//       );
//     }

//     // Ensure your depth buffer expands to match the new 2x supersampled frame resolution!
//     //_ensureDepthTexture(targetWidth, targetHeight, sampleCount: 1);
//     final double originalAspect = frame.width / frame.height;
    
//     // Explicitly override your camera's internal aspect tracker if it has one:
//     camera.aspect = originalAspect;
    
//     // Force the projection matrix to recalculate based on the original screen proportions
//     camera.updateProjectionMatrix();

//     // ==========================================
//     // PASS 1: Render 3D Scene into high-density 2x texture
//     // ==========================================
//     final proxyFrame = GpuFrame(
//       device: frame.device,
//       format: frame.format,
//       targetView: _rawSceneTextureView!, 
//       width: targetWidth,  // Tell the renderer to project onto the larger canvas size
//       height: targetHeight,
//     );
    
//     renderer!.render1(scene, camera, proxyFrame);

//     // ==========================================
//     // PASS 2: FXAA edge blend down to native screen size
//     // ==========================================
//     final commandEncoder = frame.device.createCommandEncoder(label: 'FXAA Resolution Downscale Pass');
    
//     final colorAttachment = GpuColorAttachment(
//       view: frame.targetView, // The actual 1x size presentation screen surface
//       loadOp: GpuLoadOp.clear,
//       storeOp: GpuStoreOp.store,
//       clearValue: GpuColor(0, 0, 0, 1),
//     );
    
//     final renderPass = commandEncoder.beginRenderPass(
//       colorAttachments: [colorAttachment],
//     );
    
//     renderPass.setPipeline(_rawFxaaPipeline!);
//     renderPass.setBindGroup(0, _rawFxaaBindGroup!);
//     renderPass.draw(vertexCount: 3); 
//     renderPass.end();
    
//     frame.device.queue.submit([commandEncoder.finish()]);

//     for (final listener in _listeners) {
//       listener();
//     }
//   }
  
//   _updating = false;
// }



// // Full combined shader block tailored for your specific framework structure
// final String _fxaaCombinedShaderSource = '''
// @vertex 
// fn vs_main(@builtin(vertex_index) VertexIndex : u32) -> @builtin(position) vec4<f32> { 
//     var pos = array<vec2<f32>, 3>( 
//         vec2<f32>(-1.0, -1.0), 
//         vec2<f32>( 3.0, -1.0), 
//         vec2<f32>(-1.0,  3.0) 
//     ); 
//     return vec4<f32>(pos[VertexIndex], 0.0, 1.0); 
// }

// @group(0) @binding(0) var s_sampler: sampler; 
// @group(0) @binding(1) var t_texture: texture_2d<f32>; 

// @fragment 
// fn fs_main(@builtin(position) FragCoord: vec4<f32>) -> @location(0) vec4<f32> { 
//     let dims = vec2<f32>(textureDimensions(t_texture)); 
//     let texel = 1.0 / dims; 
//     let uv = FragCoord.xy * texel; 

//     let rgbM  = textureSample(t_texture, s_sampler, uv).rgb; 
//     let rgbNW = textureSample(t_texture, s_sampler, uv + vec2<f32>(-1.0, -1.0) * texel).rgb; 
//     let rgbNE = textureSample(t_texture, s_sampler, uv + vec2<f32>( 1.0, -1.0) * texel).rgb; 
//     let rgbSW = textureSample(t_texture, s_sampler, uv + vec2<f32>(-1.0,  1.0) * texel).rgb; 
//     let rgbSE = textureSample(t_texture, s_sampler, uv + vec2<f32>( 1.0,  1.0) * texel).rgb; 

//     let luma = vec3<f32>(0.299, 0.587, 0.114); 
//     let lumaM  = dot(rgbM,  luma); 
//     let lumaNW = dot(rgbNW, luma); 
//     let lumaNE = dot(rgbNE, luma); 
//     let lumaSW = dot(rgbSW, luma); 
//     let lumaSE = dot(rgbSE, luma); 

//     var dir = vec2<f32>( 
//         -((lumaNW + lumaNE) - (lumaSW + lumaSE)), 
//         ((lumaNW + lumaSW) - (lumaNE + lumaSE)) 
//     ); 

//     let dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * 0.03125, 0.0078125); 
//     let rcpDirMin = 1.0 / (min(abs(dir.x), dir.y) + dirReduce); 
//     dir = min(vec2<f32>(8.0, 8.0), max(vec2<f32>(-8.0, -8.0), dir * rcpDirMin)) * texel; 

//     let rgbA = 0.5 * ( 
//         textureSample(t_texture, s_sampler, uv + dir * (1.0/3.0 - 0.5)).rgb + 
//         textureSample(t_texture, s_sampler, uv + dir * (2.0/3.0 - 0.5)).rgb 
//     ); 
//     let rgbB = rgbA * 0.5 + 0.25 * ( 
//         textureSample(t_texture, s_sampler, uv + dir * -0.5).rgb + 
//         textureSample(t_texture, s_sampler, uv + dir * 0.5).rgb 
//     ); 

//     let lumaB = dot(rgbB, luma); 
//     let lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE))); 
//     let lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE))); 

//     if ((lumaB < lumaMin) || (lumaB > lumaMax)) { 
//         return vec4<f32>(rgbA, 1.0); 
//     } 
//     return vec4<f32>(rgbB, 1.0); 
// }
// ''';

  Future<void> init() async{
    if (_mounted) return;
    await setup?.call();
    _mounted = true;
    onSetupComplete();
    for (final listener in _listeners) {
      listener();
    }
  }

  Widget build() {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return core.Peripherals(
        key: globalKey,
        builder: (BuildContext context) {
          return Container(
            color: Colors.white,
            width: !visible?0:width,
            height: !visible?0:height,
            child: gpux.DefaultGpu(
              child: gpux.GpuView(
                renderer: this, 
              ),
            ),
          );
        });
    });
  }

  @override
  bool render([gpux.GpuFrame? frame]) {
    if (!mounted || _disposed) return false;
    // Lazy initialize renderer carefully without breaking state mappings
    if (renderer == null) {
      renderer = GpuRenderer();
      renderer!.init(frame!, RendererConfig()).then((_) {
        _isRendererReady = true;
        // Fire your custom initialization callback to notify listeners/UI
        onSetupComplete(); 

        for (final listener in _listeners) {
          listener();
        }
      }).catchError((e) {
        print("Error during renderer initialization: $e");
      });
      renderer?.enableFrameLogging = false;
    }

    // Only kick off a frame pass execution trace if initialization has completed
    if (mounted && _isRendererReady) {
      executeFrameTick();
      return true;
    }

    // Return true to tell the hardware wrapper engine to keep checking for frames, 
    // but don't draw yet because async setup is still processing.
    return false; 
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  bool shouldUpdate(gpux.GpuRenderer oldRenderer) => false;

  @override
  bool get shouldSkipNextFrame => false;
}