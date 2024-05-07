import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

final _shvector = Vector3();
final _boneMatrix = Matrix4();
final _matrixWorldInv = Matrix4();

/// A helper object to assist with visualizing a [Skeleton]. The
/// helper is rendered using a [LineBasicMaterial].
/// 
/// ```
/// final helper = SkeletonHelper( skinnedMesh );
/// scene.add( helper );
/// ```
class SkeletonHelper extends LineSegments {
  bool isSkeletonHelper = true;
  late dynamic root;
  late dynamic bones;

  SkeletonHelper.create(super.geometry, super.material){
    type = 'SkeletonHelper';
    matrixAutoUpdate = false;
  }

  /// [object] -- Usually an instance of [SkinnedMesh]. However, any instance
  /// of [Object3D] can be used if it represents a hierarchy of [Bone]s (via [Object3D.children]).
  factory SkeletonHelper(Object3D object) {
    final bones = getBoneList(object);

    final geometry = BufferGeometry();

    List<double> vertices = [];
    List<double> colors = [];

    final color1 = Color(0, 0, 1);
    final color2 = Color(0, 1, 0);

    for (int i = 0; i < bones.length; i++) {
      final bone = bones[i];

      if (bone.parent != null && bone.parent!.type == "Bone") {
        vertices.addAll([0, 0, 0]);
        vertices.addAll([0, 0, 0]);
        colors.addAll([color1.red, color1.green, color1.blue]);
        colors.addAll([color2.red, color2.green, color2.blue]);
      }
    }

    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    geometry.setAttributeFromString('color',Float32BufferAttribute(Float32Array.from(colors), 3, false));

    final material = LineBasicMaterial.fromMap({
      "vertexColors": true,
      "depthTest": false,
      "depthWrite": false,
      "toneMapped": false,
      "transparent": true
    });

    final keletonHelper = SkeletonHelper.create(geometry, material);

    keletonHelper.root = object;
    keletonHelper.bones = bones;

    keletonHelper.matrix = object.matrixWorld;

    return keletonHelper;
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    final bones = this.bones;

    final geometry = this.geometry!;
    final position = geometry.getAttributeFromString('position');

    _matrixWorldInv.setFrom(root.matrixWorld).invert();

    for (int i = 0, j = 0; i < bones.length; i++) {
      final bone = bones[i];

      if (bone.parent != null && bone.parent.type == "Bone") {
        _boneMatrix.multiply2(_matrixWorldInv, bone.matrixWorld);
        _shvector.setFromMatrixPosition(_boneMatrix);
        position.setXYZ(j, _shvector.x, _shvector.y, _shvector.z);

        _boneMatrix.multiply2(_matrixWorldInv, bone.parent.matrixWorld);
        _shvector.setFromMatrixPosition(_boneMatrix);
        position.setXYZ(j + 1, _shvector.x, _shvector.y, _shvector.z);

        j += 2;
      }
    }

    geometry.getAttributeFromString('position').needsUpdate = true;

    super.updateMatrixWorld(force);
  }

  static List<Bone> getBoneList(Object3D? object) {
    List<Bone> boneList = [];

    if (object != null && object is Bone) {
      boneList.add(object);
    }

    for (int i = 0; i < (object?.children.length ?? 0); i++) {
      boneList.addAll(getBoneList(object!.children[i]));
    }

    return boneList;
  }
}


