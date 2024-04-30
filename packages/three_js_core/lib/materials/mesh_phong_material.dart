import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class MeshPhongMaterial extends Material {
  MeshPhongMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshPhongMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    bumpScale = 1;
    shininess = 30;
    specular = Color(0.067, 0.067, 0.067);
    color = Color(1, 1, 1); // diffuse

    type = "MeshPhongMaterial";
    emissive = Color(0, 0, 0);
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);

    map = null;

    lightMap = null;
    lightMapIntensity = 1.0;

    aoMap = null;
    aoMapIntensity = 1.0;

    emissiveIntensity = 1.0;
    emissiveMap = null;

    normalMap = null;

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;

    specularMap = null;

    alphaMap = null;

    // this.envMap = null;
    combine = MultiplyOperation;
    reflectivity = 1;
    refractionRatio = 0.98;

    wireframe = false;
    wireframeLinewidth = 1;
    wireframeLinecap = 'round';
    wireframeLinejoin = 'round';

    fog = true;
  }

  @override
  MeshPhongMaterial clone() {
    return MeshPhongMaterial(<MaterialProperty, dynamic>{}).copy(this);
  }

  @override
  MeshPhongMaterial copy(Material source) {
    super.copy(source);

    color.setFrom(source.color);
    specular!.setFrom(source.specular!);
    shininess = source.shininess;

    map = source.map;

    lightMap = source.lightMap;
    lightMapIntensity = source.lightMapIntensity;

    aoMap = source.aoMap;
    aoMapIntensity = source.aoMapIntensity;

    emissive!.setFrom(source.emissive!);
    emissiveMap = source.emissiveMap;
    emissiveIntensity = source.emissiveIntensity;

    bumpMap = source.bumpMap;
    bumpScale = source.bumpScale;

    normalMap = source.normalMap;
    normalMapType = source.normalMapType;
    normalScale!.setFrom(source.normalScale!);

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    specularMap = source.specularMap;

    alphaMap = source.alphaMap;

    envMap = source.envMap;
    combine = source.combine;
    reflectivity = source.reflectivity;
    refractionRatio = source.refractionRatio;

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;
    wireframeLinecap = source.wireframeLinecap;
    wireframeLinejoin = source.wireframeLinejoin;
    flatShading = source.flatShading;

    fog = source.fog;

    return this;
  }
}
