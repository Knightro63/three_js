import 'package:example/notworking/csg/csg.dart';
import 'package:three_js/three_js.dart';

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
  static Mesh? evaluate(Mesh objectA, Mesh objectB, BooleanType type, [Mesh? result]){
    final csgA = CSG.fromMesh(objectA);
    final csgB = CSG.fromMesh(objectB);

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
      default:
    }
    final mesh = CSG.toMesh(res, objectA.matrix, objectA.material);
    if(result != null){
      result.copy(mesh);
      mesh.dispose();
      return result;
    }
    else{
      return mesh;
    }
  }
}