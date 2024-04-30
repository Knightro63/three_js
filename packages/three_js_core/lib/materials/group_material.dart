import './material.dart';

class GroupMaterial extends Material {
  List<Material> children = [];

  GroupMaterial([List<Material>? children]) : super() {
    this.children = children ?? [];
    type = "GroupMaterial";
  }
}
