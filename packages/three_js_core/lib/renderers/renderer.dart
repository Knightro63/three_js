import 'package:three_js_math/three_js_math.dart';
import 'xr_manager.dart';
import '../cameras/camera.dart';
import '../core/object_3d.dart';
import 'render_target.dart';

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
  late XRManager xr;
  int toneMapping = NoToneMapping;
  double toneMappingExposure = 1.0;
  int get coordinateSystem => WebGLCoordinateSystem;
  
  String _outputColorSpace = SRGBColorSpace;
  String get outputColorSpace => _outputColorSpace;
	set outputColorSpace(String colorSpace )=>setOutputColorSpace(colorSpace);

  void setOutputColorSpace(String colorSpace ) {
    _outputColorSpace = colorSpace;
  }
  void dispose();
  void clear([bool color = true, bool depth = true, bool stencil = true]);
  void render(Object3D scene, Camera camera);
  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]);
  RenderTarget? getRenderTarget();
}
