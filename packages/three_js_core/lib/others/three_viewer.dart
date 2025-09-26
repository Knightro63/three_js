import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:three_js_core/others/index.dart';
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
    this.screenResolution
  }){
    this.renderOptions = renderOptions ?? {
      "format": RGBAFormat,
      "samples": 4
    };
  }
  
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  PowerPreference powerPreference;
  bool reverseDepthBuffer;
  bool failIfMajorPerformanceCaveat;
  bool depth = true;
  Precision precision;
  bool alpha;
  bool stencil;
  bool logarithmicDepthBuffer;
  int clearColor;
  double clearAlpha;
  bool antialias;
  WebXRManager Function(WebGLRenderer renderer, dynamic gl)? xr;
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
    core.WebGLRenderer? renderer,
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

  FlutterAngleTexture? texture;
  RenderingContext? gl;

  core.WebGLRenderTarget? renderTarget;
  core.WebGLRenderer? renderer;
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

  WebGLTexture? sourceTexture;

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
  Future<void> Function(core.Scene,core.Camera,FlutterAngleTexture,[double? dt])? customRenderer;
  Future<void> Function(BuildContext) onWindowResize = (context) async{};
  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];
  List<Function()> disposeEvents = [];

  FlutterAngle? angle = FlutterAngle();

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

    allNativeData.dispose();

    angle?.dispose([texture]);
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
      await initPlatformState();
    });
  }
  
  Future<void> animate(Duration duration) async {
    if (!mounted || _disposed || updating || !isVisibleOnScreen || !visible) {
      return;
    }
    _updating = true;
    double dt = clock.getDelta();
    
    if(settings.animate){
      await (customRenderer?.call(scene,camera,texture!,dt) ?? render(scene,camera,texture!,dt));
      if(!pause){
        for(int i = 0; i < events.length;i++){
          events[i].call(dt);
        }
      }
    }
    _updating = false;
  }

  Future<void> render([core.Scene? scene, core.Camera? camera, FlutterAngleTexture? texture, double? dt]) async{
    scene ??= this.scene;
    camera ??= this.camera;
    texture ??= this.texture!;
    
    if(sourceTexture == null){
      angle?.activateTexture(texture);
    }
    rendererUpdate?.call(); 
    if(postProcessor == null){
      renderer!.clear();
      renderer!.setViewport(0,0,width,height);
      renderer!.render(scene, camera);
    }
    else{
      postProcessor?.call(dt);
    }
    
    if(sourceTexture != null){
      angle?.activateTexture(texture);
    }
    await angle?.updateTexture(texture,sourceTexture);
  }
  
  void initRenderer() {
    WebGLRendererParameters options = WebGLRendererParameters(
      width: width,
      height: height,
      gl: gl!,
      stencil: settings.stencil,
      antialias: settings.antialias,
      alpha: settings.alpha,
      clearColor: settings.clearColor,
      clearAlpha: settings.clearAlpha,
      logarithmicDepthBuffer: settings.logarithmicDepthBuffer,
      xr: settings.xr,
      depth: settings.depth,
      premultipliedAlpha: settings.premultipliedAlpha,
      preserveDrawingBuffer: settings.preserveDrawingBuffer,
      powerPreference: settings.powerPreference,
      failIfMajorPerformanceCaveat: settings.failIfMajorPerformanceCaveat,
      reverseDepthBuffer: settings.reverseDepthBuffer,
      precision: settings.precision,
    );
    
    renderer = core.WebGLRenderer(options);
    renderer!.setPixelRatio(_resolution!);
    renderer!.setSize(width, height, false);
    renderer!.alpha = settings.alpha;
    renderer!.shadowMap.enabled = settings.enableShadowMap;
    renderer!.shadowMap.type = settings.shadowMapType;
    renderer!.autoClear = settings.autoClear;
    renderer!.setClearColor(
      Color.fromHex32(settings.clearColor), 
      settings.clearAlpha
    );
    renderer!.autoClearDepth = settings.autoClearDepth;
    renderer!.autoClearStencil = settings.autoClearStencil;
    renderer!.outputEncoding = settings.outputEncoding;
    renderer!.outputColorSpace = settings.colorSpace.toString();
    renderer!.localClippingEnabled = settings.localClippingEnabled;
    renderer!.clippingPlanes = settings.clippingPlanes;
    renderer!.toneMapping = settings.toneMapping;
    renderer!.toneMappingExposure = settings.toneMappingExposure;

    if(settings.useSourceTexture){
      final core.WebGLRenderTargetOptions pars = core.WebGLRenderTargetOptions(settings.renderOptions);
      renderTarget = core.WebGLRenderTarget((width * _resolution!).toInt(), (height * _resolution!).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
  }
  
  Future<void> _onWindowResize(BuildContext context) async{
    if (_disposed) return;
    double dt = clock.getDelta();
    final mqd = MediaQuery.maybeOf(context);
    if (mqd == null) return;
    if(_fixedSize == null && screenSize != mqd.size && texture != null){
      screenSize = mqd.size;

      if(settings.screenResolution == null){
        _resolution = mqd.devicePixelRatio;
      }

      final options = AngleOptions(
        width: width.toInt(),
        height: height.toInt(),
        dpr: _resolution!,
      );

      await angle?.resize(texture!, options);

      camera.aspect = width/height;
      camera.updateProjectionMatrix();

      windowResizeUpdate?.call(screenSize!);
      renderer!.setSize(width, height);

      if(postProcessor != null){
        postProcessor?.call(dt);
      }
      render(scene,camera,texture!,dt);
    }
  }

  Future<void> initScene() async{
    if (renderer == null) {
      initRenderer();
    }
    await setup?.call();
    _mounted = true;
    ticker = Ticker(animate);
    ticker?.start();
    onSetupComplete();
  }

  Future<void> initPlatformState() async {
    if(texture == null){
      await angle?.init();
      
      texture = await angle?.createTexture(      
        AngleOptions(
          width: width.toInt(), 
          height: height.toInt(), 
          dpr: _resolution!,
          alpha: settings.alpha,
          antialias: settings.antialias,
          customRenderer: !settings.useSourceTexture,
          useSurfaceProducer: true
        )
      );
    }

    console.info(texture?.toMap());
    if (gl == null) {
      gl = texture!.getContext();
    }
    await initScene();
  }

  Widget build() {
    return  Builder(builder: (BuildContext context) {
      initSize(context);
      return core.Peripherals(
        key: globalKey,
        builder: (BuildContext context) {
          return Container(
            width: !visible?0:width,
            height: !visible?0:height,
            child: SizeChangedLayoutNotifier(
              child: Builder(builder: (BuildContext context) {
                if (kIsWeb) {
                  return texture != null && mounted? HtmlElementView(viewType:texture!.textureId.toString()):loadingWidget ?? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Theme.of(context).canvasColor,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator()
                  );
                } 
                else {
                  return texture != null && mounted?
                    Transform.scale(
                      scaleY: sourceTexture != null || Platform.isAndroid?1:-1,
                      child:Texture(textureId: texture!.textureId)
                    ):loadingWidget ?? Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Theme.of(context).canvasColor,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator()
                    );
                }
              })
            )
          );
        }
      );
    });
  }
}