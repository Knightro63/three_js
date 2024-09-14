import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:three_js_core/others/index.dart';
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
    this.stencil = true
  }){
    this.renderOptions = renderOptions ?? {
      "format": RGBAFormat,
      "samples": 4
    };
  }

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
class ThreeJS {
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
    this.texture
  }){
    this.settings = settings ?? Settings();
    _size = size;
    lateRenderer = renderer;
  }

  //bool _allowDeleteTexture = true;
  Size? _size;
  late Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  FlutterAngleTexture? texture;
  late final RenderingContext gl;
  
  core.WebGLRenderTarget? falseRenderTarget;
  late final core.Camera falseCamera;
  late final core.Mesh falseMesh;

  core.WebGLRenderTarget? renderTarget;
  core.WebGLRenderer? renderer;
  core.WebGLRenderer? lateRenderer;
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

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void toDispose(Function() event){
    disposeEvents.add(event);
  }

  void dispose(){
    if(disposed) return;
    disposed = true;
    ticker?.dispose();
    if(texture != null){
      FlutterAngle.deleteTexture(texture!);
    }
    renderer?.dispose();
    renderTarget?.dispose();
    falseRenderTarget?.dispose();
    scene.dispose();
    for(final event in disposeEvents){
      event.call();
    }
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = _size ?? mqd.size;
    dpr = mqd.devicePixelRatio;

   initPlatformState();
  }
  
  void animate(Duration duration) {
    if (!mounted || disposed || updating) {
      return;
    }
    updating = true;
    double dt = clock.getDelta();
    render(dt);
    if(settings.animate){
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
      FlutterAngle.activateTexture(texture!);
    }
    rendererUpdate?.call(); 
    if(postProcessor == null){
      // false target to get it to run
      if(sourceTexture != null && !kIsWeb){
        renderer!.setRenderTarget(falseRenderTarget);
        renderer!.render(falseMesh,falseCamera );
        renderer!.setRenderTarget(renderTarget);
      }
      
      renderer!.clear();
      renderer!.setViewport(0,0,width,height);
      renderer!.render(scene, camera);
    }
    else{
      renderer!.clear();
      renderer!.setRenderTarget(renderTarget);
      renderer!.setViewport(0,0,width,height);
      postProcessor?.call(dt);
    }
    
    if(sourceTexture != null){
      FlutterAngle.activateTexture(texture!);
    }
    await FlutterAngle.updateTexture(texture!,sourceTexture);
  }
  
  void initRenderer() {
    renderer = lateRenderer;
    if(renderer == null){
      Map<String, dynamic> options = {
        "width": width,
        "height": height,
        "gl": gl,
        "stencil": settings.stencil,
        "antialias": true,
        "alpha": settings.alpha,
        "clearColor": settings.clearColor,
        "clearAlpha": settings.clearAlpha,
        "logarithmicDepthBuffer": settings.logarithmicDepthBuffer
      };
      
      renderer = lateRenderer ?? core.WebGLRenderer(options);
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
    }

    if(settings.useSourceTexture && !kIsWeb){
      final core.WebGLRenderTargetOptions pars = core.WebGLRenderTargetOptions(settings.renderOptions);
      renderTarget = core.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);

      falseMesh = core.Mesh(core.PlaneGeometry(0,0), null);
      falseRenderTarget = core.WebGLRenderTarget(0,0, core.WebGLRenderTargetOptions({}));
      falseCamera = core.Camera();
      renderer!.setRenderTarget(falseRenderTarget);
    }
  }
  void onWindowResize(BuildContext context){
    double dt = clock.getDelta();
    final mqd = MediaQuery.of(context);
    if(_size == null && screenSize != mqd.size){
      screenSize = mqd.size;
      dpr = mqd.devicePixelRatio;
      windowResizeUpdate?.call(screenSize!);
      renderer!.setPixelRatio(dpr);
      if(postProcessor == null){
        renderer!.setSize(screenSize!.width, screenSize!.height);
      }
      else{
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
    width = screenSize!.width;
    height = screenSize!.height;
    if(texture == null){
      await FlutterAngle.initOpenGL(true);
      
      texture = await FlutterAngle.createTexture(      
        AngleOptions(
          width: width.toInt(), 
          height: height.toInt(), 
          dpr: dpr,
          alpha: settings.alpha,
          antialias: true,
          customRenderer: false,
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
            width: width,
            height: height,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return texture != null? HtmlElementView(viewType:texture!.textureId.toString()):Container();
              } 
              else {
                return texture != null?
                  Transform.scale(
                    scaleY: sourceTexture != null || Platform.isAndroid?1:-1,
                    child:Texture(textureId: texture!.textureId)
                  ):Container();
              }
            })
          );
        }
      );
    });
  }
}