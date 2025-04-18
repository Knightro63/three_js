@JS('THREE')
import '../math/index.dart';

import './index.dart';
import '../cameras/index.dart';
import 'dart:js_interop';

@JS('Raycaster')
class Raycaster {
  external Ray ray;
  external double near;
  external double far;
  external Camera camera;
  external Layers layers;
  external Map<String, dynamic> params;

  external Raycaster([Vector3? origin, Vector3? direction, double? near, double? far]);
  external int ascSort(Intersection a, Intersection b);

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
  external void set(Vector3 origin, Vector3 direction);
  external void setFromCamera(Vector2 coords, Camera camera);
  external List<Intersection> intersectObject(Object3D object, [bool recursive = false, List<Intersection>? intersects]);
  external List<Intersection> intersectObjects(List<Object3D> objects, bool recursive, [List<Intersection>? intersects]);
  external void dispose();
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
