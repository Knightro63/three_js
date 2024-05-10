import 'dart:convert';
import '../others/console.dart';
import 'package:three_js_math/three_js_math.dart';
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

int _object3DId = 0;

Vector3 _v1 = Vector3.zero();
Quaternion _q1 = Quaternion(0,0,0,1);
Matrix4 m1 = Matrix4.identity();
Vector3 _target = Vector3.zero();

Vector3 _position = Vector3.zero();
Vector3 _scale = Vector3.zero();
Quaternion _quaternion = Quaternion(0,0,0,1);

Vector3 _xAxis = Vector3(1, 0, 0);
Vector3 _yAxis = Vector3(0, 1, 0);
Vector3 _zAxis = Vector3(0, 0, 1);

Event _addedEvent = Event(type: "added");
Event _removedEvent = Event(type: "removed");

/// This is the base class for most objects in three.js and provides a set of
/// properties and methods for manipulating objects in 3D space.
///
/// Note that this can be used for grouping objects via the [add] method which adds the object as a child, however it is better to
/// use [Group] for this.
class Object3D with EventDispatcher {
  static Vector3 defaultUp = Vector3(0.0, 1.0, 0.0);
  static bool defaultMatrixAutoUpdate = true;

  int id = _object3DId++;

  String uuid = MathUtils.generateUUID();

  String? tag;

  String name = '';
  String type = 'Object3D';

  Object3D? parent;
  List<Object3D> children = [];

  bool castShadow = false;

  bool autoUpdate = false; // checked by the renderer

  Matrix4 matrix = Matrix4.identity();
  Matrix4 matrixWorld = Matrix4.identity();

  bool matrixAutoUpdate = Object3D.defaultMatrixAutoUpdate;
  bool matrixWorldNeedsUpdate = false;

  Layers layers = Layers();
  bool visible = true;
  bool receiveShadow = false;

  bool frustumCulled = true;
  int renderOrder = 0;

  // List<AnimationClip> animations = [];

  bool isImmediateRenderObject = false;

  Map<String, dynamic> userData = {};

  Map<String, dynamic> extra = {};

  BufferGeometry? geometry;

  Vector3 up = Object3D.defaultUp.clone();

  Vector3 position = Vector3(0, 0, 0);
  Euler rotation = Euler(0, 0, 0);
  Quaternion quaternion = Quaternion(0,0,0,1);
  Vector3 scale = Vector3(1, 1, 1);
  Matrix4 modelViewMatrix = Matrix4.identity();
  Matrix3 normalMatrix = Matrix3.identity();

  // how to handle material is a single material or List<Material>
  Material? material;

  List<double>? morphTargetInfluences;
  Map<String,dynamic>? morphTargetDictionary;

  // InstancedMesh
  int? count;

  Matrix4? bindMatrix;
  Skeleton? skeleton;

  Material? overrideMaterial;
  Material? customDistanceMaterial;

  ///  *
	///  * Custom depth material to be used when rendering to the depth map. Can only be used in context of meshes.
	///  * When shadow-casting with a DirectionalLight or SpotLight, if you are (a) modifying vertex positions in
	///  * the vertex shader, (b) using a displacement map, (c) using an alpha map with alphaTest, or (d) using a
	///  * transparent texture with alphaTest, you must specify a customDepthMaterial for proper shadows.
	///  *
  Material? customDepthMaterial;

  // onBeforeRender({WebGLRenderer? renderer, scene, Camera? camera, RenderTarget? renderTarget, dynamic? geometry, Material? material, dynamic group}) {
  // print(" Object3D.onBeforeRender ${type} ${id} ");
  // }
  Function? onBeforeRender;

  dynamic background;
  Texture? environment;

  InstancedBufferAttribute? instanceMatrix;
  BufferAttribute? instanceColor;
  /// The constructor takes no arguments.
  Object3D() {
    init();
  }

  Object3D.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson) {
    uuid = json["uuid"];
    if (json["name"] != null) {
      name = json["name"]!;
    }
    type = json["type"];
    layers.mask = json["layers"];

    position = Vector3(json["position"][0],json["position"][1],json["position"][2]);
    quaternion = Quaternion(json["quaternion"][0],json["quaternion"][1],json["quaternion"][2],json["quaternion"][3]);
    scale = Vector3(json["scale"][0],json["scale"][1],json["scale"][2]);

    if (json["geometry"] != null) {
      List<BufferGeometry>? geometries = rootJson["geometries"];

      if (geometries != null) {
        BufferGeometry geometry = geometries.firstWhere((element) => element.uuid == json["geometry"]);
        this.geometry = geometry;
      }
    }

    if (json["material"] != null) {
      List<Material>? materials = rootJson["materials"];

      if (materials != null) {
        Material material = materials.firstWhere((element) => element.uuid == json["material"]);
        this.material = material;
      }
    }

    init();

    if (json["children"] != null) {
      List<Map<String, dynamic>> children = json["children"];
      for (Map<String, dynamic> child in children) {
        final obj = Object3D.castJson(child,rootJson);
        if (obj is Object3D) this.children.add(obj);
      }
    }
  }

  void init() {
    rotation.onChange(onRotationChange);
    quaternion.onChange(onQuaternionChange);
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

  void onRotationChange() {
    quaternion.setFromEuler(rotation);
  }

  void onQuaternionChange() {
    rotation.setFromQuaternion(quaternion);
  }

  /// Applies the matrix transform to the object and updates the object's
  /// position, rotation and scale.
  void applyMatrix4(Matrix4 matrix) {
    if (matrixAutoUpdate) updateMatrix();
    this.matrix.multiply(matrix);
    this.matrix.decompose(position, quaternion, scale);
  }

  /// Applies the rotation represented by the quaternion to the object.
  Object3D applyQuaternion(Quaternion q) {
    quaternion.multiply(q);
    return this;
  }

  /// [axis] - A normalized vector in object space.
  /// 
  /// [angle] - angle in radians
  /// 
  /// Calls [setFromAxisAngle] ([axis], [angle]) on the [quaternion].
  void setRotationFromAxisAngle(Vector3 axis, double angle) {
    // assumes axis is normalized
    quaternion.setFromAxisAngle(axis, angle);
  }

  /// euler -- Euler angle specifying rotation amount.
  /// 
  /// Calls [setRotationFromEuler]
  /// ([euler]) on the [quaternion].
  void setRotationFromEuler(Euler euler) {
    quaternion.setFromEuler(euler, true);
  }

  /// [m] - rotate the quaternion by the rotation component of the matrix.
  /// 
  /// Calls [setFromRotationMatrix]
  /// ([m]) on the [quaternion].
  /// 
  /// Note that this assumes that the upper 3x3 of m is a pure rotation matrix
  /// (i.e, unscaled).
  void setRotationFromMatrix(m) {
    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
    quaternion.setFromRotationMatrix(m);
  }

  /// [q] - normalized Quaternion.
  /// 
  /// Copy the given quaternion into [quaternion].
  void setRotationFromQuaternion(Quaternion q) {
    // assumes q is normalized
    quaternion.setFrom(q);
  }

  /// [axis] -- A normalized vector in object space.
  /// 
  /// [angle] -- The angle in radians.
  /// 
  /// Rotate an object along an axis in object space. The axis is assumed to be
  /// normalized.
  Object3D rotateOnAxis(Vector3 axis, double angle) {
    // rotate object on axis in object space
    // axis is assumed to be normalized
    _q1.setFromAxisAngle(axis, angle);
    quaternion.multiply(_q1);
    return this;
  }

  /// [axis] -- A normalized vector in world space.
  /// 
  /// [angle] -- The angle in radians.
  /// 
  /// Rotate an object along an axis in world space. The axis is assumed to be
  /// normalized. Method Assumes no rotated parent.
  Object3D rotateOnWorldAxis(Vector3 axis, double angle) {
    // rotate object on axis in world space
    // axis is assumed to be normalized
    // method assumes no rotated parent
    _q1.setFromAxisAngle(axis, angle);
    quaternion.multiply(_q1);
    return this;
  }

  /// [angle] - the angle to rotate in radians.
  /// 
  /// Rotates the object around x axis in local space.
  Object3D rotateX(double angle) {
    return rotateOnAxis(_xAxis, angle);
  }

  /// [angle] - the angle to rotate in radians.
  /// 
  /// Rotates the object around y axis in local space.
  Object3D rotateY(double angle) {
    return rotateOnAxis(_yAxis, angle);
  }

  /// [angle] - the angle to rotate in radians.
  /// 
  /// Rotates the object around z axis in local space.
  Object3D rotateZ(double angle) {
    return rotateOnAxis(_zAxis, angle);
  }

  /// [axis] - A normalized vector in object space.
  /// 
  /// [distance] - The distance to translate.
  /// 
  /// Translate an object by distance along an axis in object space. The axis is
  /// assumed to be normalized.
  Object3D translateOnAxis(Vector3 axis, double distance) {
    // translate object by distance along axis in object space
    // axis is assumed to be normalized
    _v1.setFrom(axis);
    _v1.applyQuaternion(quaternion);
    _v1.scale(distance);
    position.add(_v1);
    return this;
  }

  /// Translates object along x axis in object space by `distance` units.
  Object3D translateX(double distance) {
    return translateOnAxis(_xAxis, distance);
  }

  /// Translates object along y axis in object space by `distance` units.
  Object3D translateY(double distance) {
    return translateOnAxis(_yAxis, distance);
  }

  /// Translates object along z axis in object space by `distance` units.
  Object3D translateZ(double distance) {
    return translateOnAxis(_zAxis, distance);
  }

  /// [vector] - A vector representing a position in this object's local space.
  /// 
  /// Converts the vector from this object's local space to world space.
  Vector3 localToWorld(Vector3 vector) {
    vector.applyMatrix4(matrixWorld);
    return vector;
  }

  /// [vector] - A vector representing a position in world space.
  /// 
  /// Converts the vector from world space to this object's local space.
  Vector3 worldToLocal(Vector3 vector) {
    m1.setFrom(matrixWorld);
    m1.invert();
    vector.applyMatrix4(m1);
    return vector;
  }

  /// [vector] - A vector representing a position in world space.
  /// Optionally, the [x], [y] and [z] components of the
  /// world space position.
  /// 
  /// Rotates the object to face a point in world space.
  /// 
  /// This method does not support objects having non-uniformly-scaled
  /// parent(s).
  void lookAt(Vector3 position) {
    // This method does not support objects having non-uniformly-scaled parent(s)

    _target.setFrom(position);

    final parent = this.parent;

    updateWorldMatrix(true, false);

    _position.setFromMatrixPosition(matrixWorld);

    if (this is Camera || this is Light) {
      m1.lookAt(_position, _target, up);
    } else {
      m1.lookAt(_target, _position, up);
    }

    quaternion.setFromRotationMatrix(m1);


    if (parent != null) {
      m1.extractRotation(parent.matrixWorld);
      _q1.setFromRotationMatrix(m1);
      _q1.conjugate();
      quaternion.multiply(_q1);
    }
  }

  /// Adds list `objects` as child of this object.
  Object3D addAll(List<Object3D> objects) {
    for (int i = 0; i < objects.length; i++) {
      add(objects[i]);
    }

    return this;
  }

  /// Adds `object` as child of this object. An arbitrary number of objects may
  /// be added. Any current parent on an object passed in here will be removed,
  /// since an object can have at most one parent.
  /// 
  /// See [Group] for info on manually grouping objects.
  Object3D add(Object3D? object) {
    if (object == this) {
      console.warning('Object3D.add: object can\'t be added as a child of itself. $object');
      return this;
    }

    if (object != null) {
      if (object.parent != null) {
        object.parent!.remove(object);
      }

      object.parent = this;
      children.add(object);

      object.dispatchEvent(_addedEvent);
    } 
    else {
      console.warning('Object3D.add: object not an instance of THREE.Object3D. $object');
    }

    return this;
  }

  /// Removes list of `objects` from this object.
  Object3D removeList(List<Object3D> objects) {
    for (int i = 0; i < objects.length; i++) {
      remove(objects[i]);
    }

    return this;
  }

  /// Removes `object` as child of this object. An arbitrary number of objects
  /// may be removed.
  Object3D remove(Object3D object) {
    final index = children.indexOf(object);

    if (index != -1) {
      object.parent = null;
      children.removeAt(index);

      object.dispatchEvent(_removedEvent);
    }

    return this;
  }

  /// Removes this object from its current parent.
  Object3D removeFromParent() {
    final parent = this.parent;

    if (parent != null) {
      parent.remove(this);
    }

    return this;
  }

  /// Removes all child objects.
  Object3D clear() {
    for (int i = 0; i < children.length; i++) {
      final object = children[i];

      object.parent = null;

      object.dispatchEvent(_removedEvent);
    }

    children.length = 0;

    return this;
  }

  Object3D attach(Object3D object) {
    // adds object as a child of this, while maintaining the object's world transform

    updateWorldMatrix(true, false);

    m1.setFrom(matrixWorld);
    m1.invert();

    if (object.parent != null) {
      object.parent!.updateWorldMatrix(true, false);
      m1.multiply(object.parent!.matrixWorld);
    }

    object.applyMatrix4(m1);
    add(object);
    object.updateWorldMatrix(false, false);

    return this;
  }

  /// id -- Unique number of the object instance
  /// 
  /// Searches through an object and its children, starting with the object
  /// itself, and returns the first with a matching id.
  /// 
  /// Note that ids are assigned in chronological order: 1, 2, 3, ...,
  /// incrementing by one for each new object.
  Object3D? getObjectById(String id) {
    return getObjectByProperty('id', id);
  }

  /// [name] -- String to match to the children's Object3D.name property.
  ///
  ///
  /// Searches through an object and its children, starting with the object
  /// itself, and returns the first with a matching name
  /// 
  /// Note that for most objects the name is an empty string by default. You
  /// will have to set it manually to make use of this method.
  Object3D? getObjectByName(String name) {
    return getObjectByProperty('name', name);
  }

  /// [name] -- the property name to search for.
  /// 
  /// [value] -- value of the given property.
  /// 
  /// Searches through an object and its children, starting with the object
  /// itself, and returns the first with a property that matches the value
  /// given.
  Object3D? getObjectByProperty(String name, String value) {
    if (getProperty(name) == value) return this;

    for (int i = 0, l = children.length; i < l; i++) {
      final child = children[i];
      final object = child.getObjectByProperty(name, value);
      if (object != null) {
        return object;
      }
    }

    return null;
  }

  /// [target] — the result will be copied into this Vector3.
  ///
  /// Returns a vector representing the position of the object in world space.
  Vector3 getWorldPosition(Vector3? target) {
    if (target == null) {
      console.error('Object3D: .getWorldPosition() target is now required');
      target = Vector3.zero();
    }

    updateWorldMatrix(true, false);
    target.setFromMatrixPosition(matrixWorld);
    return target;
  }

  /// [target] — the result will be copied into this Quaternion.
  /// 
  /// Returns a quaternion representing the rotation of the object in world
  /// space.
  Quaternion getWorldQuaternion(Quaternion target) {
    updateWorldMatrix(true, false);
    matrixWorld.decompose(_position, target, _scale);
    return target;
  }

  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns a vector of the scaling factors applied to the object for each
  /// axis in world space.
  Vector3 getWorldScale(Vector3 target) {
    updateWorldMatrix(true, false);
    matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }

  /// [target] — the result will be copied into this Vector3.
  /// 
  /// 
  /// Returns a vector representing the direction of object's positive z-axis in
  /// world space.
  Vector3 getWorldDirection(Vector3 target) {
    updateWorldMatrix(true, false);
    final e = matrixWorld.storage;
    target.setValues(e[8], e[9], e[10]);
    target.normalize();
    return target;
  }

  /// Abstract (empty) method to get intersections between a casted ray and this
  /// object. Subclasses such as [Mesh], [Line], and [Points]
  /// implement this method in order to use raycasting.
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    throw("Object3D not implimented");
  }

  /// [callback] - A function with as first argument an object3D object.
  /// 
  /// Executes the callback on this object and all descendants.
  /// 
  /// Note: Modifying the scene graph inside the callback is discouraged.
  void traverse(Function(Object3D) callback) {
    callback(this);

    final children = this.children;

    for (int i = 0, l = children.length; i < l; i++) {
      children[i].traverse(callback);
    }
  }

  /// [callback] - A function with as first argument an object3D object.
  /// 
  /// Like traverse, but the callback will only be executed for visible objects.
  /// Descendants of invisible objects are not traversed.
  /// 
  /// Note: Modifying the scene graph inside the callback is discouraged.
  void traverseVisible(Function(Object3D?) callback) {
    if (visible == false) return;

    callback(this);

    final children = this.children;

    for (int i = 0, l = children.length; i < l; i++) {
      children[i].traverseVisible(callback);
    }
  }

  /// [callback] - A function with as first argument an object3D object.
  /// 
  /// Executes the callback on all ancestors.
  /// 
  /// Note: Modifying the scene graph inside the callback is discouraged.
  void traverseAncestors(Function(Object3D?) callback) {
    final parent = this.parent;

    if (parent != null) {
      callback(parent);

      parent.traverseAncestors(callback);
    }
  }

  /// Updates the local transform.
  void updateMatrix() {
    matrix.compose(position, quaternion, scale);
    matrixWorldNeedsUpdate = true;
  }

  /// [force] - A boolean that can be used to bypass
  /// [matrixWorldAutoUpdate], to recalculate the world matrix of the
  /// object and descendants on the current frame. Useful if you cannot wait for
  /// the renderer to update it on the next frame (assuming
  /// [matrixWorldAutoUpdate] set to `true`).
  /// 
  /// Updates the global transform of the object and its descendants if the
  /// world matrix needs update ([matrixWorldNeedsUpdate] set to true) or
  /// if the `force` parameter is set to `true`.
  void updateMatrixWorld([bool force = false]) {
    if (matrixAutoUpdate) updateMatrix();

    if (matrixWorldNeedsUpdate || force) {
      if (parent == null) {
        matrixWorld.setFrom(matrix);
      } else {
        matrixWorld.multiply2(parent!.matrixWorld, matrix);
      }

      matrixWorldNeedsUpdate = false;

      force = true;
    }

    // update children

    List<Object3D> children = this.children;

    for (int i = 0, l = children.length; i < l; i++) {
      children[i].updateMatrixWorld(force);
    }
  }

  /// [updateParents] - recursively updates global transform of ancestors.
  /// 
  /// [updateChildren] - recursively updates global transform of descendants.
  /// 
  /// Updates the global transform of the object.
  void updateWorldMatrix(bool updateParents, bool updateChildren) {
    final parent = this.parent;

    if (updateParents == true && parent != null) {
      parent.updateWorldMatrix(true, false);
    }

    if (matrixAutoUpdate) updateMatrix();

    if (this.parent == null) {
      matrixWorld.setFrom(matrix);
    } else {
      matrixWorld.multiply2(this.parent!.matrixWorld, matrix);
    }

    // update children

    if (updateChildren == true) {
      final children = this.children;

      for (int i = 0, l = children.length; i < l; i++) {
        children[i].updateWorldMatrix(false, true);
      }
    }
  }

  /// meta -- object containing metadata such as materials, textures or images
  /// for the object.
  /// 
  /// Convert the object to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    // meta is a string when called from JSON.stringify
    final isRootObject = (meta == null || meta is String);

    Map<String, dynamic> output = <String, dynamic>{};

    // meta is a hash used to collect geometries, materials.
    // not providing it implies that this is the root object
    // being serialized.
    if (isRootObject) {
      // initialize meta obj
      meta = Object3dMeta();

      output["metadata"] = {
        "version": 4.5,
        "type": 'Object',
        "generator": 'Object3D.toJson'
      };
    }

    // standard Object3D serialization

    Map<String, dynamic> object = <String, dynamic>{};

    object["uuid"] = uuid;
    object["type"] = type;

    if (name != "") object["name"] = name;
    if (castShadow == true) object["castShadow"] = true;
    if (receiveShadow == true) object["receiveShadow"] = true;
    if (visible == false) object["visible"] = false;
    if (frustumCulled == false) object["frustumCulled"] = false;
    if (renderOrder != 0) object["renderOrder"] = renderOrder;
    if (userData.isNotEmpty) object["userData"] = userData;

    object["layers"] = layers.mask;
    object["matrix"] = matrix.storage;//toArray(List<double>.filled(16, 0.0))

    if (matrixAutoUpdate == false) object["matrixAutoUpdate"] = false;

    // object specific properties

    if (type == "InstancedMesh") {
      InstancedMesh instanceMesh = this as InstancedMesh;

      object["type"] = 'InstancedMesh';
      object["count"] = instanceMesh.count;
      object["instanceMatrix"] = instanceMesh.instanceMatrix!.toJson();

      if (instanceMesh.instanceColor != null) {
        object["instanceColor"] = instanceMesh.instanceColor!.toJson();
      }
    }

    if (this is Scene) {
      if (background != null) {
        if (background is Color) {
          object["background"] = background!.getHex();
        } else if (background is Texture) {
          object["background"] = background.toJson(meta).uuid;
        }
      }

      if (environment != null && environment is Texture) {
        object["environment"] = environment!.toJson(meta)['uuid'];
      }
    } else if (this is Mesh || this is Line || this is Points) {
      object["geometry"] = serialize(meta.geometries, geometry, meta);

      final parameters = geometry!.parameters;

      if (parameters != null && parameters["shapes"] != null) {
        final shapes = parameters["shapes"];

        if (shapes is List) {
          for (int i = 0, l = shapes.length; i < l; i++) {
            final shape = shapes[i];

            serialize(meta.shapes, shape, meta);
          }
        } else {
          serialize(meta.shapes, shapes, meta);
        }
      }
    }

    // if ( this.type == "SkinnedMesh" ) {

    //   SkinnedMesh _skinnedMesh = this;

    // 	object["bindMode"] = _skinnedMesh.bindMode;
    // 	object["bindMatrix"] = _skinnedMesh.bindMatrix.toArray();

    // 	if ( _skinnedMesh.skeleton != null ) {

    // 		serialize( meta.skeletons, _skinnedMesh.skeleton );

    // 		object.skeleton = _skinnedMesh.skeleton.uuid;

    // 	}

    // }

    if (material != null) {
      List<String> uuids = [];

      if (material is GroupMaterial) {
        for (int i = 0, l = (material as GroupMaterial).children.length; i < l; i++) {
          uuids.add(serialize(meta.materials, (material as GroupMaterial).children[i], meta));
        }

        object["material"] = uuids;
      } else {
        object["material"] = serialize(meta.materials, material, meta);
      }
    }

    if (children.isNotEmpty) {
      List<Map<String, dynamic>> childrenJSON = [];

      for (int i = 0; i < children.length; i++) {
        childrenJSON.add(children[i].toJson(meta: meta)["object"]);
      }

      object["children"] = childrenJSON;
    }


    // if ( this.animations.length > 0 ) {

    // 	List<Map<String, dynamic>> _animationJSON = [];

    // 	for ( int i = 0; i < this.animations.length; i ++ ) {

    // 		const animation = this.animations[ i ];

    // 		_animationJSON.add( serialize( meta.animations, animation ) );

    // 	}

    //   object["animations"] = _animationJSON;

    // }

    if (isRootObject) {
      final geometries = extractFromCache(meta.geometries);
      final materials = extractFromCache(meta.materials);
      final textures = extractFromCache(meta.textures);
      final images = extractFromCache(meta.images);
      final shapes = extractFromCache(meta.shapes);
      final skeletons = extractFromCache(meta.skeletons);
      final animations = extractFromCache(meta.animations);
      
      console.info("isRootObject: $isRootObject ");

      if (geometries.isNotEmpty) output["geometries"] = geometries;
      if (materials.isNotEmpty) output["materials"] = materials;
      if (textures.isNotEmpty) output["textures"] = textures;
      if (images.isNotEmpty) output["images"] = images;
      if (shapes.isNotEmpty) output["shapes"] = shapes;
      if (skeletons.isNotEmpty) output["skeletons"] = skeletons;
      if (animations.isNotEmpty) output["animations"] = animations;
    }

    output["object"] = object;

    return output;
  }

  String serialize(Map<String, dynamic> library, dynamic element, Object3dMeta? meta) {
    if (library[element.uuid] == null) {
      library[element.uuid] = element.toJson(meta: meta);
    }

    return element.uuid;
  }

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

  /// [recursive] -- if true, descendants of the object are also cloned. Default
  /// is true.
  /// 
  /// Returns a clone of this object and optionally all descendants.
  Object3D clone([bool? recursive]) {
    return Object3D().copy(this, recursive);
  }

  /// [recursive] -- If set to `true`, descendants of the object are copied next to the existing ones. 
  /// If set to `false`, descendants are left unchanged. Default is `true`.
  /// 
  /// Copies the given object into this object. Note: Event listeners and
  /// user-defined callbacks ([onAfterRender] and [onBeforeRender])
  /// are not copied.
  Object3D copy(Object3D source, [bool? recursive = true]) {
    recursive = recursive ?? true;

    name = source.name;

    up.setFrom(source.up);

    position.setFrom(source.position);
    rotation.order = source.rotation.order;
    quaternion.setFrom(source.quaternion);
    scale.setFrom(source.scale);

    matrix.setFrom(source.matrix);
    matrixWorld.setFrom(source.matrixWorld);

    matrixAutoUpdate = source.matrixAutoUpdate;
    matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;

    layers.mask = source.layers.mask;
    visible = source.visible;

    castShadow = source.castShadow;
    receiveShadow = source.receiveShadow;

    frustumCulled = source.frustumCulled;
    renderOrder = source.renderOrder;

    userData = json.decode(json.encode(source.userData));

    if (recursive == true) {
      for (int i = 0; i < source.children.length; i++) {
        final child = source.children[i];
        add(child.clone());
      }
    }

    return this;
  }

  /// An optional callback that is executed immediately after a 3D object is
  /// rendered. This function is called with the following parameters: renderer,
  /// scene, camera, geometry, material, group.
  /// 
  /// Please notice that this callback is only executed for `renderable` 3D
  /// objects. Meaning 3D objects which define their visual appearance with
  /// geometries and materials like instances of [Mesh], [Line],
  /// [Points] or [Sprite]. Instances of [Object3D], [Group]
  /// or [Bone] are not renderable and thus this callback is not executed
  /// for such objects.
  void onAfterRender({
    WebGLRenderer? renderer,
      Object3D? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Material? material,
      Map<String, dynamic>? group
    }) {
    // print(" Object3D.onAfterRender ${type} ${id} ");
  }

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

  void dispose() {}
}

class Object3dMeta {
  Map<String, dynamic> geometries = <String, dynamic>{};
  Map<String, dynamic> materials = <String, dynamic>{};
  Map<String, dynamic> textures = <String, dynamic>{};
  Map<String, dynamic> images = <String, dynamic>{};
  Map<String, dynamic> shapes = <String, dynamic>{};
  Map<String, dynamic> skeletons = <String, dynamic>{};
  Map<String, dynamic> animations = <String, dynamic>{};
}
