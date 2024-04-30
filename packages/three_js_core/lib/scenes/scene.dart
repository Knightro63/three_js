import '../core/index.dart';
import '../materials/index.dart';

import './fog.dart';

class Scene extends Object3D {
  FogBase? fog;

  Scene() : super(){
    autoUpdate = true; // checked by the renderer
    type = 'Scene';
  }

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
  Scene copy(Object3D source, [bool? recursive]) {
    super.copy(source);

    // if ( source.background !== null ) this.background = source.background.clone();
    // if ( source.environment !== null ) this.environment = source.environment.clone();
    // if ( source.fog !== null ) this.fog = source.fog.clone();

    // if ( source.overrideMaterial !== null ) this.overrideMaterial = source.overrideMaterial.clone();

    // this.autoUpdate = source.autoUpdate;
    // this.matrixAutoUpdate = source.matrixAutoUpdate;

    return this;
  }

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);

    if (fog != null) data["object"]["fog"] = fog!.toJson();

    return data;
  }
}
