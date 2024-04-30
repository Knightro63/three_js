import './index.dart';
import '../cameras/index.dart';
import 'package:three_js_math/three_js_math.dart';

class Raycaster {
  late Ray ray;
  late double near;
  late double far;
  late Camera camera;
  late Layers layers;
  late Map<String, dynamic> params;

  Raycaster([Vector3? origin, Vector3? direction, double? near, double? far]) {
    ray = origin == null || direction == null?Ray():Ray.originDirection(origin, direction);
    // direction is assumed to be normalized (for accurate distance calculations)

    this.near = near ?? 0;
    this.far = far ?? double.infinity;
    layers = Layers();

    params = {
      "Mesh": {},
      "Line": {"threshold": 1},
      "LOD": {},
      "Points": {"threshold": 1},
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

  void set(Vector3 origin, Vector3 direction) {
    // direction is assumed to be normalized (for accurate distance calculations)
    ray.set(origin, direction);
  }

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
      print('THREE.Raycaster: Unsupported camera type: ${camera.type}');
    }
  }

  List<Intersection> intersectObject(Object3D object, bool recursive,[List<Intersection>? intersects]) {
    final ints = intersects ?? [];
    intersectObject4(object, this, ints, recursive);
    ints.sort(ascSort);
    return ints;
  }

  List<Intersection> intersectObjects(List<Object3D> objects, bool recursive, [List<Intersection>? intersects]) {
    intersects = intersects ?? List<Intersection>.from([]);

    for (int i = 0, l = objects.length; i < l; i++) {
      intersectObject4(objects[i], this, intersects, recursive);
    }

    intersects.sort(ascSort);

    return intersects;
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
  Vector2? uv2;

  Intersection({
    this.instanceId,
    required this.distance,
    this.distanceToRay,
    this.point,
    this.index,
    this.face,
    this.faceIndex,
    this.object,
    this.uv,
    this.uv2
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
      uv2: json["uv2"]
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
