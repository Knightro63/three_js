import 'dart:convert';
import '../core/index.dart';
import '../materials/index.dart';
import 'skinned_mesh.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _meshinverseMatrix = Matrix4.identity();
final _meshray = Ray();
final _meshsphere = BoundingSphere();

final _vA = Vector3.zero();
final _vB = Vector3.zero();
final _vC = Vector3.zero();

final _tempA = Vector3.zero();
final _tempB = Vector3.zero();
final _tempC = Vector3.zero();

final _morphA = Vector3.zero();
final _morphB = Vector3.zero();
final _morphC = Vector3.zero();

final _uvA = Vector2.zero();
final _uvB = Vector2.zero();
final _uvC = Vector2.zero();

final _intersectionPoint = Vector3.zero();
final _intersectionPointWorld = Vector3.zero();

/// Class representing triangular
/// [polygon mesh](https://en.wikipedia.org/wiki/Polygon_mesh) based
/// objects. Also serves as a base for other classes such as
/// [SkinnedMesh].
/// ```
/// final geometry = BoxGeometry( 1, 1, 1 );
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00 } );
/// final mesh = Mesh( geometry, material );
/// scene.add( mesh );
/// ```
class Mesh extends Object3D {
  /// [geometry] — (optional) an instance of
  /// [BufferGeometry]. Default is a new [BufferGeometry].
  /// 
  /// [ material] — (optional) a single or an array of
  /// [Material]. Default is a new [MeshBasicMaterial]
  /// 
  Mesh([BufferGeometry? geometry, Material? material]) : super() {
    this.geometry = geometry ?? BufferGeometry();
    this.material = material;
    type = "Mesh";
    updateMorphTargets();
  }

  Mesh.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = "Mesh";
  }

  /// Returns a clone of this [name] object and its descendants.
  @override
  Mesh clone([bool? recursive = true]) {
    return Mesh(geometry!.clone(), material?.clone()).copy(this, recursive);
  }

  @override
  Mesh copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);
    if (source is Mesh) {
      if (source.morphTargetInfluences.isNotEmpty) {
        morphTargetInfluences = source.morphTargetInfluences.sublist(0);
      }
      if (source.morphTargetDictionary != null) {
        morphTargetDictionary = json.decode(json.encode(source.morphTargetDictionary));
      }
      material = source.material;
      geometry = source.geometry;
    }
    return this;
  }

  /// Updates the morphTargets to have no influence on the object. Resets the
  /// [morphTargetInfluences] and
  /// [morphTargetDictionary] properties.
  void updateMorphTargets() {
    final geometry = this.geometry;

    final morphAttributes = geometry!.morphAttributes;
    final keys = morphAttributes.keys.toList();

    if (keys.isNotEmpty) {
      List<BufferAttribute>? morphAttribute = morphAttributes[keys[0]];

      if (morphAttribute != null) {
        morphTargetInfluences = [];
        morphTargetDictionary = {};

        for (int m = 0, ml = morphAttribute.length; m < ml; m++) {
          String name = morphAttribute[m].name ?? m.toString();

          morphTargetInfluences.add(0.0);
          morphTargetDictionary![name] = m;
        }
      }
    }
  
  }

  /// Get intersections between a casted ray and this mesh.
  /// [Raycaster.intersectObject] will call this method, but the results
  /// are not ordered.
  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    final geometry = this.geometry;
    final material = this.material;
    final matrixWorld = this.matrixWorld;

    if (material == null) return;

    // Checking boundingSphere distance to ray

    if (geometry?.boundingSphere == null) geometry?.computeBoundingSphere();
    
    if(geometry != null){
      _meshsphere.setFrom(geometry.boundingSphere!);
    }
    _meshsphere.applyMatrix4(matrixWorld);

    if (raycaster.ray.intersectsSphere(_meshsphere) == false) return;

    _meshinverseMatrix..setFrom(matrixWorld)..invert();
    _meshray..copyFrom(raycaster.ray)..applyMatrix4(_meshinverseMatrix);

    // Check boundingBox before continuing

    if (geometry?.boundingBox != null) {
      if (!_meshray.intersectsBox(geometry!.boundingBox!)) return;
    }

    Intersection? intersection;
    final index = geometry?.index;
    final position = geometry?.attributes["position"];
    final morphPosition = geometry?.morphAttributes["position"];
    final morphTargetsRelative = geometry?.morphTargetsRelative;
    final uv = geometry?.attributes["uv"];
    final uv2 = geometry?.attributes["uv2"];
    final groups = geometry?.groups;
    final drawRange = geometry?.drawRange;

    if (index != null) {
      // indexed buffer geometry

      if (material is GroupMaterial) {
        for (int i = 0, il = groups?.length ?? 0; i < il; i++) {
          final group = groups![i];
          final groupMaterial = material.children[group["materialIndex"]];

          final start = math.max<int>(group["start"], drawRange!["start"]!);
          final end = math.min<int>((group["start"] + group["count"]),
              (drawRange["start"]! + drawRange["count"]!));

          for (int j = start, jl = end; j < jl; j += 3) {
            int a = index.getX(j)!.toInt();
            int b = index.getX(j + 1)!.toInt();
            int c = index.getX(j + 2)!.toInt();

            intersection = checkBufferGeometryIntersection(
                this,
                groupMaterial,
                raycaster,
                _meshray,
                position,
                morphPosition,
                morphTargetsRelative,
                uv,
                uv2,
                a,
                b,
                c);

            if (intersection != null) {
              intersection.faceIndex = (j / 3).floor();
              // triangle number in indexed buffer semantics
              intersection.face?.materialIndex = group["materialIndex"];
              intersects.add(intersection);
            }
          }
        }
      } else {
        final start = math.max(0, drawRange!["start"]!);
        final end = math.min(index.count, (drawRange["start"]! + drawRange["count"]!));

        for (int i = start, il = end; i < il; i += 3) {
          int a = index.getX(i)!.toInt();
          int b = index.getX(i + 1)!.toInt();
          int c = index.getX(i + 2)!.toInt();

          intersection = checkBufferGeometryIntersection(
              this,
              material,
              raycaster,
              _meshray,
              position,
              morphPosition,
              morphTargetsRelative,
              uv,
              uv2,
              a,
              b,
              c);

          if (intersection != null) {
            intersection.faceIndex = (i / 3).floor();
            // triangle number in indexed buffer semantics
            intersects.add(intersection);
          }
        }
      }
    } else if (position != null) {
      // non-indexed buffer geometry

      if (material is GroupMaterial) {
        for (int i = 0, il = groups?.length ?? 0; i < il; i++) {
          final group = groups![i];
          final groupMaterial = material.children[group["materialIndex"]];

          final start = math.max<int>(group["start"], drawRange!["start"]!);
          final end = math.min<int>((group["start"] + group["count"]),
              (drawRange["start"]! + drawRange["count"]!));

          for (int j = start, jl = end; j < jl; j += 3) {
            final a = j;
            final b = j + 1;
            final c = j + 2;

            intersection = checkBufferGeometryIntersection(
                this,
                groupMaterial,
                raycaster,
                _meshray,
                position,
                morphPosition,
                morphTargetsRelative,
                uv,
                uv2,
                a,
                b,
                c);

            if (intersection != null) {
              intersection.faceIndex = (j / 3).floor();
              // triangle number in non-indexed buffer semantics
              intersection.face?.materialIndex = group["materialIndex"];
              intersects.add(intersection);
            }
          }
        }
      } else {
        final start = math.max(0, drawRange!["start"]!);
        final end = math.min<int>(
            position.count, (drawRange["start"]! + drawRange["count"]!));

        for (int i = start, il = end; i < il; i += 3) {
          final a = i;
          final b = i + 1;
          final c = i + 2;

          intersection = checkBufferGeometryIntersection(
              this,
              material,
              raycaster,
              _meshray,
              position,
              morphPosition,
              morphTargetsRelative,
              uv,
              uv2,
              a,
              b,
              c);

          if (intersection != null) {
            intersection.faceIndex = (i / 3).floor(); // triangle number in non-indexed buffer semantics
            intersects.add(intersection);
          }
        }
      }
    }
  }
}

Intersection? checkIntersection(
    Object3D object,
    Material material,
    Raycaster raycaster,
    Ray ray,
    Vector3 pA,
    Vector3 pB,
    Vector3 pC,
    Vector3 point) {
  Vector3? intersect;

  if (material.side == BackSide) {
    intersect = ray.intersectTriangle(pC, pB, pA, true, point);
  } else {
    intersect =
        ray.intersectTriangle(pA, pB, pC, material.side != DoubleSide, point);
  }

  if (intersect == null) return null;

  _intersectionPointWorld.setFrom(point);
  _intersectionPointWorld.applyMatrix4(object.matrixWorld);

  final distance = raycaster.ray.origin.distanceTo(_intersectionPointWorld);

  if (distance < raycaster.near || distance > raycaster.far) return null;

  return Intersection(
    distance: distance,
    point: _intersectionPointWorld.clone(),
    object: object
  );
}

Intersection? checkBufferGeometryIntersection(
    Object3D object,
    Material material,
    Raycaster raycaster,
    Ray ray,
    BufferAttribute position,
    morphPosition,
    morphTargetsRelative,
    uv,
    uv2,
    int a,
    int b,
    int c) {
  _vA.fromBuffer(position, a);
  _vB.fromBuffer(position, b);
  _vC.fromBuffer(position, c);

  final morphInfluences = object.morphTargetInfluences;

  if (morphPosition != null && morphInfluences.isNotEmpty) {
    _morphA.setValues(0, 0, 0);
    _morphB.setValues(0, 0, 0);
    _morphC.setValues(0, 0, 0);

    for (int i = 0, il = morphPosition.length; i < il; i++) {
      double influence = morphInfluences[i];
      final morphAttribute = morphPosition[i];

      if (influence == 0) continue;

      _tempA.fromBuffer(morphAttribute, a);
      _tempB.fromBuffer(morphAttribute, b);
      _tempC.fromBuffer(morphAttribute, c);

      if (morphTargetsRelative) {
        _morphA.addScaled(_tempA, influence);
        _morphB.addScaled(_tempB, influence);
        _morphC.addScaled(_tempC, influence);
      } else {
        _morphA.addScaled(_tempA.sub(_vA), influence);
        _morphB.addScaled(_tempB.sub(_vB), influence);
        _morphC.addScaled(_tempC.sub(_vC), influence);
      }
    }

    _vA.add(_morphA);
    _vB.add(_morphB);
    _vC.add(_morphC);
  }

  if (object is SkinnedMesh) {
    object.applyBoneTransform(a, _vA);
    object.applyBoneTransform(b, _vB);
    object.applyBoneTransform(c, _vC);
  }

  final intersection = checkIntersection(
      object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);

  if (intersection != null) {
    if (uv != null) {
      _uvA.fromBuffer(uv, a);
      _uvB.fromBuffer(uv, b);
      _uvC.fromBuffer(uv, c);

      intersection.uv = TriangleUtil.getUV(_intersectionPoint, _vA, _vB, _vC,
          _uvA, _uvB, _uvC, Vector2.zero());
    }

    if (uv2 != null) {
      _uvA.fromBuffer(uv2, a);
      _uvB.fromBuffer(uv2, b);
      _uvC.fromBuffer(uv2, c);

      intersection.uv2 = TriangleUtil.getUV(_intersectionPoint, _vA, _vB,
          _vC, _uvA, _uvB, _uvC, Vector2.zero());
    }

    final face = Face.fromJson(
        {"a": a, "b": b, "c": c, "normal": Vector3.zero(), "materialIndex": 0});

    TriangleUtil.getNormal(_vA, _vB, _vC, face.normal);

    intersection.face = face;
  }

  return intersection;
}
