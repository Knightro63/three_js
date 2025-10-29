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

  double _dispersion = 0;
	double get dispersion => _dispersion;
	set dispersion(double value ) {
		if (_dispersion > 0 != value > 0 ) {
			version ++;
		}
		_dispersion = value;
	}

  double iridescenceIOR = 1.3;
  List<double> iridescenceThicknessRange = [ 100, 400 ];
  double _iridescence = 0;
	double get iridescence => _iridescence;
	set iridescence(double value ) {
		if (_iridescence > 0 != value > 0 ) {
			version ++;
		}
		_iridescence = value;
	}

  double _anisotropy = 0;
	double get anisotropy => _anisotropy;
	set anisotropy(double value ) {
		if (_anisotropy > 0 != value > 0 ) {
			version ++;
		}
		_anisotropy = value;
	}
  double anisotropyRotation = 0;

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
    type = 'MeshPhysicalMaterial';

		this.anisotropyRotation = 0;
		this.anisotropyMap = null;

		this.clearcoatMap = null;
		this.clearcoatRoughness = 0.0;
		this.clearcoatRoughnessMap = null;
		this.clearcoatNormalScale = new Vector2( 1, 1 );
		this.clearcoatNormalMap = null;
		this.iridescenceMap = null;
		this.iridescenceIOR = 1.3;
		this.iridescenceThicknessRange = [ 100, 400 ];
		this.iridescenceThicknessMap = null;

		this.sheenColor = new Color( 0x000000 );
		this.sheenColorMap = null;
		this.sheenRoughness = 1.0;
		this.sheenRoughnessMap = null;

		this.transmissionMap = null;

		this.thickness = 0;
		this.thicknessMap = null;
		this.attenuationDistance = double.infinity;
		this.attenuationColor = new Color( 1, 1, 1 );

		this.specularIntensity = 1.0;
		this.specularIntensityMap = null;
		this.specularColor = new Color( 1, 1, 1 );
		this.specularColorMap = null;

    sheenColor = Color.fromHex32( 0x000000 );

    ior = 1.5;
    dispersion = 0;

    defines = {'STANDARD': '', 'PHYSICAL': ''};

		_anisotropy = 0;
		clearcoat = 0;
		_dispersion = 0;
		_iridescence = 0;
		sheen = 0.0;
		transmission = 0;
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
    return MeshPhysicalMaterial()..copy(this);
  }
  @override
  MeshPhysicalMaterial copy(Material source) {
    super.copy(source);

    defines = {'STANDARD': '', 'PHYSICAL': ''};
    if(source is MeshPhysicalMaterial){
      anisotropy = source.anisotropy;
      anisotropyRotation = source.anisotropyRotation;
      anisotropyMap = source.anisotropyMap;
      dispersion = source.dispersion;

      iridescence = source.iridescence;
      iridescenceMap = source.iridescenceMap;
      iridescenceIOR = source.iridescenceIOR;
      iridescenceThicknessRange = [ ...source.iridescenceThicknessRange ];
      iridescenceThicknessMap = source.iridescenceThicknessMap;
    }

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
