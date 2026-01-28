import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

abstract class ShadowMap {
  final shadowSide = {0: BackSide, 1: FrontSide, 2: DoubleSide};

  late ShaderMaterial shadowMaterialVertical;
  late ShaderMaterial shadowMaterialHorizontal;

  BufferGeometry fullScreenTri = BufferGeometry();

  late Mesh fullScreenMesh;

  bool enabled = false;

  bool autoUpdate = true;
  bool needsUpdate = false;

  int type = PCFShadowMap;
  late ShadowMap scope;

  void dispose();

  void render(List<Light> lights, Object3D scene, Camera camera);
  void vSMPass(LightShadow shadow, Camera camera);

  Material getDepthMaterial(Object3D object, Material material, Light light, double shadowCameraNear, double shadowCameraFar, int type);
  void renderObject(Object3D object, Camera camera, Camera shadowCamera, Light light, int type);
}
