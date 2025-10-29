import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A material for drawing geometry by depth. Depth is based off of the camera
/// near and far plane. White is nearest, black is farthest.
class MeshDepthMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
  MeshDepthMaterial([Map<MaterialProperty, dynamic>?parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshDepthMaterial.fromMap([Map<String, dynamic>?parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }

  void _init(){
    type = "MeshDepthMaterial";
    depthPacking = BasicDepthPacking;
    displacementScale = 1.0;
    displacementBias = 0;
    wireframe = false;
    wireframeLinewidth = 1;

    displacementMap = null;
  }
  
  /// Copy the parameters from the passed material into this material.
  @override
  MeshDepthMaterial copy(Material source) {
    super.copy(source);

    depthPacking = source.depthPacking;

    map = source.map;

    alphaMap = source.alphaMap;

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;

    return this;
  }

  /// Return a new material with the same parameters as this material.
  @override
  MeshDepthMaterial clone() {
    return MeshDepthMaterial()..copy(this);
  }
}
