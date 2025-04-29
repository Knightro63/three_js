import 'package:three_js_core/others/index.dart';

import './index.dart';
import '../cameras/index.dart';
import 'package:three_js_math/three_js_math.dart';

/// This class is designed to assist with
/// [raycasting](https://en.wikipedia.org/wiki/Ray_casting). Raycasting is
/// used for mouse picking (working out what objects in the 3d space the mouse
/// is over) amongst other things.
class Raycaster {
  late Ray ray;
  late double near;
  late double far;
  late Camera camera;
  late Layers layers;
  late Map<String, dynamic> params;

  /// [origin] — The origin vector where the ray casts from.
  /// 
  /// [direction] — The direction vector that gives direction to
  /// the ray. Should be normalized.
  /// 
  /// [near] — All results returned are further away than near. Near
  /// can't be negative. Default value is `0`.
  /// 
  /// [far] — All results returned are closer than far. Far can't be
  /// lower than near. Default value is Infinity.
  /// 
  /// This creates a new raycaster object.
  Raycaster([Vector3? origin, Vector3? direction, double? near, double? far]) {
    ray = origin == null || direction == null?Ray():Ray.originDirection(origin, direction);
    // direction is assumed to be normalized (for accurate distance calculations)

    this.near = near ?? 0;
    this.far = far ?? double.infinity;
    layers = Layers();

    params = {
      "Mesh": {},
      "Line": {"threshold": 1.0},
      "Line2": {"threshold": 0.0},
      "LOD": {},
      "Points": {"threshold": 1.0},
      "Sprite": {}
    };
  }

  int ascSort(Intersection a, Intersection b) {
    return a.distance - b.distance >= 0 ? 1 : -1;
  }

  void intersectObject4(Object3D object, Raycaster raycaster, List<Intersection> intersects, bool recursive) {
    if (object.layers.test(raycaster.layers)) {
      object.raycast(raycaster, intersects);
    }

    if (recursive == true) {
      final children = object.children;

      for (int i = 0, l = children.length; i < l; i++) {
        intersectObject4(children[i], raycaster, intersects, true);
      }
    }
  }

  /// [origin] — The origin vector where the ray casts from.
  /// 
  /// [direction] — The normalized direction vector that gives
  /// direction to the ray.
  /// 
  /// Updates the ray with a new origin and direction. Please note that this
  /// method only copies the values from the arguments.
  void set(Vector3 origin, Vector3 direction) {
    // direction is assumed to be normalized (for accurate distance calculations)
    ray.set(origin, direction);
  }

  /// [coords] — 2D coordinates of the mouse, in normalized device
  /// coordinates (NDC)---X and Y components should be between `-1` and `1`.
  /// 
  /// [camera] — camera from which the ray should originate
  /// 
  /// Updates the ray with a new origin and direction.
  void setFromCamera(Vector2 coords, Camera camera) {
    if (camera is PerspectiveCamera) {
      ray.origin.setFromMatrixPosition(camera.matrixWorld);
      ray.direction.setValues(coords.x, coords.y, 0.5);
      ray.direction.unproject(camera);
      ray.direction.sub(ray.origin);
      ray.direction.normalize();
      this.camera = camera;
    } 
    else if (camera is OrthographicCamera) {
      ray.origin.setValues(coords.x, coords.y,(camera.near + camera.far) / (camera.near - camera.far));
      ray.origin.unproject(camera); // set origin in plane of camera
      ray.direction.setValues(0, 0, -1);
      ray.direction.transformDirection(camera.matrixWorld);
      this.camera = camera;
    } 
    else {
      console.error('Raycaster: Unsupported camera type: ${camera.type}');
    }
  }

  /// [object] — The object to check for intersection with the
  /// ray.
  /// 
  /// [recursive] — If true, it also checks all descendants.
  /// Otherwise it only checks intersection with the object. Default is true.
  /// 
  /// [intersects] — (optional) target to set the result.
  /// Otherwise a new [List] is instantiated. If set, you must clear this
  /// list prior to each call (i.e., list.length = 0;).
  /// 
  /// Checks all intersection between the ray and the object with or without the
  /// descendants. Intersections are returned sorted by distance, closest first.
  /// A list of intersections is returned...
  /// 
  /// `Raycaster` delegates to the [raycast] method of the
  /// passed object, when evaluating whether the ray intersects the object or
  /// not. This allows [meshes] to respond differently to ray casting
  /// than [lines] and [pointclouds].
  /// 
  /// *Note* that for meshes, faces must be pointed towards the origin of the
  /// [ray] in order to be detected; intersections of the ray passing
  /// through the back of a face will not be detected. To raycast against both
  /// faces of an object, you'll want to set the [material]'s
  /// [side] property to `DoubleSide`.
  List<Intersection> intersectObject(Object3D object, [bool recursive = false, List<Intersection>? intersects]) {
    final ints = intersects ?? [];
    intersectObject4(object, this, ints, recursive);
    ints.sort(ascSort);
    return ints;
  }

  /// [objects] — The objects to check for intersection with the
  /// ray.
  /// 
  /// [recursive] — If true, it also checks all descendants of the
  /// objects. Otherwise it only checks intersection with the objects. Default
  /// is true.
  /// 
  /// [intersects] — (optional) target to set the result.
  /// Otherwise a new [List] is instantiated. If set, you must clear this
  /// list prior to each call (i.e., list.length = 0;).
  /// 
  /// Checks all intersection between the ray and the objects with or without
  /// the descendants. Intersections are returned sorted by distance, closest
  /// first. Intersections are of the same form as those returned by
  /// [intersectObject].
  List<Intersection> intersectObjects(List<Object3D> objects, bool recursive, [List<Intersection>? intersects]) {
    intersects ??= List<Intersection>.from([]);

    for (int i = 0, l = objects.length; i < l; i++) {
      intersectObject4(objects[i], this, intersects, recursive);
    }

    intersects.sort(ascSort);

    return intersects;
  }

  void dispose(){
    params.clear();
    camera.dispose();
  }
}

class Intersection {
  int? instanceId;
  double distance;
  double? distanceToRay;
  Vector3? point;
  int? index;
  Face? face;
  int? faceIndex;
  Object3D? object;
  Vector2? uv;
  Vector2? uv1;
  Vector3? normal;
  Vector3? barycoord;
  Vector2? uv2;
  int batchId;

  /// [distance] – distance between the origin of the ray and the
  /// intersection
  /// 
  /// [point] – point of intersection, in world coordinates
  /// 
  /// [face] – intersected face
  /// 
  /// [faceIndex] – index of the intersected face
  /// 
  /// [object] – the intersected object
  /// 
  /// [uv] - U,V coordinates at point of intersection
  /// 
  /// [uv2] - Second set of U,V coordinates at point of
  /// intersection
  /// 
  /// [normal] - interpolated normal vector at point of
  /// intersection
  /// 
  /// [instanceId] – The index number of the instance where the ray
  /// intersects the InstancedMesh
  Intersection({
    this.instanceId,
    required this.distance,
    this.distanceToRay,
    this.point,
    this.normal,
    this.index,
    this.face,
    this.faceIndex,
    this.object,
    this.uv,
    this.uv1,
    this.uv2,
    this.barycoord,
    this.batchId = 0
  });

  factory Intersection.fromJson(Map<String, dynamic> json) {
    return Intersection(
      instanceId: json["instanceId"],
      distance: json["distance"],
      distanceToRay: json["distanceToRay"],
      point: json["point"],
      index: json["index"],
      face: json["face"],
      faceIndex: json["faceIndex"],
      object: json["object"],
      uv: json["uv"],
      uv2: json["uv2"],
      uv1: json['uv1'],
      normal: json['normal'],
      barycoord: json['barycoord'],
      batchId: json["batchId"]
    );
  }
}

class Face {
  late int a;
  late int b;
  late int c;
  late Vector3 normal;
  late int materialIndex;

  Face(this.a, this.b, this.c, this.normal, this.materialIndex);

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      json["a"],
      json["b"],
      json["c"],
      json["normal"],
      json["materialIndex"],
    );
  }
}
