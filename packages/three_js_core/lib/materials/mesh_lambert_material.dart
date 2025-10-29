import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A material for non-shiny surfaces, without specular highlights.
///
/// The material uses a non-physically based
/// [Lambertian](https://en.wikipedia.org/wiki/Lambertian_reflectance)
/// model for calculating reflectance. This can simulate some surfaces (such
/// as untreated wood or stone) well, but cannot simulate shiny surfaces with
/// specular highlights (such as varnished wood). [MeshLambertMaterial] uses per-fragment
/// shading.
///
/// Due to the simplicity of the reflectance and illumination models,
/// performance will be greater when using this material over the
/// [MeshPhongMaterial], [MeshStandardMaterial] or
/// [MeshPhysicalMaterial], at the cost of some graphical accuracy.
class MeshLambertMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
  MeshLambertMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshLambertMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    type = "MeshLambertMaterial";

    color = Color.fromHex32(0xffffff); // diffuse

    map = null;
    envMapRotation = Euler();

    lightMap = null;
    lightMapIntensity = 1.0;

    aoMap = null;
    aoMapIntensity = 1.0;

    emissive = Color(0, 0, 0);
    emissiveIntensity = 1.0;
    emissiveMap = null;

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

  /// Return a new material with the same parameters as this material.
  @override
  MeshLambertMaterial clone() {
    return MeshLambertMaterial()..copy(this);
  }
  
  /// Copy the parameters from the passed material into this material.
  @override
  MeshLambertMaterial copy( Material source ) {
    super.copy( source );
		color.setFrom( source.color );
		map = source.map;
		lightMap = source.lightMap;
		lightMapIntensity = source.lightMapIntensity;
		aoMap = source.aoMap;
		aoMapIntensity = source.aoMapIntensity;
		emissive!.setFrom( source.emissive! );
		emissiveMap = source.emissiveMap;
		emissiveIntensity = source.emissiveIntensity;
		specularMap = source.specularMap;
		alphaMap = source.alphaMap;
		envMap = source.envMap;
    envMapRotation?.copy(source.envMapRotation!);
		combine = source.combine;
		reflectivity = source.reflectivity;
		refractionRatio = source.refractionRatio;
		wireframe = source.wireframe;
		wireframeLinewidth = source.wireframeLinewidth;
		wireframeLinecap = source.wireframeLinecap;
		wireframeLinejoin = source.wireframeLinejoin;
		fog = source.fog;
    
		return this;
  }
}
