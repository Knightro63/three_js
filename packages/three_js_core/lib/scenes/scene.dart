import 'package:three_js_core/scenes/index.dart';
import '../core/index.dart';
//import '../materials/index.dart';
import 'package:three_js_math/three_js_math.dart';

/// Scenes allow you to set up what and where is to be rendered by three.js.
/// 
/// This is where you place objects, lights and cameras.
class Scene extends Object3D {
  FogBase? fog;
  double backgroundBlurriness = 0;
  double backgroundIntensity = 1;

  Euler backgroundRotation = Euler();

  double environmentIntensity = 1;
  Euler environmentRotation = Euler();

  Scene() : super(){
    autoUpdate = true; // checked by the renderer
    type = 'Scene';
    background = null;
    environment = null;
    fog = null;
  }

  Scene.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson): super.fromJson(json, rootJson){
    type = 'Scene';
  }

  // static Scene initJson(Map<String, dynamic> json) {
  //   Map<String, dynamic> rootJson = {};

  //   //List<Shape> shapes = [];
  //   // List<Map<String, dynamic>> shapesJSON = json["shapes"];
  //   // for (Map<String, dynamic> shape in shapesJSON) {
  //   //   shapes.add(Curve.castJson(shape) as Shape);
  //   // }
  //   //rootJson["shapes"] = shapes;

  //   List<BufferGeometry> geometries = [];
  //   List<Map<String, dynamic>> geometriesJSON = json["geometries"];
  //   for (Map<String, dynamic> geometry in geometriesJSON) {
  //     geometries.add(BufferGeometry.castJson(geometry, rootJson));
  //   }

  //   List<Material> materials = [];
  //   List<Map<String, dynamic>> materialsJSON = json["materials"];
  //   for (Map<String, dynamic> material in materialsJSON) {
  //     materials.add(Material.fromJson(material, {}));
  //   }

  //   rootJson["materials"] = materials;
  //   rootJson["geometries"] = geometries;

  //   return Object3D.castJson(json["object"], rootJson) as Scene;
  // }

  @override
  Scene copy(Object3D source, [bool? recursive]) {
    source as Scene;
    super.copy(source);

    if ( source.background != null ) background = source.background.clone();
    if ( source.environment != null ) environment = source.environment?.clone();
    if ( source.fog != null ) fog = source.fog?.clone();

		this.backgroundBlurriness = source.backgroundBlurriness;
		this.backgroundIntensity = source.backgroundIntensity;
		this.backgroundRotation.copy( source.backgroundRotation );

		this.environmentIntensity = source.environmentIntensity;
		this.environmentRotation.copy( source.environmentRotation );

    if ( source.overrideMaterial != null ) overrideMaterial = source.overrideMaterial?.clone();

    //autoUpdate = source.autoUpdate;
    matrixAutoUpdate = source.matrixAutoUpdate;

    return this;
  }

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

  @override
  dynamic getProperty(String propertyName, [int? offset]) {
    if(propertyName == 'backgroundBlurriness'){
      return backgroundBlurriness;
    }
    else if(propertyName == 'backgroundIntensity'){
      return backgroundIntensity;
    }
    else if(propertyName == 'environmentIntensity'){
      return environmentIntensity;
    }
    else if(propertyName == 'backgroundRotation'){
      return backgroundRotation;
    }
    else if(propertyName == 'environmentRotation'){
      return environmentRotation;
    }
    else if(propertyName == 'fog'){
      return fog;
    }
    return super.getProperty(propertyName, offset);
  }

  @override
  Scene setProperty(String propertyName, dynamic value, [int? offset]){
    if(propertyName == 'backgroundBlurriness'){
      backgroundBlurriness = value.toDouble();
    }
    else if(propertyName == 'backgroundIntensity'){
      backgroundIntensity = value.toDouble();
    }
    else if(propertyName == 'environmentIntensity'){
      environmentIntensity = value.toDouble();
    }
    else if(propertyName == 'backgroundRotation'){
      if(value is List){
        backgroundRotation = Euler().set(value[0].todouble(),value[1].todouble(),value[2].todouble());
        return this;
      }
      backgroundRotation = value;
    }
    else if(propertyName == 'environmentRotation'){
      if(value is List){
        environmentRotation = Euler().set(value[0].todouble(),value[1].todouble(),value[2].todouble());
        return this;
      }
      environmentRotation = value;
    }
    else if(propertyName == 'fog'){
      if(fog is Map<String,dynamic>){
        if(value['type'] == 'Fog'){ 
          fog = Fog.fromJson(value);
          return this;
        }
        fog = FogExp2.fromJson(value);
      }
      fog = value;
    }
    else{
      super.setProperty(propertyName, value);
    }

    return this;
  }
}
