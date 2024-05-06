import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// [MeshDistanceMaterial] is internally used for implementing shadow mapping with
/// [PointLight]s.
///
/// Can also be used to customize the shadow casting of an object by assigning
/// an instance of [MeshDistanceMaterial] to [customDistanceMaterial]. The
/// following examples demonstrates this approach in order to ensure
/// transparent parts of objects do no cast shadows.
class MeshDistanceMaterial extends Material {
  late Vector3 referencePosition;
  late num nearDistance;
  late num farDistance;

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
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

  /// Return a new material with the same parameters as this material.
  @override
  MeshDistanceMaterial clone() {
    return MeshDistanceMaterial(<MaterialProperty, dynamic>{}).copy(this);
  }

  /// Copy the parameters from the passed material into this material.
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
