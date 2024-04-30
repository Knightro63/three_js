import '../core/index.dart';

class Group extends Object3D {
  bool isGroup = true;

  Group() : super() {
    type = 'Group';
  }

  Group.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'Group';
  }
}
