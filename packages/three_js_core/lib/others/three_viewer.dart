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
    this.outputEncoding = LinearEncoding,
    this.toneMapping = NoToneMapping,
    this.shadowMapType = PCFShadowMap,
    this.toneMappingExposure = 1.0,
    this.logarithmicDepthBuffer = false,
    this.stencil = true,
    this.xr
  }){
    this.renderOptions = renderOptions ?? {
      "format": RGBAFormat,
      "samples": 4
    };
  }

  WebXRManager Function(WebGLRenderer renderer, dynamic gl)? xr;
  bool animate;
  bool logarithmicDepthBuffer;
  bool useSourceTexture;
  bool enableShadowMap;
  bool autoClear;
  bool alpha;
  bool stencil;
  bool autoClearDepth;
  bool autoClearStencil;
  bool localClippingEnabled;
  int clearColor;
  double clearAlpha;
  late Map<String,dynamic> renderOptions;
  List<Plane> clippingPlanes;
  int outputEncoding;
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
    this.rendererUpdate,
    this.postProcessor,
    this.windowResizeUpdate,
    required this.setup,
    Size? size,
    core.WebGLRenderer? renderer,
    this.renderNumber = 0,
    this.loadingWidget,
  }){
    this.angle = FlutterAngle();
    this.settings = settings ?? Settings();
    _size = size;
  }

  int renderNumber;

  late final BuildContext _context;
  Timer? _debounceTimer;

  Widget? loadingWidget;
  Size? _size;
  late Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  bool visible = true;

  FlutterAngleTexture? texture;
  late final RenderingContext gl;

  core.WebGLRenderTarget? renderTarget;
  core.WebGLRenderer? renderer;
  core.Clock clock = core.Clock();

  late core.Scene scene;
  late core.Camera camera;
  Ticker? ticker;

  late double width;
  late double height;
  Size? screenSize;
  double dpr = 1.0;

  bool disposed = false;
  WebGLTexture? sourceTexture;
  bool pause = false;
  bool mounted = false;
  bool updating = false;

  void Function()? rendererUpdate;
  void Function(Size newSize)? windowResizeUpdate;
  void Function([double? dt])? postProcessor;
  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];
  List<Function()> disposeEvents = [];

  late FlutterAngle angle;

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void toDispose(Function() event){
    disposeEvents.add(event);
  }

  @override
  void didChangeMetrics() {
    if (disposed) return;
    _debounceTimer?.cancel(); // Clear existing timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () { // Set a new timer
      onWindowResize(_context);
    });
  }

  void dispose(){
    if(disposed) return;
    disposed = true;
    _debounceTimer?.cancel(); // Cancel timer if active
    WidgetsBinding.instance.removeObserver(this);

    ticker?.dispose();
    renderer?.dispose();
    renderTarget?.dispose();
    scene.dispose();
    for(final event in disposeEvents){
      event.call();
    }
    
    camera.dispose();
    events.clear();
    disposeEvents.clear();

    allNativeData.dispose();

    angle.dispose([texture!]);
    texture = null;
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }
    _context = context;
    WidgetsBinding.instance.addObserver(this);
    final mqd = MediaQuery.of(context);

    screenSize = _size ?? mqd.size;
    dpr = mqd.devicePixelRatio;

    width = screenSize!.width;
    height = screenSize!.height;
    
    Future.delayed(Duration(milliseconds: renderNumber*100), () async{
      await initPlatformState();
    });
  }
  
  Future<void> animate(Duration duration) async {
    if (!mounted || disposed || updating) {
      return;
    }
    updating = true;
    double dt = clock.getDelta();
    
    if(settings.animate){
      await render(dt);
      if(!pause){
        for(int i = 0; i < events.length;i++){
          events[i].call(dt);
        }
      }
    }
    updating = false;
  }
  Future<void> render([double? dt]) async{
    if(sourceTexture == null){
      angle.activateTexture(texture!);
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
      angle.activateTexture(texture!);
    }
    await angle.updateTexture(texture!,sourceTexture);
  }
  
  void initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": gl,
      "stencil": settings.stencil,
      "antialias": true,
      "alpha": settings.alpha,
      "clearColor": settings.clearColor,
      "clearAlpha": settings.clearAlpha,
      "logarithmicDepthBuffer": settings.logarithmicDepthBuffer,
      'xr': settings.xr
    };
    
    renderer = core.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
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
    renderer!.outputEncoding = sRGBEncoding;
    renderer!.localClippingEnabled = settings.localClippingEnabled;
    renderer!.clippingPlanes = settings.clippingPlanes;
    renderer!.toneMapping = settings.toneMapping;
    renderer!.toneMappingExposure = settings.toneMappingExposure;

    if(settings.useSourceTexture){
      final core.WebGLRenderTargetOptions pars = core.WebGLRenderTargetOptions(settings.renderOptions);
      renderTarget = core.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
  }
  
  Future<void> onWindowResize(BuildContext context) async{
    if (disposed) return;
    double dt = clock.getDelta();
    final mqd = MediaQuery.maybeOf(context);
    if (mqd == null) return;
    if(_size == null && screenSize != mqd.size && texture != null){
      screenSize = mqd.size;
      width = screenSize!.width;
      height = screenSize!.height;
      dpr = mqd.devicePixelRatio;

      final options = AngleOptions(
        width: width.toInt(),
        height: height.toInt(),
        dpr: dpr,
      );

      await angle.resize(texture!, options);

      camera.aspect = width/height;
      camera.updateProjectionMatrix();

      windowResizeUpdate?.call(screenSize!);
      renderer!.setSize(width, height, false);

      if(postProcessor != null){
        postProcessor?.call(dt);
      }
      render(dt);
    }
  }

  Future<void> initScene() async{
    initRenderer();
    await setup?.call();
    mounted = true;
    ticker = Ticker(animate);
    ticker?.start();
    onSetupComplete();
  }

  Future<void> initPlatformState() async {
    if(texture == null){
      await angle.init();
      
      texture = await angle.createTexture(      
        AngleOptions(
          width: width.toInt(), 
          height: height.toInt(), 
          dpr: dpr,
          alpha: settings.alpha,
          antialias: true,
          customRenderer: !settings.useSourceTexture,
          useSurfaceProducer: true
        )
      );
    }

    console.info(texture?.toMap());
    gl = texture!.getContext();
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