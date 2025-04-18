import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A material that maps the normal vectors to RGB colors.
class MeshNormalMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
  MeshNormalMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshNormalMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    type = "MeshNormalMaterial";
    bumpScale = 1;
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);
    displacementScale = 1;
    displacementBias = 0;
    wireframe = false;
    wireframeLinewidth = 1;
  }

  @override
  MeshNormalMaterial copy(Material source) {
    super.copy(source);
    bumpScale = source.bumpScale;
    normalMapType = source.normalMapType;
    normalScale = source.normalScale;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;
    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;

    return this;
  }
}
