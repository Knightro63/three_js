import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class MeshMatcapMaterial extends Material {
  MeshMatcapMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshMatcapMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    defines = {'MATCAP': ''};

    type = 'MeshMatcapMaterial';

    color = Color.fromHex32(0xffffff); // diffuse

    matcap = null;

    map = null;

    bumpMap = null;
    bumpScale = 1;

    normalMap = null;
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;

    alphaMap = null;

    flatShading = false;

    fog = true;
  }

  @override
  MeshMatcapMaterial copy(Material source) {
    super.copy(source);

    defines = {'MATCAP': ''};

    color.setFrom(source.color);

    matcap = source.matcap;

    map = source.map;

    bumpMap = source.bumpMap;
    bumpScale = source.bumpScale;

    normalMap = source.normalMap;
    normalMapType = source.normalMapType;
    normalScale!.setFrom(source.normalScale!);

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    alphaMap = source.alphaMap;

    flatShading = source.flatShading;

    fog = source.fog;

    return this;
  }
}
