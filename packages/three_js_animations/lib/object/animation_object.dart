import 'package:three_js_core/three_js_core.dart';
import '../animations/animation_clip.dart';

class AnimationObject extends Group{
  List<AnimationClip> animations = [];

  AnimationObject() : super() {
    type = 'AnimationObject';
  }

  AnimationObject.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'AnimationObject';
  }
}