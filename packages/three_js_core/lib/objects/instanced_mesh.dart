import '../core/index.dart';
import '../materials/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './mesh.dart';

final _instanceLocalMatrix = Matrix4.identity();
final _instanceWorldMatrix = Matrix4.identity();

final _sphere = BoundingSphere();

List<Intersection> _instanceIntersects = [];
final _mesh = Mesh(BufferGeometry(), Material());

/// A special version of [Mesh] with instanced rendering support. Use
/// [name] if you have to render a large number of objects with the same
/// geometry and material but with different world transformations. The usage
/// of [name] will help you to reduce the number of draw calls and thus
/// improve the overall rendering performance in your application.
class InstancedMesh extends Mesh {
  BoundingSphere? boundingSphere;

  /// [geometry] - an instance of [BufferGeometry].
  ///
  /// [material] - an instance of [Material]. Default is a
  /// new [MeshBasicMaterial].
  /// 
  /// [count] - the number of instances.
  /// 
  InstancedMesh(super.geometry, super.material, int count){
    type = "InstancedMesh";

    final dl = Float32Array(count * 16);
    instanceMatrix = InstancedBufferAttribute(dl, 16, false);
    instanceColor = null;

    this.count = count;

    frustumCulled = false;
  }

  @override
  InstancedMesh copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    if (source is InstancedMesh) {
      instanceMatrix!.copy(source.instanceMatrix!);
      if (source.instanceColor != null) {
        instanceColor = source.instanceColor!.clone();
      }
      count = source.count;
    }
    return this;
  }

  Color getColorAt(int index, Color color) {
    return color.fromUnknown(instanceColor!.array, index * 3);
  }

  /// [index] - The index of an instance. Values have to be in the
  /// range [0, count].
  /// 
  /// [matrix] - This 4x4 matrix will be set to the local
  /// transformation matrix of the defined instance.
  /// Get the local transformation matrix of the defined instance.
  /// 
  Matrix4 getMatrixAt(int index, Matrix4 matrix) {
    return matrix.fromNativeArray(instanceMatrix!.array, index * 16);
  }

  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    final matrixWorld = this.matrixWorld;
    final raycastTimes = count;

    _mesh.geometry = geometry;
    _mesh.material = material;

    if (_mesh.material == null) return;

    for (int instanceId = 0; instanceId < raycastTimes!; instanceId++) {
      // calculate the world matrix for each instance

      getMatrixAt(instanceId, _instanceLocalMatrix);

      _instanceWorldMatrix.multiply2(matrixWorld, _instanceLocalMatrix);

      // the mesh represents this single instance

      _mesh.matrixWorld = _instanceWorldMatrix;

      _mesh.raycast(raycaster, _instanceIntersects);

      // process the result of raycast

      for (int i = 0, l = _instanceIntersects.length; i < l; i++) {
        final intersect = _instanceIntersects[i];
        intersect.instanceId = instanceId;
        intersect.object = this;
        intersects.add(intersect);
      }

      _instanceIntersects.length = 0;
    }
  }

  /// [index] - The index of an instance. Values have to be in the
  /// range [0, count].
  /// 
  /// [color] - The color of a single instance.
  /// 
  /// Sets the given color to the defined instance. Make sure you set
  /// [instanceColor][needsUpdate] to
  /// true after updating all the colors.
  void setColorAt(int index, Color color) {
    instanceColor ??= InstancedBufferAttribute(Float32Array((instanceMatrix!.count * 3).toInt()), 3, false);
    color.copyIntoArray(instanceColor!.array, index * 3);
  }


  /// [index] - The index of an instance. Values have to be in the
  /// range [0, count].
  /// 
  /// [matrix] - A 4x4 matrix representing the local transformation
  /// of a single instance.
  /// 
  /// Sets the given local transformation matrix to the defined instance. Make
  /// sure you set [instanceMatrix][needsUpdate] 
  /// to true after updating all the matrices.
  void setMatrixAt(int index, Matrix4 matrix) {
    matrix.copyIntoArray(instanceMatrix!.array.toDartList(), index * 16);
  }

  @override
  void updateMorphTargets() {}

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  @override
  void dispose() {
    dispatchEvent(Event(type: "dispose"));
  }

	void computeBoundingSphere() {
		final geometry = this.geometry;
		final count = this.count;

		boundingSphere ??= BoundingSphere();
		
		if (geometry?.boundingSphere == null ) {
			geometry?.computeBoundingSphere();
		}

		boundingSphere?.empty();

		for (int i = 0; i < count!; i ++ ) {
			getMatrixAt( i, _instanceLocalMatrix );
			_sphere.setFrom(geometry!.boundingSphere!).applyMatrix4( _instanceLocalMatrix );
			boundingSphere?.union( _sphere );
		}
	}
}
