import './material.dart';
import 'mesh_standard_material.dart';
import 'package:three_js_math/three_js_math.dart';

/// An extension of the [MeshStandardMaterial], providing more advanced
/// physically-based rendering properties:
/// 
/// <ul>
///   <li>
///     <b>Anisotropy:</b> Ability to represent the anisotropic property of materials 
///     as observable with brushed metals.
///   </li>
///   <li>
///     <b>Clearcoat:</b> Some materials — like car paints, carbon fiber, and
///     wet surfaces — require a clear, reflective layer on top of another layer
///     that may be irregular or rough. Clearcoat approximates this effect,
///     without the need for a separate transparent surface.
///   </li>
///   <li>
///     <b>Iridescence:</b> Allows to render the effect where hue varies 
///     depending on the viewing angle and illumination angle. This can be seen on
///     soap bubbles, oil films, or on the wings of many insects.
///   </li>
///   <li>
///     <b>Physically-based transparency:</b> One limitation of
///     [opacity] is that highly transparent materials
///     are less reflective. Physically-based [transmission] provides a
///     more realistic option for thin, transparent surfaces like glass.
///   </li>
///   <li>
///     <b>Advanced reflectivity:</b> More flexible reflectivity for
///     non-metallic materials.
///   </li>
///   <li>
///     <b>Sheen:</b> Can be used for representing cloth and fabric materials.
///   </li>
/// </ul>
/// 
/// As a result of these complex shading features, MeshPhysicalMaterial has a
/// higher performance cost, per pixel, than other three.js materials. Most
/// effects are disabled by default, and add cost as they are enabled. For
/// best results, always specify an [environment map] when using
/// this material.
class MeshPhysicalMaterial extends MeshStandardMaterial {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material] and
  /// [MeshStandardMaterial]) can be passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
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
