import 'package:three_js_math/three_js_math.dart';

class MorphTarget {
  late String name;
  late List<Vector3> vertices;
  late List<Vector3> normals;
  
  MorphTarget(this.name,this.vertices,this.normals);
  MorphTarget.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      if (json["name"] != null) name = json["name"];
      if (json["vertices"] != null) vertices = json["vertices"];
      if (json["normals"] != null) normals = json["normals"];
    }
  }

  void dispose(){
    vertices.clear();
    normals.clear();
  }
}

class MorphColor {
  late String name;
  late List<Color> colors;
}

class MorphNormals {
  late String name;
  late List<Vector3> normals;
  late List<List<Vector3>> vertexNormals;
  late List<Vector3> faceNormals;
}