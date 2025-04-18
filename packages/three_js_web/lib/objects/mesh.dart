import 'dart:convert';
import '../core/index.dart';
import '../materials/index.dart';
import 'skinned_mesh.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _inverseMatrix = Matrix4();
final _ray = Ray();
final _sphere = BoundingSphere();
final _sphereHitAt = Vector3();

final _vA = Vector3();
final _vB = Vector3();
final _vC = Vector3();

final _tempA = Vector3();
final _morphA = Vector3();

final _intersectionPoint = Vector3();
final _intersectionPointWorld = Vector3();

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
    return Mesh(geometry?.clone(), material?.clone()).copy(this, recursive);
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

  /// Returns the local-space position of the vertex at the given index, taking into
  /// account the current animation state of both morph targets and skinning.
  ///
  /// [index] - The vertex index.
  /// [target] - The target object that is used to store the method's result.
  /// return Vector3 The vertex position in local space.
	Vector3 getVertexPosition(int index, Vector3 target ) {
		final geometry = this.geometry;
		final position = geometry?.attributes['position'];
		final morphPosition = geometry?.morphAttributes['position'];
		final morphTargetsRelative = geometry?.morphTargetsRelative;

		target.fromBuffer( position, index );

		final morphInfluences = this.morphTargetInfluences;

		if ( morphPosition != null && morphInfluences.isNotEmpty) {
			_morphA.setValues( 0, 0, 0 );

			for (int i = 0, il = morphPosition.length; i < il; i ++ ) {
				final influence = morphInfluences[ i ];
				final morphAttribute = morphPosition[ i ];

				if ( influence == 0 ) continue;

				_tempA.fromBuffer( morphAttribute, index );

				if ( morphTargetsRelative != null) {
					_morphA.addScaled( _tempA, influence );
				} else {
					_morphA.addScaled( _tempA.sub( target ), influence );
				}
			}

			target.add( _morphA );
		}

		return target;
	}

  /// Get intersections between a casted ray and this mesh.
  /// [Raycaster.intersectObject] will call this method, but the results
  /// are not ordered.
  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
		final geometry = this.geometry;
		final material = this.material;
		final matrixWorld = this.matrixWorld;

		if ( material == null ) return;

		// test with bounding sphere in world space

		if ( geometry?.boundingSphere == null ) geometry?.computeBoundingSphere();

		_sphere.setFrom( geometry!.boundingSphere! );
		_sphere.applyMatrix4( matrixWorld );

		// check distance from ray origin to bounding sphere

		_ray.copyFrom( raycaster.ray ).recast( raycaster.near );

		if ( _sphere.containsPoint( _ray.origin ) == false ) {
			if ( _ray.intersectSphere( _sphere, _sphereHitAt ) == null ) return;
			if ( _ray.origin.distanceToSquared( _sphereHitAt ) > math.pow(( raycaster.far - raycaster.near ),2) ) return;
		}

		// convert ray to local space of mesh

		_inverseMatrix.setFrom( matrixWorld ).invert();
		_ray.copyFrom( raycaster.ray ).applyMatrix4( _inverseMatrix );

		// test with bounding box in local space

		if ( geometry.boundingBox != null ) {
			if ( _ray.intersectsBox( geometry.boundingBox! ) == false ) return;
		}

		// test for intersections with geometry

		this.computeIntersections( raycaster, intersects, _ray );
  }

	void computeIntersections(Raycaster raycaster, List<Intersection> intersects, rayLocalSpace ) {
		Intersection? intersection;

		final geometry = this.geometry;
		final material = this.material;

		final index = geometry!.index;
		final position = geometry.attributes['position'];
		final uv = geometry.attributes['uv'];
		final uv1 = geometry.attributes['uv1'];
		final normal = geometry.attributes['normal'];
		final groups = geometry.groups;
		final drawRange = geometry.drawRange;

		if ( index != null ) {
			if (material is GroupMaterial) {
				for (int i = 0, il = groups.length; i < il; i ++ ) {
					final group = groups[ i ];
					final groupMaterial = material.children[ group['materialIndex'] ];

					final start = math.max<int>( group['start'], drawRange['start']! );
					final end = math.min<int>( index.count, math.min( ( group['start'] + group['count'] ), ( drawRange['start']! + drawRange['count']! ) ) );

					for (int j = start, jl = end; j < jl; j += 3 ) {
						final a = index.getX( j )!.toInt();
						final b = index.getX( j + 1 )!.toInt();
						final c = index.getX( j + 2 )!.toInt();

						intersection = checkGeometryIntersection( this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

						if ( intersection != null) {
							intersection.faceIndex = ( j / 3 ).floor(); // triangle number in indexed buffer semantics
							intersection.face?.materialIndex = group['materialIndex'];
							intersects.add( intersection );
						}
					}
				}
			} 
      else {
				final start = math.max<int>( 0, drawRange['start']! );
				final end = math.min( index.count, ( drawRange['start']! + drawRange['count']! ) );

				for (int i = start, il = end; i < il; i += 3 ) {
					final a = index.getX( i )!.toInt();
					final b = index.getX( i + 1 )!.toInt();
					final c = index.getX( i + 2 )!.toInt();

					intersection = checkGeometryIntersection( this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

					if ( intersection != null) {
						intersection.faceIndex = ( i / 3 ).floor(); // triangle number in indexed buffer semantics
						intersects.add( intersection );
					}
				}
			}
		} 
    else if ( position != null ) {
			if (material is GroupMaterial) {
				for (int i = 0, il = groups.length; i < il; i ++ ) {
					final group = groups[ i ];
					final groupMaterial = material.children[ group['materialIndex'] ];

					final start = math.max<int>( group['start'], drawRange['start']! );
					final end = math.min<int>( position.count, math.min<int>( ( group['start'] + group['count'] ), ( drawRange['start']! + drawRange['count']! ) ) );

					for (int j = start, jl = end; j < jl; j += 3 ) {
						final a = j;
						final b = j + 1;
						final c = j + 2;

						intersection = checkGeometryIntersection( this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

						if ( intersection != null) {
							intersection.faceIndex = ( j / 3 ).floor(); // triangle number in non-indexed buffer semantics
							intersection.face?.materialIndex = group['materialIndex'];
							intersects.add( intersection );
						}
					}
				}
			} 
      else {
				final start = math.max<int>( 0, drawRange['start']! );
				final end = math.min<int>( position.count, ( drawRange['start']! + drawRange['count']! ) );

				for (int i = start, il = end; i < il; i += 3 ) {
					final a = i;
					final b = i + 1;
					final c = i + 2;

					intersection = checkGeometryIntersection( this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c );

					if ( intersection != null) {
						intersection.faceIndex = ( i / 3 ).floor(); // triangle number in non-indexed buffer semantics
						intersects.add( intersection );
					}
				}
			}
		}
	}

  Intersection? checkGeometryIntersection(Mesh object, Material? material, Raycaster raycaster, Ray ray, BufferAttribute? uv, BufferAttribute? uv1, BufferAttribute? normal, int a, int b, int c ) {
    object.getVertexPosition( a, _vA );
    object.getVertexPosition( b, _vB );
    object.getVertexPosition( c, _vC );

    final intersection = checkIntersection( object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint );

    if ( intersection != null) {

      final barycoord = new Vector3();
      TriangleUtil.getBarycoord( _intersectionPoint, _vA, _vB, _vC, barycoord );

      if ( uv != null) {
        intersection.uv = TriangleUtil.getInterpolatedAttribute( uv, a, b, c, barycoord, Vector2() ) as Vector2;
      }

      if ( uv1 != null) {
        intersection.uv1 = TriangleUtil.getInterpolatedAttribute( uv1, a, b, c, barycoord, Vector2() )as Vector2;
      }

      if ( normal != null) {
        intersection.normal = TriangleUtil.getInterpolatedAttribute( normal, a, b, c, barycoord, Vector3() ) as Vector3;

        if ( (intersection.normal?.dot( ray.direction ) ?? 0) > 0 ) {
          intersection.normal?.scale( - 1 );
        }
      }

      final face = Face(
        a,
        b,
        c,
        Vector3(),
        0
      );

      TriangleUtil.getNormal( _vA, _vB, _vC, face.normal );

      intersection.face = face;
      intersection.barycoord = barycoord;
    }

    return intersection;
  }
}

Intersection? checkIntersection(
    Object3D object,
    Material? material,
    Raycaster raycaster,
    Ray ray,
    Vector3 pA,
    Vector3 pB,
    Vector3 pC,
    Vector3 point) {
  Vector3? intersect;

  if (material?.side == BackSide) {
    intersect = ray.intersectTriangle(pC, pB, pA, true, point);
  } else {
    intersect = ray.intersectTriangle(pA, pB, pC, material?.side != DoubleSide, point);
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

// Intersection? checkBufferGeometryIntersection(
//     Object3D object,
//     Material material,
//     Raycaster raycaster,
//     Ray ray,
//     BufferAttribute position,
//     morphPosition,
//     morphTargetsRelative,
//     uv,
//     uv2,
//     int a,
//     int b,
//     int c) {
//   _vA.fromBuffer(position, a);
//   _vB.fromBuffer(position, b);
//   _vC.fromBuffer(position, c);

//   final morphInfluences = object.morphTargetInfluences;

//   if (morphPosition != null && morphInfluences.isNotEmpty) {
//     _morphA.setValues(0, 0, 0);
//     _morphB.setValues(0, 0, 0);
//     _morphC.setValues(0, 0, 0);

//     for (int i = 0, il = morphPosition.length; i < il; i++) {
//       double influence = morphInfluences[i];
//       final morphAttribute = morphPosition[i];

//       if (influence == 0) continue;

//       _tempA.fromBuffer(morphAttribute, a);
//       _tempB.fromBuffer(morphAttribute, b);
//       _tempC.fromBuffer(morphAttribute, c);

//       if (morphTargetsRelative) {
//         _morphA.addScaled(_tempA, influence);
//         _morphB.addScaled(_tempB, influence);
//         _morphC.addScaled(_tempC, influence);
//       } else {
//         _morphA.addScaled(_tempA.sub(_vA), influence);
//         _morphB.addScaled(_tempB.sub(_vB), influence);
//         _morphC.addScaled(_tempC.sub(_vC), influence);
//       }
//     }

//     _vA.add(_morphA);
//     _vB.add(_morphB);
//     _vC.add(_morphC);
//   }

//   if (object is SkinnedMesh) {
//     object.applyBoneTransform(a, _vA);
//     object.applyBoneTransform(b, _vB);
//     object.applyBoneTransform(c, _vC);
//   }

//   final intersection = checkIntersection(
//       object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);

//   if (intersection != null) {
//     if (uv != null) {
//       _uvA.fromBuffer(uv, a);
//       _uvB.fromBuffer(uv, b);
//       _uvC.fromBuffer(uv, c);

//       intersection.uv = TriangleUtil.getUV(_intersectionPoint, _vA, _vB, _vC,
//           _uvA, _uvB, _uvC, Vector2.zero());
//     }

//     if (uv2 != null) {
//       _uvA.fromBuffer(uv2, a);
//       _uvB.fromBuffer(uv2, b);
//       _uvC.fromBuffer(uv2, c);

//       intersection.uv2 = TriangleUtil.getUV(_intersectionPoint, _vA, _vB,
//           _vC, _uvA, _uvB, _uvC, Vector2.zero());
//     }

//     final face = Face.fromJson(
//         {"a": a, "b": b, "c": c, "normal": Vector3.zero(), "materialIndex": 0});

//     TriangleUtil.getNormal(_vA, _vB, _vC, face.normal);

//     intersection.face = face;
//   }

//   return intersection;
// }
