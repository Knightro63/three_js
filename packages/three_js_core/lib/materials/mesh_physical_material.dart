import './material.dart';
import 'mesh_standard_material.dart';
import 'package:three_js_math/three_js_math.dart';

class MeshPhysicalMaterial extends MeshStandardMaterial {
  MeshPhysicalMaterial([Map<MaterialProperty, dynamic>? parameters]) : super(parameters) {
    _init();
    setValues(parameters);
  }
  MeshPhysicalMaterial.fromMap([Map<String, dynamic>? parameters]):super.fromMap(parameters) {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    clearcoatRoughness = 0.0;
    type = 'MeshPhysicalMaterial';
    clearcoatNormalScale = Vector2(1, 1);
    thickness = 0.0;
    attenuationColor = Color(1, 1, 1);
    attenuationDistance = 0.0;
    specularIntensity = 1.0;
    specularColor = Color(1, 1, 1);
    ior = 1.5;

    defines = {'STANDARD': '', 'PHYSICAL': ''};

  }

  @override
  double get reflectivity {
    return (MathUtils.clamp(2.5 * (ior! - 1) / (ior! + 1), 0, 1));
  }

  @override
  set reflectivity(double? value){
    value ??= 0;
    ior = (1 + 0.4 * value) / (1 - 0.4 * value);
  }
  @override
  MeshPhysicalMaterial clone() {
    return MeshPhysicalMaterial(<MaterialProperty, dynamic>{}).copy(this);
  }
  @override
  MeshPhysicalMaterial copy(Material source) {
    super.copy(source);

    defines = {'STANDARD': '', 'PHYSICAL': ''};

    clearcoat = source.clearcoat;
    clearcoatMap = source.clearcoatMap;
    clearcoatRoughness = source.clearcoatRoughness;
    clearcoatRoughnessMap = source.clearcoatRoughnessMap;
    clearcoatNormalMap = source.clearcoatNormalMap;
    clearcoatNormalScale!.setFrom(source.clearcoatNormalScale!);

    ior = source.ior;

    if (source.sheenColor != null) {
      sheenColor!.setFrom(source.sheenColor!);
    } else {
      sheenColor = null;
    }

    sheenColorMap = source.sheenColorMap;
    sheenRoughness = source.sheenRoughness;
    sheenRoughnessMap = source.sheenRoughnessMap;

    transmission = source.transmission;
    transmissionMap = source.transmissionMap;

    thickness = source.thickness;
    thicknessMap = source.thicknessMap;

    attenuationColor!.setFrom(source.attenuationColor!);
    attenuationDistance = source.attenuationDistance;

    specularIntensity = source.specularIntensity;
    specularIntensityMap = source.specularIntensityMap;
    specularColor!.setFrom(source.specularColor!);
    specularColorMap = source.specularColorMap;

    return this;
  }
}
