import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class MeshDistanceMaterial extends Material {
  late Vector3 referencePosition;
  late num nearDistance;
  late num farDistance;

  MeshDistanceMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshDistanceMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    type = 'MeshDistanceMaterial';

    referencePosition = Vector3.zero();
    nearDistance = 1;
    farDistance = 1000;

    map = null;

    alphaMap = null;

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;
  }

  @override
  MeshDistanceMaterial clone() {
    return MeshDistanceMaterial(<MaterialProperty, dynamic>{}).copy(this);
  }

  @override
  MeshDistanceMaterial copy(Material source) {
    super.copy(source);

    if (source is MeshDistanceMaterial) {
      referencePosition.setFrom(source.referencePosition);
      nearDistance = source.nearDistance;
      farDistance = source.farDistance;
    }

    map = source.map;

    alphaMap = source.alphaMap;

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    return this;
  }
}
