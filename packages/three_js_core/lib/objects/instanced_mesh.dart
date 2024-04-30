import 'package:flutter_gl/flutter_gl.dart';
import '../core/index.dart';
import '../materials/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './mesh.dart';

final _instanceLocalMatrix = Matrix4.identity();
final _instanceWorldMatrix = Matrix4.identity();

List<Intersection> _instanceIntersects = [];

final _mesh = Mesh(BufferGeometry(), Material());

class InstancedMesh extends Mesh {
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
    return color.fromNativeArray(instanceColor!.array.data, index * 3);
  }

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

  void setColorAt(int index, Color color) {
    instanceColor ??= InstancedBufferAttribute(Float32Array((instanceMatrix!.count * 3).toInt()), 3, false);
    color.copyIntoArray(instanceColor!.array, index * 3);
  }

  void setMatrixAt(int index, Matrix4 matrix) {
    matrix.copyIntoArray(instanceMatrix!.array.toDartList(), index * 16);
  }

  @override
  void updateMorphTargets() {}

  @override
  void dispose() {
    dispatchEvent(Event(type: "dispose"));
  }
}
