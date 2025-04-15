import 'csg.dart';
import 'package:three_js_core/three_js_core.dart';

enum BooleanType{
  union,subtract,intersect;

  static BooleanType fromString(String name){
    for(final type in BooleanType.values){
      if(type.name == name){
        return type;
      }
    }

    return BooleanType.subtract;
  }
}

class Evaluator {
  static Mesh? evaluate(Mesh meshA, Mesh meshB, BooleanType type, [Mesh? result]){
    Mesh? mesh;
    switch (type) {
      case BooleanType.union:
        mesh = CSG.unionMesh(meshA, meshB);
        break;
      case BooleanType.subtract:
        mesh = CSG.subtractMesh(meshA, meshB);
        break;
      case BooleanType.intersect:
        mesh = CSG.intersectMesh(meshA, meshB);
        break;
    }

    if(result != null){
      result.geometry?.dispose();
      result.copy(mesh);
      mesh = null;
      return result;
    }
    else{
      return mesh;
    }
  }
  static Mesh? evaluate2(Mesh meshA, Mesh meshB, BooleanType type, [Mesh? result]){
    final csgA = CSG.fromMesh(meshA);
    final csgB = CSG.fromMesh(meshB);
    
    late final CSG res;

    switch (type) {
      case BooleanType.union:
        res = csgA.union(csgB);
        break;
      case BooleanType.subtract:
        res = csgA.subtract(csgB);
        break;
      case BooleanType.intersect:
        res = csgA.intersect(csgB);
        break;
    }
    
    Mesh? mesh = CSG.toMesh(res, meshA.matrix, meshB.material);
    if(result != null){
      result.copy(mesh);
      mesh = null;
      return result;
    }
    else{
      return mesh;
    }
  }
}