import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js/three_js.dart' hide Texture, Color;

class DemoSettings{
  DemoSettings({
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
    this.outputEncoding = three.LinearEncoding
  }){
    this.renderOptions = renderOptions ?? {
      "format": three.RGBAFormat,
      "samples": 4
    };
  }

  bool animate;
  bool enableShadowMap;
  bool autoClear;
  bool alpha;
  bool autoClearDepth;
  bool autoClearStencil;
  bool localClippingEnabled;
  int clearColor;
  double clearAlpha;
  late Map<String,dynamic> renderOptions;
  List<three.Plane> clippingPlanes;
  int outputEncoding;
}

/// Demo utility class. If you want to learn how to connect cannon.js with three.js, please look at the examples/threejs_* instead.
class Demo{
  void Function() onSetupComplete;
  Demo({
    DemoSettings? settings,
    required this.onSetupComplete, 
    this.rendererUpdate,
    required this.fileName,
    required this.setup,
    Size? size
  }){
    this.settings = settings ?? DemoSettings();
    _size = size;
  }

  Size? _size;
  late DemoSettings settings;
  String fileName;
  final GlobalKey<three.PeripheralsState> globalKey = GlobalKey<three.PeripheralsState>();
  three.PeripheralsState get domElement => globalKey.currentState!;

  late FlutterGlPlugin three3dRender;
  WebGLRenderTarget? renderTarget;
  WebGLRenderer? renderer;
  Clock clock = Clock();

  late three.Scene scene;
  late three.Camera camera;
  
  late double width;
  late double height;
  Size? screenSize;
  double dpr = 1.0;

  bool disposed = false;
  dynamic sourceTexture;
  bool pause = false;
  bool mounted = false;

  void Function()? rendererUpdate;
  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void dispose(){
    disposed = true;
    //renderTarget?.dispose();
    //renderer?.dispose();
    scene.dispose();
    three3dRender.dispose();
    three.loading.clear();
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

  void render() {
    final gl = three3dRender.gl;
    rendererUpdate?.call();
    renderer!.render(scene, camera);
    gl.flush();
    if(!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }
  void initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
      "alpha": settings.alpha,
      "clearColor": settings.clearColor,
      "clearAlpha": settings.clearAlpha,
    };

    if(!kIsWeb){
      options['logarithmicDepthBuffer'] = true;
    }

    renderer = WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.alpha = settings.alpha;
    renderer!.shadowMap.enabled = settings.enableShadowMap;
    renderer!.shadowMap.type = three.PCFShadowMap;
    renderer!.autoClear = settings.autoClear;
    renderer!.setClearColor(
      three.Color.fromHex32(settings.clearColor), 
      settings.clearAlpha
    );
    renderer!.autoClearDepth = settings.autoClearDepth;
    renderer!.autoClearStencil = settings.autoClearStencil;
    renderer!.outputEncoding = three.sRGBEncoding;
    renderer!.localClippingEnabled = settings.localClippingEnabled;
    renderer!.clippingPlanes = settings.clippingPlanes;

    if(!kIsWeb){
      final WebGLRenderTargetOptions pars = WebGLRenderTargetOptions(settings.renderOptions);
      renderTarget = WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
    else{
      renderTarget = null;
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

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": settings.alpha,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
      'precision': 'highp'
    };
    await three3dRender.initialize(options: options);

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
  }

  Widget threeDart() {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: Builder(builder: (BuildContext context) {
        initSize(context);
        return Stack(
          children:[
            Container(
              width: screenSize!.width,
              height: screenSize!.height,
              color: Theme.of(context).canvasColor,
              child: three.Peripherals(
                key: globalKey,
                builder: (BuildContext context) {
                  return Container(
                    width: width,
                    height: height,
                    color: Theme.of(context).canvasColor,
                    child: Builder(builder: (BuildContext context) {
                      if (kIsWeb) {
                        return three3dRender.isInitialized? HtmlElementView(viewType:three3dRender.textureId!.toString()):Container();
                      } 
                      else {
                        return three3dRender.isInitialized?Texture(textureId: three3dRender.textureId!):Container();
                      }
                    })
                  );
                }
              ),
            ),
          ]
        );
      })
    );
  }
}