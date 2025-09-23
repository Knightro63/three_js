import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart' as tmath;
import './distortion_shader.dart';

enum DistorsionType{pincushion,barrel}

/// coreJs utility class. If you want to learn how to connect cannon.js with js, please look at the examples/corejs_* instead.
class VrViewer{
  void Function() onSetupComplete;
  VrViewer({
    core.Settings? settings,
    required this.onSetupComplete, 
    required this.setup,
    this.loadingWidget,
    double eyeSep = 0.064,
    this.k1 = 0.20, // Adjust for desired distortion
    this.k2 = 0.02 , // Adjust for desired distortion
    tmath.Vector2? lensSize,
    tmath.Vector2? eyeOffset,
    this.distorsionType = DistorsionType.barrel
  }){
    this.lensSize = lensSize ?? tmath.Vector2(0.9,0.9);
    this.eyeOffset = eyeOffset ?? tmath.Vector2(0,0);
    this.settings = settings ?? core.Settings();
    stereoCamera.eyeSep = eyeSep;

    _mat.uniforms['k1']['value'] = k1;
    _mat.uniforms['k2']['value'] = k1;
    _mat.uniforms['eyeTextureOffsetX']['value'] = this.eyeOffset.x;
    _mat.uniforms['eyeTextureOffsetY']['value'] = this.eyeOffset.y;
    _mat.uniforms['lensSize']['value'] = this.lensSize;
    _mat.uniforms['type']['value'] = distorsionType.index;
  }
  double k1;
  double k2;
  late tmath.Vector2 lensSize;
  late tmath.Vector2 eyeOffset;
  DistorsionType distorsionType;

  Timer? _debounceTimer;

  Widget? loadingWidget;
  late final core.Settings settings;
  final GlobalKey<core.PeripheralsState> globalKey = GlobalKey<core.PeripheralsState>();
  core.PeripheralsState get domElement => globalKey.currentState!;

  bool visible = true;

  tmath.FlutterAngleTexture? texture;
  tmath.RenderingContext? gl;

  core.WebGLRenderTarget? renderTargetLeft;
  core.WebGLRenderTarget? renderTargetRight;
  core.WebGLRenderer? renderer;
  final core.Clock clock = core.Clock();

  late final core.Scene scene;
  late final core.Camera camera;
  final core.StereoCamera stereoCamera = core.StereoCamera();
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

  FutureOr<void> Function()? setup;
  List<Function(double dt)> events = [];
  List<Function()> disposeEvents = [];

  tmath.FlutterAngle? angle = tmath.FlutterAngle();

  void addAnimationEvent(Function(double dt) event){
    events.add(event);
  }
  void toDispose(Function() event){
    disposeEvents.add(event);
  }

  void dispose(){
    if(_disposed) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,overlays: SystemUiOverlay.values);
    _disposed = true;
    _debounceTimer?.cancel(); // Cancel timer if active
    _debounceTimer = null;
    ticker?.dispose();
    ticker = null;
    renderer?.dispose();
    renderer = null;
    renderTargetLeft?.dispose();
    renderTargetRight?.dispose();
    renderTargetLeft = null;
    renderTargetRight = null;
    scene.dispose();
    for(final event in disposeEvents){
      event.call();
    }
    
    stereoCamera.dispose();
    events.clear();
    disposeEvents.clear();

    tmath.allNativeData.dispose();

    angle?.dispose([texture]);
    loadingWidget = null;
    screenSize = null;
    setup = null;

    _scene.dispose();
    _mat.dispose();
    _camera.dispose();
    _geometry.dispose();
  }

  void initSize(BuildContext context){
    if (screenSize != null) {
      return;
    }
    
    final mqd = MediaQuery.of(context);
    screenSize = mqd.size;
    _resolution ??= mqd.devicePixelRatio;

    initPlatformState();
  }
  
  Future<void> animate(Duration duration) async {
    if (!mounted || _disposed || updating || !isVisibleOnScreen || !visible) {
      return;
    }
    _updating = true;
    double dt = clock.getDelta();
    
    if(settings.animate){
      await render(dt);
      if(!pause){
        for(int i = 0; i < events.length;i++){
          events[i].call(dt);
        }
      }
    }
    _updating = false;
  }

  final core.Camera _camera = core.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  final core.BufferGeometry _geometry = core.PlaneGeometry(2,2);
  final core.ShaderMaterial _mat = core.ShaderMaterial.fromMap(distortionShader);
  late final core.Scene _scene = core.Scene()..add(core.Mesh(_geometry,_mat));

  Future<void> render([double? dt]) async{
    if ( scene.matrixWorldAutoUpdate == true ) scene.updateMatrixWorld();
    if ( camera.parent == null && camera.matrixWorldAutoUpdate == true ) camera.updateMatrixWorld();

    stereoCamera.update(camera);

    renderer!.setRenderTarget(renderTargetLeft);
    renderer!.render(scene, stereoCamera.cameraL);

    renderer!.setRenderTarget(renderTargetRight);
    renderer!.render(scene, stereoCamera.cameraR);

    angle!.activateTexture(texture!);
    final currentAutoClear = renderer!.autoClear;
    renderer!.autoClear = false;
    renderer?.setScissorTest( true );
    
    renderer!.setRenderTarget(null);
    renderer!.setScissor( 0, 0, width/2, height);
    renderer!.setViewport(0.5, 0, width/2, height);
    _mat.uniforms['tDiffuse']['value'] = renderTargetLeft?.texture;
    renderer!.render(_scene, _camera);
    
    renderer!.setRenderTarget(null);
    renderer!.setScissor( width / 2, 0, width / 2, height);
    renderer!.setViewport(width / 2-0.5, 0, width / 2, height);
    _mat.uniforms['tDiffuse']['value'] = renderTargetRight?.texture;
    renderer!.render(_scene, _camera);

    renderer?.setScissorTest( false );
    renderer!.autoClear = currentAutoClear;
    await angle?.updateTexture(texture!);
  }
  
  void initRenderer() {
    core.WebGLRendererParameters options = core.WebGLRendererParameters(
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
      tmath.Color.fromHex32(settings.clearColor), 
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

    final core.WebGLRenderTargetOptions pars = core.WebGLRenderTargetOptions(settings.renderOptions);

    renderTargetLeft = core.WebGLRenderTarget((width * _resolution!)~/2, (height * _resolution!).toInt(), pars);
    renderer!.setRenderTarget(renderTargetLeft);

    renderTargetRight = core.WebGLRenderTarget((width * _resolution!)~/2, (height * _resolution!).toInt(), pars);
    renderer!.setRenderTarget(renderTargetRight);
  }
  Future<void> initScene() async{
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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
    final options = tmath.AngleOptions(
      width: width.toInt(), 
      height: height.toInt(), 
      dpr: _resolution!,
      alpha: settings.alpha,
      antialias: settings.antialias,
      customRenderer: true,
      useSurfaceProducer: true
    );
    if(texture == null){
      await angle?.init();
      texture = await angle?.createTexture(options);
      core.console.info(texture?.toMap());
      gl= texture!.getContext();
    }
  
    await initScene();
  }

  Widget viewer(int? textureId, BuildContext context){
    if (kIsWeb) {
      return textureId != null && mounted? SizedBox(
          width: width,
          height: height,
          child:HtmlElementView(viewType:textureId.toString())
        ):loadingWidget ?? Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).canvasColor,
        alignment: Alignment.center,
        child: const CircularProgressIndicator()
      );
    } 
    else {
      return textureId != null && mounted?
        SizedBox(
          width: width,
          height: height,
          child: Transform.scale(
            scaleY: Platform.isAndroid?1:-1,
            child:Texture(textureId: textureId)
          )
        ):loadingWidget ?? Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Theme.of(context).canvasColor,
          alignment: Alignment.center,
          child: const CircularProgressIndicator()
        );
    }
  }

  Widget build() {
    return  Builder(builder: (BuildContext context) {
      initSize(context);
      return core.Peripherals(
        key: globalKey,
        builder: (BuildContext context) {
          return viewer(texture?.textureId, context);
        }
      );
    });
  }
}