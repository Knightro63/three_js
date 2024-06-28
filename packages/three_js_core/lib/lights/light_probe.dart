import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light.dart';

/// Light probes are an alternative way of adding light to a 3D scene. Unlike
/// classical light sources (e.g. directional, point or spot lights), light
/// probes do not emit light. Instead they store information about light
/// passing through 3D space. During rendering, the light that hits a 3D
/// object is approximated by using the data from the light probe.
/// 
/// Light probes are usually created from (radiance) environment maps. The
/// class [LightProbeGenerator] can be used to create light probes from
/// instances of [CubeTexture] or [WebGLCubeRenderTarget]. However,
/// light estimation data could also be provided in other forms e.g. by WebXR.
/// This enables the rendering of augmented reality content that reacts to
/// real world lighting.
/// 
/// The current probe implementation in three.js supports so-called diffuse
/// light probes. This type of light probe is functionally equivalent to an
/// irradiance environment map.
class LightProbe extends Light {

  /// [sh] - (optional) An instance of
  /// [SphericalHarmonics3].
  /// 
  /// [intensity] - (optional) Numeric value of the light probe's
  /// intensity. Default is `1`.
  LightProbe.create([SphericalHarmonics3? sh, double? intensity]) : super(null, intensity){
    this.sh = sh;
    type = 'LightProbe';
  }
  
  factory LightProbe([SphericalHarmonics3? sh, double? intensity]){
    sh ??= SphericalHarmonics3();
    return LightProbe.create(sh, intensity);
  }
  factory LightProbe.fromJson(Map<String,dynamic> json, [Map<String,dynamic>? rootJson]){
    SphericalHarmonics3 sh3 = SphericalHarmonics3();
    sh3.fromArray(json['sh']);
    return LightProbe.create(sh3, json['intensity']);
  }

  /// Copies the value of [color] and [intensity]
  /// from the [source] light into this one.
  @override
  LightProbe copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    LightProbe source1 = source as LightProbe;
    sh!.copy(source1.sh!);
    return this;
  }

  /// [meta] - object containing metadata such as materials, textures for
  /// objects.
  /// 
  /// Convert the light to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);
    data["object"]['sh'] = sh!.toArray([]);
    return data;
  }
}
