import 'package:three_js_core/three_js_core.dart';
import '../animations/animation_clip.dart';

/// This is almost identical to an [Group]. Its purpose is to
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
/// final animationObject = AnimationObject();
/// animationObject.add(cubeA);
/// animationObject.add(cubeB);
///
/// scene.add(animationObject);
/// ```
class AnimationObject extends Group{
  List<AnimationClip> animations = [];

  AnimationObject() : super() {
    type = 'AnimationObject';
  }

  AnimationObject.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'AnimationObject';
  }
}