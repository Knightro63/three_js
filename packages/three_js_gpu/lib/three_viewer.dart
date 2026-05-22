import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:three_js_gpu/renderer/RendererConfig.dart';
import 'renderer/webgpu/WebGPURenderer.dart';
import 'package:three_js_core/renderers/index.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter_gpux/flutter_gpux.dart';

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
    //this.powerPreference = core.PowerPreference.defaultp,
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
  //PowerPreference powerPreference;
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
  XRManager Function(WebGPURenderer renderer, dynamic gl)? xr;
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
class ThreeJS with WidgetsBindingObserver{
  void Function() onSetupComplete;
  ThreeJS({
    Settings? settings,
    required this.onSetupComplete, 
    required this.setup,
    this.rendererUpdate,
    this.postProcessor,
    this.windowResizeUpdate,
    Size? size,
    WebGPURenderer? renderer,
    this.renderNumber = 0,
    this.loadingWidget
  }){
    this.settings = settings ?? Settings();
    _resolution = this.settings.screenResolution;
    _fixedSize = size;
  }

  int renderNumber;

  BuildContext? _context;
  Timer? _debounceTimer;

  Widget? loadingWidget;
  Size? _fixedSize;
  late final Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  bool visible = true;

  RenderTarget? renderTarget;
  WebGPURenderer? renderer;
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

  @override
  void didChangeMetrics() {
    if (_disposed) return;
    _debounceTimer?.cancel(); // Clear existing timer
    _debounceTimer = Timer(Duration(milliseconds: 300+renderNumber*100), () { // Set a new timer
      if (_context != null && _context!.mounted) {
        _onWindowResize(_context!);
      }
    });
  }

  void dispose(){
    if(_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel(); // Cancel timer if active
    _debounceTimer = null;
    WidgetsBinding.instance.removeObserver(this);
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
    _context = context;
    WidgetsBinding.instance.addObserver(this);
    final mqd = MediaQuery.of(context);

    screenSize = _fixedSize ?? mqd.size;
    _resolution ??= mqd.devicePixelRatio;

    Future.delayed(Duration(milliseconds: renderNumber*100), () async{
      await init();
    });
  }
  
  Future<void> animate(Duration duration) async {
    if (!mounted || _disposed || updating || !isVisibleOnScreen || !visible) {
      return;
    }
    _updating = true;
    double dt = clock.getDelta();
    
    if(settings.animate){
      await (customRenderer?.call(scene,camera,dt) ?? render(scene,camera,dt));
      if(!pause){
        for(int i = 0; i < events.length;i++){
          events[i].call(dt);
        }
      }
    }
    _updating = false;
  }

  void setContext(GpuFrame frame){
    renderer?.setContext(frame);
  }

  Future<void> render([core.Scene? scene, core.Camera? camera, double? dt]) async{
    if(!_mounted) return;
    scene ??= this.scene;
    camera ??= this.camera;
    renderer!.render(scene, camera);
  }
  
  void executeFrameTick(GpuTextureView targetView) {
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

      // 2. Direct your WebGPURenderer to compile down onto the active frame target texture channel
      renderer!.render1(scene, camera, targetView);
    }

    _updating = false;
  }

  Future<void> _onWindowResize(BuildContext context) async{
    if (_disposed) return;
  }

  Future<void> init() async{
    if (renderer == null) {
      renderer = WebGPURenderer();
      renderer!.initialize(RendererConfig());
      renderer?.enableFrameLogging = false;
    }
    await setup?.call();
    _mounted = true;
    onSetupComplete();
  }

  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return core.Peripherals(
        key: globalKey,
        builder: (BuildContext context) {
          return SizedBox(
            width: !visible?0:width,
            height: !visible?0:height,
            child: DefaultGpu(
              child: GpuView(
                // 2. Hook up your custom GpuRenderer drawing pipeline class
                renderer: TriangleRenderer(this), 
              ),
            ),
          );
        });
    });
  }
}

class TriangleRenderer implements GpuRenderer {
  TriangleRenderer(this.threeJs);
  final ThreeJS threeJs;

  final List<VoidCallback> _listeners = [];
  
  @override
  bool render(GpuFrame frame) {
    if (!threeJs.mounted || threeJs._disposed) return false;

    // 1. Pass the active frame texture target view downstream into your WebGPURenderer 
    final GpuTextureView frameTargetView = frame.targetView;
    
    // 2. Drive the game engine clock step forward natively synchronized with the Flutter frame tick
    threeJs.executeFrameTick(frameTargetView);

    // 3. Inform Flutter to continuously schedule the next repaint layer block
    for (final listener in _listeners) {
      listener();
    }
    return true;
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void dispose() => _listeners.clear();

  @override
  bool shouldUpdate(GpuRenderer oldRenderer) => true;

  @override
  bool get shouldSkipNextFrame => false;
}




