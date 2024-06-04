import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_angle/flutter_angle.dart';
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
    this.shadowMapType = PCFShadowMap
  }){
    this.renderOptions = renderOptions ?? {
      "format": RGBAFormat,
      "samples": 4
    };
  }

  bool animate;
  bool useSourceTexture;
  bool enableShadowMap;
  bool autoClear;
  bool alpha;
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
}

/// threeJs utility class. If you want to learn how to connect cannon.js with js, please look at the examples/threejs_* instead.
class ThreeJS{
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
  }){
    this.settings = settings ?? Settings();
    _size = size;
    lateRenderer = renderer;
  }

  Size? _size;
  late Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  FlutterGLTexture? texture;
  late final RenderingContext gl;
  core.WebGLRenderTarget? renderTarget;
  core.WebGLRenderer? renderer;
  core.WebGLRenderer? lateRenderer;
  core.Clock clock = core.Clock();

  late core.Scene scene;
  late core.Camera camera;
  
  late double width;
  late double height;
  Size? screenSize;
  double dpr = 1.0;

  bool disposed = false;
  WebGLTexture? sourceTexture;
  bool pause = false;
  bool mounted = false;

  void Function()? rendererUpdate;
  void Function(Size newSize)? windowResizeUpdate;
  void Function([double? dt])? postProcessor;
  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void dispose(){
    disposed = true;
    renderer?.dispose();
    renderTarget?.dispose();
    if(texture != null){
      FlutterAngle.deleteTexture(texture!);
    }
    scene.material?.dispose();
    scene.children.forEach((element) {
      element.material?.dispose();
    });
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
  
  void animate() {
    if (!mounted || disposed) {
      return;
    }
    render();
    if(settings.animate){
      Future.delayed(const Duration(milliseconds: 1000~/60), () {
        if(!pause){
          for(int i = 0; i < events.length;i++){
            events[i].call(clock.getDelta());
          }
        }
        animate();
      });
    }
  }

  Future<void> render() async{
    if(sourceTexture == null){
      FlutterAngle.activateTexture(texture!);
    }
    rendererUpdate?.call();
    if(postProcessor == null){
      renderer!.clear();
      renderer!.setViewport(0,0,width,height);
      renderer!.render(scene, camera);
    }
    else{
      postProcessor?.call(clock.getDelta());
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
        "antialias": true,
        "alpha": settings.alpha,
        "clearColor": settings.clearColor,
        "clearAlpha": settings.clearAlpha,
      };

      if(!kIsWeb){
        options['logarithmicDepthBuffer'] = true;
      }

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
    }

    if(settings.useSourceTexture){
      final core.WebGLRenderTargetOptions pars = core.WebGLRenderTargetOptions(settings.renderOptions);
      renderTarget = core.WebGLMultisampleRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
  }
  void onWindowResize(BuildContext context){
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
        postProcessor?.call(clock.getDelta());
      }
      render();
    }
  }

  void initScene() async{
    initRenderer();
    await setup?.call();
    mounted = true;
    animate();
    onSetupComplete();
  }

  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    await FlutterAngle.initOpenGL(true);

    texture = await FlutterAngle.createTexture(      
      AngleOptions(
        width: width.toInt(), 
        height: height.toInt(), 
        dpr: dpr,
        alpha: settings.alpha,
        antialias: true,
        customRenderer: false
      )
    );
    
    gl = texture!.getContext();
    initScene();
  }

  Widget build() {
    return  Builder(builder: (BuildContext context) {
      initSize(context);
      return Stack(
        children:[
          Container(
            width: screenSize!.width,
            height: screenSize!.height,
            color: Theme.of(context).canvasColor,
            child: core.Peripherals(
              key: globalKey,
              builder: (BuildContext context) {
                return Container(
                  width: width,
                  height: height,
                  color: Theme.of(context).canvasColor,
                  child: Builder(builder: (BuildContext context) {
                    if (kIsWeb) {
                      return texture != null? HtmlElementView(viewType:texture!.textureId.toString()):Container();
                    } 
                    else {
                      return texture != null?Texture(textureId: texture!.textureId):Container();
                    }
                  })
                );
              }
            ),
          ),
        ]
      );
    });
  }
}