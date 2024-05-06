import '../core/index.dart';

/// This is almost identical to an [Object3D]. Its purpose is to
/// make working with animatins of objects syntactically clearer.
/// ```
/// final geometry = BoxGeometry(1, 1, 1);
/// final material = MeshBasicMaterial({MaterialProperty.color: 0x00ff00});
///
/// final cubeA = Mesh(geometry, material);
/// cubeA.position.setValues(100,100,0);
///
/// final cubeB = Mesh(geometry, material);
/// cubeB.position.setValues(-100,-100,0);
///
/// //create a group and add the two cubes
/// //These cubes can now be rotated / scaled etc as a group
/// final group = Group();
/// group.add(cubeA);
/// group.add(cubeB);
///
/// scene.add(group);
/// ```
class Group extends Object3D {
  bool isGroup = true;

  Group() : super() {
    type = 'Group';
  }

  Group.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'Group';
  }
}
