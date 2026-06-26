import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:three_js_impeller_renderer/renderer/renderer.dart';
import 'package:three_js_core/renderers/index.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart';

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
  XRManager Function(ImpellerRenderer renderer, dynamic gl)? xr;
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

class ThreeJSPainter extends CustomPainter {
  ThreeJSPainter(this.renderer, {required Listenable repaint}) : super(repaint: repaint);

  ImpellerRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    /// Wrap the Flutter GPU texture as a ui.Image and draw it like normal!
    final image = renderer.image;
    if(image != null) canvas.drawImage(image, Offset(0, 0), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ThreeJS{
  void Function() onSetupComplete;
  ThreeJS({
    Settings? settings,
    required this.onSetupComplete, 
    required this.setup,
    this.rendererUpdate,
    this.postProcessor,
    this.windowResizeUpdate,
    Size? size,
    ImpellerRenderer? renderer,
    this.renderNumber = 0,
    this.loadingWidget
  }){
    this.settings = settings ?? Settings();
    _resolution = this.settings.screenResolution;
    _fixedSize = size;
  }

  int renderNumber;
  final ChangeNotifier repaintNotifier = ChangeNotifier();

  BuildContext? _context;
  Timer? _debounceTimer;

  Widget? loadingWidget;
  Size? _fixedSize;
  late final Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  bool visible = true;

  RenderTarget? renderTarget;
  ImpellerRenderer? renderer;
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

  bool didRender = false;

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
    repaintNotifier.dispose();
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }
    
    _context = context;

    final mqd = MediaQuery.of(context);

    screenSize = _fixedSize ?? mqd.size;
    _resolution ??= mqd.devicePixelRatio;
    
    Future.delayed(Duration(milliseconds: renderNumber*100), () async{
      await init();
    });
  }

  Future<void> animate(Duration duration) async {
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
      await (customRenderer?.call(scene,camera,dt) ?? render(scene,camera,dt));
      repaintNotifier.notifyListeners(); 
    }

    _updating = false;
  }

  Future<void> render([core.Scene? scene, core.Camera? camera, double? dt]) async{
    scene ??= this.scene;
    camera ??= this.camera;
    
    rendererUpdate?.call(); 
    if(postProcessor == null){
      renderer!.setViewport(0,0,width,height);
      renderer!.render(scene, camera);
    }
    else{
      renderer!.setViewport(0,0,width,height);
      postProcessor?.call(dt);
    }
  }

  Future<void> init() async{
    if (_mounted) return;
    if (renderer == null) {
      renderer = ImpellerRenderer(
        ImpellerRendererParameters(
          width: width, 
          height: height,
          sampleCount: settings.antialias?4:1
        )
      );
    }
    await setup?.call();
    _mounted = true;
    ticker = Ticker(animate);
    ticker?.start();
    onSetupComplete();
  }

  Widget build() {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return core.Peripherals(
        key: globalKey,
        builder: (BuildContext context) {
          return Container(
            color: Colors.transparent,
            width: !visible?0:width,
            height: !visible?0:height,
            child: renderer == null?SizedBox():CustomPaint(
              painter: ThreeJSPainter(renderer!,repaint: repaintNotifier),
            ),
          );
        });
    });
  }
}