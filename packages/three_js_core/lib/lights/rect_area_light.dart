import '../core/index.dart';
import 'light.dart';

/// RectAreaLight emits light uniformly across the face a rectangular plane.
/// This light type can be used to simulate light sources such as bright
/// windows or strip lighting.
///
/// Important Notes:
/// <ul>
///   <li>There is no shadow support.</li>
///   <li>
///     Only [page:MeshStandardMaterial MeshStandardMaterial] and
///     [page:MeshPhysicalMaterial MeshPhysicalMaterial] are supported.
///   </li>
///   <li>
///     You have to include
///     [RectAreaLightUniformsLib](https://threejs.org/examples/jsm/lights/RectAreaLightUniformsLib.js) into your scene and call `init()`.
///   </li>
/// </ul>
/// 
/// ```
/// const width = 10;
/// const height = 10;
/// const intensity = 1;
/// final rectLight = RectAreaLight( 0xffffff, intensity,  width, height );
/// rectLight.position.setValues( 5, 5, 0 );
/// rectLight.lookAt( 0, 0, 0 );
/// scene.add( rectLight )
///
/// final rectLightHelper = RectAreaLightHelper( rectLight );
/// rectLight.add( rectLightHelper );
/// ```
class RectAreaLight extends Light {
  /// [color] - (optional) hexadecimal color of the light. Default
  /// is 0xffffff (white).
  /// 
  /// [intensity] - (optional) the light's intensity, or brightness.
  /// Default is `1`.
  /// 
  /// [ width] - (optional) width of the light. Default is `10`.
  /// 
  /// [height] - (optional) height of the light. Default is `10`.
  RectAreaLight([super.color, super.intensity, double? width, double? height]){
    type = 'RectAreaLight';

    this.width = width ?? 10;
    this.height = height ?? 10;
    isRectAreaLight = true;
  }

  /// Copies value of all the properties from the [source] to
  /// this RectAreaLight.
  @override
  RectAreaLight copy(Object3D source, [bool? recursive]) {
    super.copy(source);

    RectAreaLight source1 = source as RectAreaLight;

    width = source1.width;
    height = source1.height;

    return this;
  }

  /// [meta] - object containing metadata such as materials, textures for
  /// objects.
  /// 
  /// Convert the light to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String,dynamic> toJson({Object3dMeta? meta}) {
    Map<String,dynamic> data = super.toJson(meta: meta);

    data["object"]["width"] = width;
    data["object"]["height"] = height;

    return data;
  }
}
