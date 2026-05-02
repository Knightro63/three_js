import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

enum RenderType{after,before,custom}
enum PowerPreference{high,defaultp,low;

  String get name => _name();
  String _name(){
    if(index == 0){
      return 'high-performance';
    }
    else if(index == 2){
      return 'low-power';
    }
    else{
      return 'default';
    }
  }
}

enum Precision{highp,mediump,lowp}

abstract class Renderer {
  bool autoClear = true;
  bool autoClearColor = true;
  bool autoClearDepth = true;
  bool autoClearStencil = true;
  bool sortObjects = true;

  late XRManager xr;
  late ShadowMap shadowMap;
  late Capabilities capabilities;
  late State state;

  int toneMapping = NoToneMapping;
  double toneMappingExposure = 1.0;
  int get coordinateSystem => WebGLCoordinateSystem;
  
  String _outputColorSpace = SRGBColorSpace;
  String get outputColorSpace => _outputColorSpace;
	set outputColorSpace(String colorSpace )=>setOutputColorSpace(colorSpace);
  
  double getTargetPixelRatio();
  Vector2 getSize(Vector2 target);
  dynamic getContext();
  double getPixelRatio();

  double getClearAlpha();
  void setClearAlpha(double alpha);

  void setViewport(double x, double y, double width, double height);
  Vector4 getViewport(Vector4 target);
  Vector4 getCurrentViewport(Vector4 target);

  void setOutputColorSpace(String colorSpace ) {
    _outputColorSpace = colorSpace;
  }
  void dispose();
  void clear([bool color = true, bool depth = true, bool stencil = true]);
  void clearColor() {
    clear(true, false, false);
  }
  void clearDepth() {
    clear(false, true, false);
  }
  void clearStencil() {
    clear(false, false, true);
  }
  void setClearColor(Color color, [double alpha = 1.0]);
  Color getClearColor(Color target);
  void setPixelRatio(double value);
  void setSize(double width, double height, [bool updateStyle = false]);
  void setRenderTargetFramebuffer(RenderTarget renderTarget, defaultFramebuffer);
  void setRenderTargetTextures(RenderTarget renderTarget, colorTexture, depthTexture);
  void setScissorTest(bool boolean);
  void setScissor(double x, double y, double width, double height);
  void render(Object3D scene, Camera camera);
  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]);
  void readRenderTargetPixels(RenderTarget renderTarget, int x, int y, int width, int height, TypedData buffer, [int? activeCubeFaceIndex]) ;
  void copyFramebufferToTexture(Vector? position, Texture? texture, {int level = 0});
  void renderBufferDirect(Camera camera,Object3D? scene,BufferGeometry geometry,Material material,Object3D object,Map<String, dynamic>? group);
  RenderTarget? getRenderTarget();
}
