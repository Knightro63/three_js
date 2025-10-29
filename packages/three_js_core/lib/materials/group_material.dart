import './material.dart';

class GroupMaterial extends Material {
  List<Material> children = [];

  GroupMaterial([List<Material>? children]) : super() {
    this.children = children ?? [];
    type = "GroupMaterial";
  }

  void add(Material material){
    children.add(material);
  }

  @override
  GroupMaterial copy(Material source) {
    super.copy(source);

    if(source is GroupMaterial){
      children = source.children.sublist(0);
    }

    return this;
  }

  @override
  void dispose(){
    super.dispose();

    children.forEach((mat){
      mat.dispose();
    });
  }

  /// Return a new material with the same parameters as this material.
  @override
  GroupMaterial clone() {
    return GroupMaterial()..copy(this);
  }
}
