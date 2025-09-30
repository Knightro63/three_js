import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/renderers/webgl/index.dart';
import 'package:three_js_xr/app/index.dart';
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/renderer/platform/distortion_shader.dart';
import 'package:three_js_xr/renderer/platform/head_pose.dart';
import 'package:three_js_xr/renderer/web/web_xr_controller.dart';

class WebXRWorker extends WebXRManager{
  XRSession? session;
  late final WebGLState state;
  dynamic onAnimationFrameCallback;
  WebGLRenderTarget? renderTargetLeft;
  WebGLRenderTarget? renderTargetRight;

  final WebGLAnimation animation = WebGLAnimation();
  final StereoCamera stereoCamera = StereoCamera();

  final Camera _camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);
  final BufferGeometry _geometry = PlaneGeometry(2,2);
  final ShaderMaterial _mat = ShaderMaterial.fromMap(distortionShader);
  late final Scene _scene = Scene()..add(Mesh(_geometry,_mat));

  late final double width;
  late final double height;
  late final double dpr;
  final HeadPose _pose = HeadPose();

  late final ArrayCamera cameraVR;
  late final PerspectiveCamera cameraL = stereoCamera.cameraL;
  late final PerspectiveCamera cameraR = stereoCamera.cameraR;

  WebXRWorker(super.renderer, super.gl){
    cameraVR = ArrayCamera([ cameraL, cameraR ]);
  }

  void setUpOptions([XROptions? options]){
    options ??= XROptions();

    width = options.width;
    height = options.height;
    dpr = options.dpr;

    _mat.uniforms['k1']['value'] = options.k1;
    _mat.uniforms['k2']['value'] = options.k1;
    _mat.uniforms['eyeTextureOffsetX']['value'] = options.eyeOffset.x.toInt();
    _mat.uniforms['eyeTextureOffsetY']['value'] = options.eyeOffset.y.toInt();
    _mat.uniforms['lensSize']['value'] = options.lensSize;
    _mat.uniforms['type']['value'] = options.distorsionType.index;

    final WebGLRenderTargetOptions pars = WebGLRenderTargetOptions({
      "format": RGBAFormat,
      'colorSpace': SRGBColorSpace,
      "samples": 4
    });

    renderTargetLeft = WebGLRenderTarget((width * dpr)~/2, (height * dpr).toInt(), pars);
    renderer.setRenderTarget(renderTargetLeft);

    renderTargetRight = WebGLRenderTarget((width * dpr)~/2, (height * dpr).toInt(), pars);
    renderer.setRenderTarget(renderTargetRight);
  }

  @override
  void init(){
    state = renderer.state;
    animation.setAnimationLoop( onAnimationFrame );
  }

  WebXRController? getController (int index ) {
    return null;
  }

  WebXRController? getControllerGrip(int index ) {
    return null;
  }

  WebXRController? getHand(int index ) {
    return null;
  }

  void onSessionEvent(Event event ) {}
  void setReferenceSpace(XRReferenceSpace? space ) {}

  void end(){
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    animation.stop();
  }

  void onSessionEnd(Event event) {
    end();
    isPresenting = false;
    dispatchEvent(Event(type: 'sessionend'));
    onXRSessionEnd?.call();
  }

  void onSessionStarted() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    onXRSessionStart?.call();
  }

  @override
  void updateCamera(Camera camera ) {}

  Future<void> render(Scene scene, Camera camera, FlutterAngleTexture texture, [double? dt]) async{
    final width = texture.options.width.toDouble();
    final height = texture.options.height.toDouble();
    
    if(!enabled || !isPresenting){
      texture.activate();
      renderer.clear();
      renderer.setViewport(0,0,width,height);
      renderer.setRenderTarget(null);
      renderer.render(scene, camera);
      await texture.signalNewFrameAvailable();
      return;
    }

    if ( scene.matrixWorldAutoUpdate == true ) scene.updateMatrixWorld();
    if ( camera.parent == null && camera.matrixWorldAutoUpdate == true ) camera.updateMatrixWorld();
    _pose.update(camera);
    stereoCamera.update( camera );

    renderer.setRenderTarget(renderTargetLeft);
    renderer.render(scene, stereoCamera.cameraL);

    renderer.setRenderTarget(renderTargetRight);
    renderer.render(scene, stereoCamera.cameraR);

    texture.activate();

    final currentAutoClear = renderer.autoClear;
    renderer.autoClear = false;
    renderer.setScissorTest( true );
    
    renderer.setRenderTarget(null);
    renderer.setScissor( 0, 0, width/2, height);
    renderer.setViewport(0, 0, width/2, height);
    _mat.uniforms['tDiffuse']['value'] = renderTargetLeft?.texture;
    renderer.render(_scene, _camera);
    
    renderer.setRenderTarget(null);
    renderer.setScissor( width / 2, 0, width / 2, height);
    renderer.setViewport(width / 2, 0, width / 2, height);
    _mat.uniforms['tDiffuse']['value'] = renderTargetRight?.texture;
    renderer.render(_scene, _camera);

    renderer.setScissorTest( false );
    renderer.autoClear = currentAutoClear;

    await texture.signalNewFrameAvailable();
  }

  Future<void> setSession (XRSession? value ) async{
    session = value;

    if ( session != null ) {
      session?.addEventListener( 'select', onSessionEvent );
      session?.addEventListener( 'selectstart', onSessionEvent );
      session?.addEventListener( 'selectend', onSessionEvent );
      session?.addEventListener( 'squeeze', onSessionEvent );
      session?.addEventListener( 'squeezestart', onSessionEvent );
      session?.addEventListener( 'squeezeend', onSessionEvent );
      session?.addEventListener( 'end', onSessionEnd );
      session?.addEventListener( 'inputsourceschange', onInputSourcesChange );

      animation.setContext( session );
      animation.start();

      isPresenting = true;
      onSessionStarted();
      dispatchEvent( Event(type: 'sessionstart' ) );
    }
  }

  XRReferenceSpace? getReferenceSpace () {
    return null;
  }

  void setReferenceSpaceType(String value ) {}
  void onInputSourcesChange(Event event ) {}
  void onAnimationFrame(double time, frame ) {
    if ( onAnimationFrameCallback != null) onAnimationFrameCallback( time, frame );
  }

  @override
  void setAnimationLoop ( callback ) {
    onAnimationFrameCallback = callback;
  }

  @override
  void dispose(){
    end();
    _scene.dispose();
    _mat.dispose();
    _camera.dispose();
    _geometry.dispose();
    _pose.dispose();
    renderTargetLeft?.dispose();
    renderTargetRight?.dispose();
  }
}
