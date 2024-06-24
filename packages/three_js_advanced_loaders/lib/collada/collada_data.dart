

import 'package:three_js_core/three_js_core.dart';

class ColladaData{
  ColladaData({
    this.scene,
    this.library,
    this.animations,
    this.kinematics,
  });

  Object3D? scene;
  Map<String,Map<String,dynamic>>? library;
  List? animations;
  Map<String,dynamic>? kinematics;
}