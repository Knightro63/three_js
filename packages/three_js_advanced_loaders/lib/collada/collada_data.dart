import 'package:three_js_core/three_js_core.dart';

class KinematicsData{
  dynamic joints;
  double? Function(String)? getJointValue;
  void Function(String,double)? setJointValue;

  KinematicsData({
    this.joints,
    this.getJointValue,
    this.setJointValue
  });
}

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
  KinematicsData? kinematics;
}