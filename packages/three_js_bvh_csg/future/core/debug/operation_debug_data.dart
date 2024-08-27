import 'package:three_js_core/objects/line.dart';
import 'package:three_js_math/three_js_math.dart';
import '../operations/operations_utils.dart';

class TriangleIntersectData {
  Triangle triangle;
  Map<int, Triangle> intersects = {};

  TriangleIntersectData(Triangle tri) : triangle = Triangle().copy(tri);

  void addTriangle(int index, Triangle tri) {
    intersects[index] = Triangle().copy(tri);
  }

  List<Triangle> getIntersectArray() {
    return intersects.values.toList();
  }
}

class TriangleIntersectionSets {
  Map<int, TriangleIntersectData> data = {};

  void addTriangleIntersection(int ia, Triangle triA, int ib, Triangle triB) {
    data.putIfAbsent(ia, () => TriangleIntersectData(triA));
    data[ia]!.addTriangle(ib, triB);
  }

  List<dynamic> getTrianglesAsArray(int? id) {
    const arr = [];
    if (id != null && data.containsKey(id)) {
      arr.add(data[id]!.triangle);
    } else {
      for (var key in data.keys) {
        arr.add(data[key]!.triangle);
      }
    }

    return arr;
  }

  List<int> getTriangleIndices() {
    return data.keys.toList();
  }

  List<int> getIntersectionIndices(int id) {
    if (!data.containsKey(id)) {
      return [];
    } else {
      return data[id]!.intersects.keys.toList();
    }
  }

  List<Triangle> getIntersectionsAsArray([int? id, int? id2]) {
    var triSet = <int>{};
    var arr = <Triangle>[];

    void addTriangles(int key) {
      if (!data.containsKey(key)) return;

      if (id2 != null && data[key]!.intersects.containsKey(id2)) {
        arr.add(data[key]!.intersects[id2]!);
      } else {
        data[key]!.intersects.forEach((key2, value) {
          if (!triSet.contains(key2)) {
            triSet.add(key2);
            arr.add(value);
          }
        });
      }
    }

    if (id != null) {
      addTriangles(id);
    } else {
      data.forEach((key, value) {
        addTriangles(key);
      });
    }

    return arr;
  }

  void reset() {
    data = {};
  }
}

class OperationDebugData {
  bool enabled = false;
  TriangleIntersectionSets triangleIntersectsA = TriangleIntersectionSets();
  TriangleIntersectionSets triangleIntersectsB = TriangleIntersectionSets();
  List<Line> intersectionEdges = [];

  void addIntersectingTriangles(int ia, Triangle triA, int ib, Triangle triB) {
    triangleIntersectsA.addTriangleIntersection(ia, triA, ib, triB);
    triangleIntersectsB.addTriangleIntersection(ib, triB, ia, triA);
  }

  void addEdge(Line edge) {
    intersectionEdges.add(edge.clone());
  }

  void reset() {
    triangleIntersectsA.reset();
    triangleIntersectsB.reset();
    intersectionEdges = [];
  }

  void init() {
    if (enabled) {
      reset();
      setDebugContext(this);
    }
  }

  void complete() {
    if (enabled) {
      setDebugContext(null);
    }
  }
}
