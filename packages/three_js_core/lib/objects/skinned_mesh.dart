import 'package:three_js_core/others/index.dart';

import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './mesh.dart';
import './skeleton.dart';

final _basePosition = Vector3.zero();

final _skinIndex = Vector4.identity();
final _skinWeight = Vector4.identity();

final _vector3 = Vector3();
final _matrix4 = Matrix4();
final _vertex = Vector3();

final _sphere = BoundingSphere();
final _inverseMatrix = Matrix4();
final _ray = Ray();

/// A mesh that has a [Skeleton] with [bones] that can then be
/// used to animate the vertices of the geometry.
/// 
/// ```
/// final geometry = CylinderGeometry( 5, 5, 5, 5, 15, 5, 30 );
///
/// // create the skin indices and skin weights manually
/// // (typically a loader would read this data from a 3D model for you)
///
/// final position = geometry.attributes.position;
///
/// final vertex = Vector3();
///
/// final skinIndices = [];
/// final skinWeights = [];
///
/// for(int i = 0; i < position.count; i++){
///   vertex.fromBufferAttribute( position, i );
///
///   // compute skinIndex and skinWeight based on some configuration data
///   final y = ( vertex.y + sizing.halfHeight );
///   final skinIndex = Math.floor( y / sizing.segmentHeight );
///   final skinWeight = ( y % sizing.segmentHeight ) / sizing.segmentHeight;
///   skinIndices.push( skinIndex, skinIndex + 1, 0, 0 );
///   skinWeights.push( 1 - skinWeight, skinWeight, 0, 0 );
/// }
///
/// geometry.setAttribute(Attribute.skinIndex, Uint16BufferAttribute( skinIndices, 4));
/// geometry.setAttribute(Attribute.skinWeight, Float32BufferAttribute( skinWeights, 4));
///
/// // create skinned mesh and skeleton
///
/// final mesh = SkinnedMesh(geometry, material);
/// final skeleton = Skeleton(bones);
///
/// // see example from THREE.Skeleton
/// final rootBone = skeleton.bones[0];
/// mesh.add(rootBone);
///
/// // bind the skeleton to the mesh
/// mesh.bind(skeleton);
///
/// // move the bones and manipulate the model
/// skeleton.bones[0].rotation.x = -0.1;
/// skeleton.bones[1].rotation.x = 0.2;
/// ```
/// 
class SkinnedMesh extends Mesh {
  String bindMode = AttachedBindMode;
  Matrix4 bindMatrixInverse = Matrix4.identity();
  BoundingBox? boundingBox;
  BoundingSphere? boundingSphere;

  /// [geometry] - an instance of [BufferGeometry].
  /// 
  /// [material] - (optional) an instance of [Material].
  /// Default is a new [MeshBasicMaterial].
  SkinnedMesh(super.geometry, super.material){
    type = "SkinnedMesh";
    bindMatrix = Matrix4.identity();
  }

	
	/// Computes the bounding box of the skinned mesh, and updates {@link SkinnedMesh#boundingBox}.
	/// The bounding box is not automatically computed by the engine; this method must be called by your app.
	/// If the skinned mesh is animated, the bounding box should be recomputed per frame in order to reflect
	/// the current animation state.
	void computeBoundingBox() {
		final geometry = this.geometry;

		if ( this.boundingBox == null ) {
			this.boundingBox = new BoundingBox();
		}

		this.boundingBox?.empty();

		final positionAttribute = geometry?.getAttributeFromString( 'position' );

		for (int i = 0; i < positionAttribute.count; i ++ ) {
			this.getVertexPosition( i, _vertex );
			this.boundingBox?.expandByPoint( _vertex );
		}
	}

  /// Computes the bounding sphere of the skinned mesh, and updates {@link SkinnedMesh#boundingSphere}.
  /// The bounding sphere is automatically computed by the engine once when it is needed, e.g., for ray casting
  /// and view frustum culling. If the skinned mesh is animated, the bounding sphere should be recomputed
  /// per frame in order to reflect the current animation state.
	void computeBoundingSphere() {
		final geometry = this.geometry;

		if ( this.boundingSphere == null ) {
			this.boundingSphere = new BoundingSphere();
		}

		this.boundingSphere?.empty();

		final positionAttribute = geometry?.getAttributeFromString( 'position' );

		for (int i = 0; i < positionAttribute.count; i ++ ) {
			this.getVertexPosition( i, _vertex );
			this.boundingSphere?.expandByPoint( _vertex );
		}
	}

  /// This method does currently not clone an instance of [name] correctly.
  /// Please use [SkeletonUtils.clone] in the meanwhile.
  @override
  SkinnedMesh clone([bool? recursive]) {
    return SkinnedMesh(geometry!, material).copy(this, recursive);
  }

  @override
  SkinnedMesh copy(Object3D source, [bool? recursive]) {
    super.copy(source);

    SkinnedMesh source1 = source as SkinnedMesh;

    bindMode = source1.bindMode;
    bindMatrix!.setFrom(source1.bindMatrix!);
    bindMatrixInverse.setFrom(source1.bindMatrixInverse);

    skeleton = source1.skeleton;

    return this;
  }

	void raycast(Raycaster raycaster, List<Intersection> intersects ) {
		final material = this.material;
		final matrixWorld = this.matrixWorld;

		if ( material == null ) return;

		// test with bounding sphere in world space

		if ( this.boundingSphere == null ) this.computeBoundingSphere();

		_sphere.setFrom( this.boundingSphere! );
		_sphere.applyMatrix4( matrixWorld );

		if ( raycaster.ray.intersectsSphere( _sphere ) == false ) return;

		// convert ray to local space of skinned mesh

		_inverseMatrix.setFrom( matrixWorld ).invert();
		_ray.copyFrom( raycaster.ray ).applyMatrix4( _inverseMatrix );

		// test with bounding box in local space

		if ( this.boundingBox != null ) {
			if ( _ray.intersectsBox( this.boundingBox! ) == false ) return;
		}

		// test for intersections with geometry

		this.computeIntersections( raycaster, intersects, _ray );
	}

  @override
	Vector3 getVertexPosition(int index, Vector3 target ) {
		super.getVertexPosition( index, target );
		this.applyBoneTransform( index, target );
		return target;
	}
  
  /// [skeleton] - [Skeleton] created from a [Bones] tree.
  /// 
  /// [bindMatrix] - [Matrix4] that represents the base
  /// transform of the skeleton.
  ///
  /// Bind a skeleton to the skinned mesh. The bindMatrix gets saved to
  /// .bindMatrix property and the .bindMatrixInverse gets calculated.
  void bind(Skeleton skeleton, [Matrix4? bindMatrix]) {
    this.skeleton = skeleton;

    if (bindMatrix == null) {
      updateMatrixWorld(true);

      this.skeleton!.calculateInverses();

      bindMatrix = matrixWorld;
    }

    this.bindMatrix!.setFrom(bindMatrix);
    bindMatrixInverse..setFrom(bindMatrix)..invert();
  }

  /// This method sets the skinned mesh in the rest pose (resets the pose).
  void pose() {
    skeleton!.pose();
  }

  /// Normalizes the skin weights.
  void normalizeSkinWeights() {
    final vector = Vector4.identity();
    final skinWeight = geometry!.attributes["skinWeight"];
    for (int i = 0, l = skinWeight.count; i < l; i++) {
      vector.fromBuffer( skinWeight, i );
      final scale = 1.0 / vector.manhattanLength();
      if (scale != double.infinity) {
        vector.scale(scale);
      } 
      else {
        vector.setValues(1, 0, 0, 0); // do something reasonable
      }
      skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
    }
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    super.updateMatrixWorld(force);

    if (bindMode == AttachedBindMode) {
      bindMatrixInverse..setFrom(matrixWorld)..invert();
    } 
    else if (bindMode == DetachedBindMode) {
      bindMatrixInverse..setFrom(bindMatrix!)..invert();
    } 
    else {
      console.warning('SkinnedMesh: Unrecognized bindMode: $bindMode');
    }
  }

  /// Applies the bone transform associated with the given index to the given
  /// position vector. Returns the updated vector.
  Vector3 applyBoneTransform(int index, Vector3 target) {
    final skeleton = this.skeleton;
    final geometry = this.geometry!;

    _skinIndex.fromBuffer(geometry.attributes["skinIndex"], index);
    _skinWeight.fromBuffer(geometry.attributes["skinWeight"], index);
    _basePosition..setFrom(target)..applyMatrix4(bindMatrix!);
    target.setValues(0, 0, 0);

    for (int i = 0; i < 4; i++) {
      final weight = _skinWeight[i];
      if (weight != 0) {
        final boneIndex = _skinIndex[i].toInt();
        _matrix4.multiply2(skeleton!.bones[boneIndex].matrixWorld,skeleton.boneInverses[boneIndex]);
        target.addScaled(_vector3..setFrom(_basePosition)..applyMatrix4(_matrix4), weight);
      }
    }
    target.applyMatrix4(bindMatrixInverse);
    return target;
  }

  @override
  Matrix4? getValue(String name) {
    if (name == "bindMatrix") {
      return bindMatrix;
    } 
    else if (name == "bindMatrixInverse") {
      return bindMatrixInverse;
    } 
    else {
      return super.getValue(name);
    }
  }
}
