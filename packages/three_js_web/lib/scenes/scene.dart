import '../core/index.dart';
import '../materials/index.dart';
import './fog.dart';
import 'dart:js_interop';

@JS('Scene')
class Scene extends Object3D {
  external FogBase? fog;
  external double backgroundBlurriness;
  external double backgroundIntensity;

  external Euler backgroundRotation;

  external double environmentIntensity;
  external Euler environmentRotation;

  external Scene();

  Scene.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson): super.fromJson(json, rootJson){
    type = 'Scene';
  }

  static Scene initJson(Map<String, dynamic> json) {
    Map<String, dynamic> rootJson = {};

    //List<Shape> shapes = [];
    // List<Map<String, dynamic>> shapesJSON = json["shapes"];
    // for (Map<String, dynamic> shape in shapesJSON) {
    //   shapes.add(Curve.castJson(shape) as Shape);
    // }
    //rootJson["shapes"] = shapes;

    List<BufferGeometry> geometries = [];
    List<Map<String, dynamic>> geometriesJSON = json["geometries"];
    for (Map<String, dynamic> geometry in geometriesJSON) {
      geometries.add(BufferGeometry.castJson(geometry, rootJson));
    }

    List<Material> materials = [];
    List<Map<String, dynamic>> materialsJSON = json["materials"];
    for (Map<String, dynamic> material in materialsJSON) {
      materials.add(Material.fromJson(material, {}));
    }

    rootJson["materials"] = materials;
    rootJson["geometries"] = geometries;

    return Object3D.castJson(json["object"], rootJson) as Scene;
  }

  @override
  external Scene copy(Object3D source, [bool? recursive]);

  /// [meta] - object containing metadata such as textures or images for the scene.
  /// 
  /// Convert the scene to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);

    if (fog != null) data["object"]["fog"] = fog!.toJson();

    return data;
  }
}
