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
    this.alpha = false
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
  late Map<String,dynamic> renderOptions;
}

/**
 * Demo utility class. If you want to learn how to connect cannon.js with three.js, please look at the examples/threejs_* instead.
 */
class Demo{
  void Function() onSetupComplete;
  Demo({
    DemoSettings? settings,
    required this.onSetupComplete, 
    this.rendererUpdate,
    required this.fileName,
    required this.setup
  }){
    this.settings = settings ?? DemoSettings();
  }

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

  late void Function()? rendererUpdate;
  late FutureOr<void> Function()? setup;
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
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
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
    final _gl = three3dRender.gl;
    rendererUpdate?.call();
    renderer!.render(scene, camera);
    _gl.flush();
    if(!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }
  void initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
      "alpha": settings.alpha
    };

    if(!kIsWeb){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = settings.enableShadowMap;
    renderer!.shadowMap.type = three.PCFShadowMap;
    renderer!.autoClear = settings.autoClear;

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
    await setup?.call();
    initRenderer();
    // setupWorld();
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