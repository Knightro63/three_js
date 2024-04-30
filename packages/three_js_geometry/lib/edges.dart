import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class EdgesGeometry extends BufferGeometry {
  final _v0 = Vector3.zero();
  final _v1 = Vector3.zero();
  final _normal = Vector3.zero();
  final _triangle = Triangle.init();

  EdgesGeometry(BufferGeometry geometry, double? thresholdAngle) : super() {
    type = "EdgesGeometry";
    parameters = {"thresholdAngle": thresholdAngle};

    thresholdAngle = (thresholdAngle != null) ? thresholdAngle : 1;

    //final precisionPoints = 4;
    //final precision = math.pow(10, precisionPoints);
    final thresholdDot = math.cos((math.pi/180) * thresholdAngle);

    final indexAttr = geometry.getIndex();
    final positionAttr = geometry.getAttribute(Semantic.position);
    final indexCount = indexAttr != null ? indexAttr.count : positionAttr.count;

    final indexArr = [0, 0, 0];
    final vertKeys = ['a', 'b', 'c'];
    Map hashes = {};

    final edgeData = {};
    List<double> vertices = [];
    for (int i = 0; i < indexCount; i += 3) {
      if (indexAttr != null) {
        indexArr[0] = indexAttr.getX(i)!.toInt();
        indexArr[1] = indexAttr.getX(i + 1)!.toInt();
        indexArr[2] = indexAttr.getX(i + 2)!.toInt();
      } else {
        indexArr[0] = i;
        indexArr[1] = i + 1;
        indexArr[2] = i + 2;
      }

      final a = _triangle.a;
      final b = _triangle.b;
      final c = _triangle.c;

      a.fromBuffer(positionAttr, indexArr[0]);
      b.fromBuffer(positionAttr, indexArr[1]);
      c.fromBuffer(positionAttr, indexArr[2]);
      _triangle.getNormal(_normal);

      // create hashes for the edge from the vertices
      hashes[0] = "${a.x},${a.y},${a.z}";
      hashes[1] = "${b.x},${b.y},${b.z}";
      hashes[2] = "${c.x},${c.y},${c.z}";

      // skip degenerate triangles
      if (hashes[0] == hashes[1] ||
          hashes[1] == hashes[2] ||
          hashes[2] == hashes[0]) {
        continue;
      }

      // iterate over every edge
      for (int j = 0; j < 3; j++) {
        // get the first and next vertex making up the edge
        final jNext = (j + 1) % 3;
        final vecHash0 = hashes[j];
        final vecHash1 = hashes[jNext];
        final v0 = _triangle[vertKeys[j]];
        final v1 = _triangle[vertKeys[jNext]];

        final hash = "${vecHash0}_$vecHash1";
        final reverseHash = "${vecHash1}_$vecHash0";

        if (edgeData.containsKey(reverseHash) &&
            edgeData[reverseHash] != null) {
          // if we found a sibling edge add it into the vertex array if
          // it meets the angle threshold and delete the edge from the map.
          if (_normal.dot(edgeData[reverseHash]["normal"]) <= thresholdDot) {
            vertices
                .addAll([v0.x.toDouble(), v0.y.toDouble(), v0.z.toDouble()]);
            vertices
                .addAll([v1.x.toDouble(), v1.y.toDouble(), v1.z.toDouble()]);
          }

          edgeData[reverseHash] = null;
        } else if (!(edgeData.containsKey(hash))) {
          // if we've already got an edge here then skip adding a new one
          edgeData[hash] = {
            "index0": indexArr[j],
            "index1": indexArr[jNext],
            "normal": _normal.clone(),
          };
        }
      }
    }

    // iterate over all remaining, unmatched edges and add them to the vertex array
    for (final key in edgeData.keys) {
      if (edgeData[key] != null) {
        final ed = edgeData[key];
        final index0 = ed["index0"];
        final index1 = ed["index1"];
        _v0.fromBuffer(positionAttr, index0);
        _v1.fromBuffer(positionAttr, index1);

        vertices.addAll([_v0.x.toDouble(), _v0.y.toDouble(), _v0.z.toDouble()]);
        vertices.addAll([_v1.x.toDouble(), _v1.y.toDouble(), _v1.z.toDouble()]);
      }
    }

    setAttribute(Semantic.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
  }
}
