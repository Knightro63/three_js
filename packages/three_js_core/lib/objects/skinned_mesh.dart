import 'package:three_js_core/others/index.dart';

import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './mesh.dart';
import './skeleton.dart';

final _basePosition = Vector3.zero();

final _skinIndex = Vector4.identity();
final _skinWeight = Vector4.identity();

final _vector = Vector3.zero();
final _matrix = Matrix4.identity();

class SkinnedMesh extends Mesh {
  String bindMode = "attached";
  Matrix4 bindMatrixInverse = Matrix4.identity();

  SkinnedMesh(super.geometry, super.material){
    type = "SkinnedMesh";
    bindMatrix = Matrix4.identity();
  }

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

  void pose() {
    skeleton!.pose();
  }

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
      skinWeight.setXYZW(i, vector.x.toDouble(), vector.y.toDouble(), vector.z.toDouble(), vector.w.toDouble());
    }
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    super.updateMatrixWorld(force);

    if (bindMode == 'attached') {
      bindMatrixInverse..setFrom(matrixWorld)..invert();
    } 
    else if (bindMode == 'detached') {
      bindMatrixInverse..setFrom(bindMatrix!)..invert();
    } 
    else {
      console.warning('SkinnedMesh: Unrecognized bindMode: $bindMode');
    }
  }

  Vector3 boneTransform(int index, Vector3 target) {
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
        _matrix.multiply2(skeleton!.bones[boneIndex].matrixWorld,
            skeleton.boneInverses[boneIndex]);
        target.addScaled(
            _vector..setFrom(_basePosition)..applyMatrix4(_matrix), weight);
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
