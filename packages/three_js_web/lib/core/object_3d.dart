@JS('THREE')
import 'dart:js_interop';
import '../others/console.dart';
import '../math/index.dart';
import '../materials/index.dart';
import '../textures/index.dart';
import '../objects/index.dart';
import '../cameras/index.dart';
import '../lights/index.dart';
import '../scenes/index.dart';
import '../renderers/index.dart';
import '../geometries/buffer_geometry.dart';
import 'event_dispatcher.dart';
import './layers.dart';
import './raycaster.dart';

typedef OnRender = void Function({
  WebGLRenderer? renderer,
  RenderTarget? renderTarget,
  Object3D? mesh,
  Scene? scene,
  Camera? camera,
  BufferGeometry? geometry,
  Material? material,
  Map<String, dynamic>? group
});


@JS('Object3D')
class Object3D with EventDispatcher {
  external BoundingSphere? boundingSphere;
  external static Vector3 defaultUp;
  external static bool defaultMatrixAutoUpdate;
  external static bool defaultMatrixWorldAutoUpdate;

  external int id;

  external String uuid;
  external String? tag;
  external String name;
  String type = 'Object3D';

  external Object3D? parent;
  external List<Object3D> children;

  external bool castShadow;
  external bool autoUpdate; // checked by the renderer

  external Matrix4 matrix;
  external Matrix4 matrixWorld;

  bool matrixAutoUpdate = Object3D.defaultMatrixAutoUpdate;
  bool matrixWorldAutoUpdate = Object3D.defaultMatrixWorldAutoUpdate;
  external bool matrixWorldNeedsUpdate;

  external Layers layers;
  external bool visible;
  external bool receiveShadow;

  external bool frustumCulled;
  external int renderOrder;

  // List<AnimationClip> animations = [];

  external bool isImmediateRenderObject;

  external Map<String, dynamic> userData;
  external Map<String, dynamic> extra;

  external BufferGeometry? geometry;
  external Vector3 up;

  external Vector3 position;
  external Euler rotation;
  external Quaternion quaternion;
  external Vector3 scale;
  external Matrix4 modelViewMatrix;
  external Matrix3 normalMatrix;

  // how to handle material is a single material or List<Material>
  external Material? material;

  external List<double> morphTargetInfluences ;
  external Map<String,dynamic>? morphTargetDictionary;

  // InstancedMesh
  external int? count;

  external Matrix4? bindMatrix;
  external Skeleton? skeleton;

  external Material? overrideMaterial;
  external Material? customDistanceMaterial;

  ///  *
	///  * Custom depth material to be used when rendering to the depth map. Can only be used in context of meshes.
	///  * When shadow-casting with a DirectionalLight or SpotLight, if you are (a) modifying vertex positions in
	///  * the vertex shader, (b) using a displacement map, (c) using an alpha map with alphaTest, or (d) using a
	///  * transparent texture with alphaTest, you must specify a customDepthMaterial for proper shadows.
	///  *
  external Material? customDepthMaterial;

  // onBeforeRender({WebGLRenderer? renderer, scene, Camera? camera, RenderTarget? renderTarget, dynamic? geometry, Material? material, dynamic group}) {
  // print(" Object3D.onBeforeRender ${type} ${id} ");
  // }
  external OnRender? onBeforeRender;

  external dynamic background;
  external Texture? environment;

  external InstancedBufferAttribute? instanceMatrix;
  external BufferAttribute? instanceColor;
  /// The constructor takes no arguments.
  external Object3D();

  Object3D.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson) {
    Object3D();
  }

  static EventDispatcher castJson(Map<String, dynamic> json, Map<String,dynamic> rootJson) {
    String? type = json["type"];

    if (type == null) {
      Map<String, dynamic>? object = json["object"];
      if (object != null) {
        type = object["type"];
        json = object;
        console.warning("object is not null use object as json type: $type ");
      }
    }

    if (type == "Camera") {
      return Camera.fromJson(json,rootJson);
    } else if (type == "PerspectiveCamera") {
      return PerspectiveCamera.fromJson(json,rootJson);
    } else if (type == "Scene") {
      return Scene.fromJson(json,rootJson);
    } else if (type == "PointLight") {
      return PointLight.fromJson(json,rootJson);
    } else if (type == "Group") {
      return Group.fromJson(json,rootJson);
    } else if (type == "Mesh") {
      return Mesh.fromJson(json,rootJson);
    } else if (type == "Line") {
      return Line.fromJson(json,rootJson);
    } else if (type == "Points") {
      return Points.fromJson(json,rootJson);
    } else if (type == "AmbientLight") {
      return AmbientLight.fromJson(json,rootJson);
    } else if (type == "Sprite") {
      return Sprite.fromJson(json,rootJson);
    } else if (type == "SpriteMaterial") {
      return SpriteMaterial.fromJson(json,rootJson);
    } 
    // else if (type == "ShapeGeometry") {
    //   return ShapeGeometry.fromJson(json);
    // } 
    else {
      throw " type: $type Object3D.castJson is not support yet... ";
    }
  }

  external void onRotationChange();
  external void onQuaternionChange();
  external void applyMatrix4(Matrix4 matrix);
  external Object3D applyQuaternion(Quaternion q);
  external void setRotationFromAxisAngle(Vector3 axis, double angle);
  external void setRotationFromEuler(Euler euler);
  external void setRotationFromMatrix(m);
  external void setRotationFromQuaternion(Quaternion q);

  external Object3D rotateOnAxis(Vector3 axis, double angle);
  external Object3D rotateOnWorldAxis(Vector3 axis, double angle);
  external Object3D rotateX(double angle);
  external Object3D rotateY(double angle);
  external Object3D rotateZ(double angle);

  external Object3D translateOnAxis(Vector3 axis, double distance);
  external Object3D translateX(double distance);
  external Object3D translateY(double distance);
  external Object3D translateZ(double distance);
  external Vector3 localToWorld(Vector3 vector);
  external Vector3 worldToLocal(Vector3 vector);
  external void lookAt(Vector3 position);

  /// Adds list `objects` as child of this object.
  Object3D addAll(List<Object3D> objects) {
    for (int i = 0; i < objects.length-1; i++) {
      add(objects[i]);
    }

    return add(objects.last);
  }

  external Object3D add(Object3D? object);

  /// Removes list of `objects` from this object.
  Object3D removeList(List<Object3D> objects) {
    for (int i = 0; i < objects.length-1; i++) {
      remove(objects[i]);
    }

    return remove(objects.last);
  }

  external Object3D remove(Object3D object);
  external Object3D removeFromParent();
  external Object3D clear();
  external Object3D attach(Object3D object);
  external Object3D? getObjectById(String id);
  external Object3D? getObjectByName(String name);
  external Object3D? getObjectByProperty(String name, String value);
  external Vector3 getWorldPosition(Vector3? target);
  external Quaternion getWorldQuaternion(Quaternion target);
  external Vector3 getWorldScale(Vector3 target);
  external Vector3 getWorldDirection(Vector3 target);

  /// Abstract (empty) method to get intersections between a casted ray and this
  /// object. Subclasses such as [Mesh], [Line], and [Points]
  /// implement this method in order to use raycasting.
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    throw("Object3D not implimented");
  }

  external void traverse(Function(Object3D) callback);

  external void traverseVisible(Function(Object3D?) callback);
  external void traverseAncestors(Function(Object3D?) callback);
  external void updateMatrix();
  external void updateMatrixWorld([bool force = false]);
  external void updateWorldMatrix(bool updateParents, bool updateChildren);

  void computeBoundingSphere(){
    throw('Object3D.computeBoundingSphere is Not implimented!');
  }

  external Map<String,dynamic> toJSON(Map<String,dynamic>? meta);
  Map<String, dynamic> toJson({Object3dMeta? meta}){
    return toJSON(meta?.toJson());
  }

  external String serialize(Map<String, dynamic> library, dynamic element, Object3dMeta? meta);

  // extract data from the cache hash
  // remove metadata on each item
  // and return as array
  List<Map<String, dynamic>> extractFromCache(Map<String, dynamic> cache) {
    List<Map<String, dynamic>> values = [];
    for (String key in cache.keys) {
      Map<String, dynamic> data = cache[key];
      data.remove("metadata");

      values.add(data);
    }

    return values;
  }


  external Object3D clone([bool? recursive]);
  external Object3D copy(Object3D source, [bool? recursive = true]);
  external OnRender? onAfterRender;

  OnRender? customRender;

  external void onBeforeShadow({
    WebGLRenderer? renderer,
    Object3D? scene,
    Camera? camera,
    Camera? shadowCamera,
    BufferGeometry? geometry,
    Material? material,
    Map<String, dynamic>? group
  });

  external void onAfterShadow({
    WebGLRenderer? renderer,
    Object3D? scene,
    Camera? camera,
    Camera? shadowCamera,
    BufferGeometry? geometry,
    Material? material,
    Map<String, dynamic>? group
  });

  Matrix4? getValue(String name) {
    if (name == "bindMatrix") {
      return bindMatrix;
    } else {
      throw ("Object3D.getValue type: $type name: $name is not support .... ");
    }
  }

  dynamic getProperty(String propertyName) {
    if (propertyName == "id") {
      return id;
    } else if (propertyName == "name") {
      return name;
    } else if (propertyName == "scale") {
      return scale;
    } else if (propertyName == "position") {
      return position;
    } else if (propertyName == "quaternion") {
      return quaternion;
    } else if (propertyName == "material") {
      return material;
    } else if (propertyName == "opacity") {
      return null;
    } else if (propertyName == "morphTargetInfluences") {
      return morphTargetInfluences;
    } else if (propertyName == "castShadow") {
      return castShadow;
    } else if (propertyName == "receiveShadow") {
      return receiveShadow;
    } else if (propertyName == "visible") {
      return visible;
    } else {
      throw ("Object3D.getProperty type: $type propertyName: $propertyName is not support ");
    }
  }

  Object3D setProperty(String propertyName, value) {
    if (propertyName == "id") {
      id = value;
    } else if (propertyName == "castShadow") {
      castShadow = value;
    } else if (propertyName == "receiveShadow") {
      receiveShadow = value;
    } else if (propertyName == "visible") {
      visible = value;
    } else if (propertyName == "name") {
      name = value;
    } else if (propertyName == "quaternion") {
      quaternion.setFrom(value);
    } else {
      throw ("Object3D.setProperty type: $type propertyName: $propertyName is not support ");
    }

    return this;
  }

  external void dispose();
}

class Object3dMeta {
  Map<String, dynamic> geometries = <String, dynamic>{};
  Map<String, dynamic> materials = <String, dynamic>{};
  Map<String, dynamic> textures = <String, dynamic>{};
  Map<String, dynamic> images = <String, dynamic>{};
  Map<String, dynamic> shapes = <String, dynamic>{};
  Map<String, dynamic> skeletons = <String, dynamic>{};
  Map<String, dynamic> animations = <String, dynamic>{};

  Map<String,Map<String,dynamic>> toJson(){
    return {
      'geometries': geometries,
      'materials': materials,
      'textures': textures,
      'images': images,
      'shapes': shapes,
      'skeletons': skeletons,
      'animations': animations,
    };
  }
}
