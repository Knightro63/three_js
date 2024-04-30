import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class MeshDepthMaterial extends Material {
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

  @override
  MeshDepthMaterial clone() {
    return MeshDepthMaterial().copy(this);
  }
}
