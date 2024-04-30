import '../core/index.dart';
import '../materials/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _pointsinverseMatrix = Matrix4.identity();
final _pointsray = Ray();
final _pointssphere = BoundingSphere();
final _position = Vector3.zero();

class Points extends Object3D {
  Points(BufferGeometry geometry, Material? material) {
    type = 'Points';

    this.geometry = geometry;
    this.material = material;

    updateMorphTargets();
  }

  Points.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'Points';
  }

  @override
  Points copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    if (source is Points) {
      material = source.material;
      geometry = source.geometry;
    }
    return this;
  }

  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    final geometry = this.geometry!;
    final matrixWorld = this.matrixWorld;
    final threshold = raycaster.params["Points"].threshold;
    final drawRange = geometry.drawRange;

    // Checking boundingSphere distance to ray

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _pointssphere.setFrom(geometry.boundingSphere!);
    _pointssphere.applyMatrix4(matrixWorld);
    _pointssphere.radius += threshold;

    if (raycaster.ray.intersectsSphere(_pointssphere) == false) return;

    //

    _pointsinverseMatrix..setFrom(matrixWorld)..invert();
    _pointsray..copyFrom(raycaster.ray)..applyMatrix4(_pointsinverseMatrix);

    final localThreshold = threshold / ((scale.x + scale.y + scale.z) / 3);
    final localThresholdSq = localThreshold * localThreshold;

    final index = geometry.index;
    final attributes = geometry.attributes;
    final positionAttribute = attributes["position"];

    if (index != null) {
      final start = math.max(0, drawRange["start"]!);
      final end =
          math.min(index.count, (drawRange["start"]! + drawRange["count"]!));

      for (int i = start, il = end; i < il; i++) {
        final a = index.getX(i)!.toInt();

        _position.fromBuffer(positionAttribute, a.toInt());

        testPoint(_position, a, localThresholdSq, matrixWorld, raycaster,
            intersects, this);
      }
    } else {
      final start = math.max(0, drawRange["start"]!);
      final end = math.min<int>(
          positionAttribute.count, (drawRange["start"]! + drawRange["count"]!));

      for (int i = start, l = end; i < l; i++) {
        _position.fromBuffer(positionAttribute, i);

        testPoint(_position, i, localThresholdSq, matrixWorld, raycaster,
            intersects, this);
      }
    }
  }

  void updateMorphTargets() {
    final geometry = this.geometry;

    if (geometry is BufferGeometry) {
      final morphAttributes = geometry.morphAttributes;
      final keys = morphAttributes.keys.toList();

      if (keys.isNotEmpty) {
        final morphAttribute = morphAttributes[keys[0]];

        if (morphAttribute != null) {
          morphTargetInfluences = [];
          morphTargetDictionary = {};

          for (int m = 0, ml = morphAttribute.length; m < ml; m++) {
            final name = morphAttribute[m].name ?? m.toString();

            morphTargetInfluences!.add(0);
            morphTargetDictionary![name] = m;
          }
        }
      }
    }
    // else {
    //   final morphTargets = geometry.morphTargets;

    //   if (morphTargets != null && morphTargets.length > 0) {
    //     print(
    //         'THREE.Points.updateMorphTargets() does not support THREE.Geometry. Use THREE.BufferGeometry instead.');
    //   }
    // }
  }
}

void testPoint(
  Vector3 point,
  int index,
  double localThresholdSq,
  Matrix4 matrixWorld,
  Raycaster raycaster,
  List<Intersection> intersects,
  Object3D object
) {
  final rayPointDistanceSq = _pointsray.distanceSqToPoint(point);

  if (rayPointDistanceSq < localThresholdSq) {
    final intersectPoint = Vector3.zero();

    _pointsray.closestPointToPoint(point, intersectPoint);
    intersectPoint.applyMatrix4(matrixWorld);

    final distance = raycaster.ray.origin.distanceTo(intersectPoint);

    if (distance < raycaster.near || distance > raycaster.far) return;

    intersects.add(Intersection(
      distance: distance,
      distanceToRay: math.sqrt(rayPointDistanceSq),
      point: intersectPoint,
      index: index,
      object: object
    ));
  }
}
