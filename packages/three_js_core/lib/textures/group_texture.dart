import './texture.dart';

class GroupTexture extends Texture {
  late List<Texture> children;
  GroupTexture([List<Texture>? children]){
    this.children = children ?? [];
  }
}