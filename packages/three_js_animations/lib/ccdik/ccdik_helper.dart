import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final Vector3 _vector = Vector3();

/// Gets the relative position of a bone within the inverted world matrix.
Vector3 getPosition(Bone? bone, Matrix4 matrixWorldInv) {
  if(bone == null) return Vector3();
  return _vector
      .setFromMatrixPosition(bone.matrixWorld)
      .applyMatrix4(matrixWorldInv);
}

/// Sets the calculated bone position values into the flat attribute array.
void setPositionOfBoneToAttributeArray(dynamic array, int index, dynamic bone, Matrix4 matrixWorldInv) {
  final v = getPosition(bone, matrixWorldInv);
  
  array[index * 3 + 0] = v.x;
  array[index * 3 + 1] = v.y;
  array[index * 3 + 2] = v.z;
}


final Matrix4 _matrix = Matrix4();

/// Helper for visualizing IK bones.
class CCDIKHelper extends Object3D {
  /// The skinned mesh this helper refers to.
  late Object3D root;

  /// The IK objects.
  late List<Map<String,dynamic>> iks;

  /// The helpers sphere geometry.
  late SphereGeometry sphereGeometry;

  /// The material for the target spheres.
  late MeshBasicMaterial targetSphereMaterial;

  /// The material for the effector spheres.
  late MeshBasicMaterial effectorSphereMaterial;

  /// The material for the link spheres.
  late MeshBasicMaterial linkSphereMaterial;

  /// A global line material.
  late LineBasicMaterial lineMaterial;

  CCDIKHelper(Object3D mesh, [List<Map<String,dynamic>>? iks, double sphereSize = 0.25]) : super() {
    this.root = mesh;
    this.iks = iks ?? [];

    matrix.setFrom(mesh.matrixWorld);
    matrixAutoUpdate = false;

    sphereGeometry = SphereGeometry(sphereSize, 16, 8);

    targetSphereMaterial = MeshBasicMaterial.fromMap({
      'color': 0xff8888,
      'depthTest': false,
      'depthWrite': false,
      'transparent': true
    });

    effectorSphereMaterial = MeshBasicMaterial.fromMap({
      'color': 0x88ff88,
      'depthTest': false,
      'depthWrite': false,
      'transparent': true
    });

    linkSphereMaterial = MeshBasicMaterial.fromMap({
      'color': 0x8888ff,
      'depthTest': false,
      'depthWrite': false,
      'transparent': true
    });

    lineMaterial = LineBasicMaterial.fromMap({
      'color': 0xff0000,
      'depthTest': false,
      'depthWrite': false,
      'transparent': true
    });

    _init();
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    final mesh = root;

    if (visible) {
      int offset = 0;
      final iksList = iks;
      final bones = mesh.skeleton?.bones;

      _matrix.setFrom(mesh.matrixWorld).invert();

      for (int i = 0; i < iksList.length; i++) {
        final ik = iksList[i];
        final targetBone = bones?[ik['target']];
        final effectorBone = bones?[ik['effector']];

        final targetMesh = children[offset++];
        final effectorMesh = children[offset++];

        targetMesh.position.setFrom(getPosition(targetBone, _matrix));
        effectorMesh.position.setFrom(getPosition(effectorBone, _matrix));

        final List links = ik['links'] ?? [];
        for (int j = 0; j < links.length; j++) {
          final link = links[j];
          final linkBone = bones?[link['index']];
          final linkMesh = children[offset++];
          linkMesh.position.setFrom(getPosition(linkBone, _matrix));
        }

        final line = children[offset++];
        final array = line.geometry?.attributes['position'].array;

        setPositionOfBoneToAttributeArray(array, 0, targetBone, _matrix);
        setPositionOfBoneToAttributeArray(array, 1, effectorBone, _matrix);

        for (int j = 0; j < links.length; j++) {
          final link = links[j];
          final linkBone = bones?[link['index']];
          setPositionOfBoneToAttributeArray(array, j + 2, linkBone, _matrix);
        }

        line.geometry?.attributes['position'].needsUpdate = true;
      }
    }

    matrix.setFrom(mesh.matrixWorld);
    super.updateMatrixWorld(force);
  }

  /// Frees the GPU-related resources allocated by this instance.
  /// Call this method whenever this instance is no longer used in your app.
  void dispose() {
    sphereGeometry.dispose();
    targetSphereMaterial.dispose();
    effectorSphereMaterial.dispose();
    linkSphereMaterial.dispose();
    lineMaterial.dispose();

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Line) {
        child.geometry?.dispose();
      }
    }
  }

  // Private method wrapper
  void _init() {
    BufferGeometry createLineGeometry(dynamic ik) {
      final geometry = BufferGeometry();
      final List<Map<String,dynamic>> links = ik['links'] ?? [];
      final vertices = Float32List((2 + links.length) * 3);
      geometry.setAttributeFromString('position', Float16BufferAttribute.fromList(vertices, 3));
      return geometry;
    }

    Mesh createTargetMesh() {
      return Mesh(sphereGeometry, targetSphereMaterial);
    }

    Mesh createEffectorMesh() {
      return Mesh(sphereGeometry, effectorSphereMaterial);
    }

    Mesh createLinkMesh() {
      return Mesh(sphereGeometry, linkSphereMaterial);
    }

    Line createLine(Map<String,dynamic> ik) {
      return Line(createLineGeometry(ik), lineMaterial);
    }

    for (int i = 0; i < iks.length; i++) {
      final ik = iks[i];
      add(createTargetMesh());
      add(createEffectorMesh());

      final List links = ik['links'] ?? [];
      for (int j = 0; j < links.length; j++) {
        add(createLinkMesh());
      }

      add(createLine(ik));
    }
  }
}
