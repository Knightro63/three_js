import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'utils/hash_utils.dart';
import 'utils/geometry_utils.dart';
import 'utils/compute_disjoint_edges.dart';

Vector2 _vec2 = Vector2.zero();
Vector3 _vec3 = Vector3.zero();
Vector4 _vec4 = Vector4.zero();
List<String> _hashes = ['', '', ''];

class HalfEdgeMap {
  // result data
  Int32List? data;
  Map<int, List<int>>? disjointConnections;
  Map<int, List<int>>? unmatchedDisjointEdges;
  int unmatchedEdges = -1;
  int matchedEdges = -1;

  // options
  bool useDrawRange = true;
  bool useAllAttributes = false;
  bool matchDisjointEdges = false;
  double degenerateEpsilon = 1e-8;

  HalfEdgeMap([BufferGeometry? geometry]) {
    if (geometry != null) {
      updateFrom(geometry);
    }
  }

  int getSiblingTriangleIndex(int triIndex, int edgeIndex) {
    int otherIndex = data![triIndex * 3 + edgeIndex];
    return otherIndex == -1 ? -1 : (otherIndex ~/ 3);
  }

  int getSiblingEdgeIndex(int triIndex, int edgeIndex) {
    int otherIndex = data![triIndex * 3 + edgeIndex];
    return otherIndex == -1 ? -1 : (otherIndex % 3);
  }

  List<int> getDisjointSiblingTriangleIndices(int triIndex, int edgeIndex) {
    int index = triIndex * 3 + edgeIndex;
    List<int>? arr = disjointConnections?[index];
    return arr != null ? arr.map((i) => (i ~/ 3)).toList() : [];
  }

  List<int> getDisjointSiblingEdgeIndices(int triIndex, int edgeIndex) {
    int index = triIndex * 3 + edgeIndex;
    List<int>? arr = disjointConnections?[index];
    return arr != null ? arr.map((i) => i % 3).toList() : [];
  }

  bool isFullyConnected() {
    return unmatchedEdges == 0;
  }

  void updateFrom(BufferGeometry geometry) {
    bool useAllAttributes = this.useAllAttributes;
    bool useDrawRange = this.useDrawRange;
    bool matchDisjointEdges = this.matchDisjointEdges;
    double degenerateEpsilon = this.degenerateEpsilon;
    // hashFunction old location

    // runs on the assumption that there is a 1 : 1 match of edges
    Map<String, int> map = {};

    // attributes
    var attributes = geometry.attributes;
    var attrKeys = useAllAttributes ? attributes.keys.toList() : null;
    var indexAttr = geometry.index;
    var posAttr = attributes['position'];

    // hashPositionAttribute and hashAllAttributes new location
    String hashPositionAttribute(int i) {
      _vec3.fromBuffer(posAttr, i);
      return hashVertex3(_vec3);
    }

    String hashAllAttributes(int i) {
      String result = '';
      for (int k = 0, l = (attrKeys?.length ?? 0); k < l; k++) {
        final Float32BufferAttribute attr = attributes[attrKeys![k]];
        String str = '';
        switch (attr.itemSize) {
          case 1:
            str = hashNumber(attr.getX(i)!.toDouble()).toString();
            break;
          case 2:
            str = hashVertex2(_vec2.fromBuffer(attr, i));
            break;
          case 3:
            str = hashVertex3(_vec3.fromBuffer(attr, i));
            break;
          case 4:
            str = hashVertex4(_vec4.fromBuffer(attr, i));
            break;
        }

        if (result != '') {
          result += '|';
        }

        result += str;
      }

      return result;
    }

    // hashFunction new location
    var hashFunction = useAllAttributes ? hashAllAttributes : hashPositionAttribute;

    // get the potential number of triangles
    int triCount = getTriCount(geometry);
    int maxTriCount = triCount;

    // get the real number of triangles from the based on the draw range
    int offset = 0;
    if (useDrawRange) {
      offset = geometry.drawRange['start']!;
      if (geometry.drawRange['count'] != double.maxFinite.toInt()) {
        triCount = (geometry.drawRange['count']! ~/ 3);
      }
    }

    // initialize the connectivity buffer - 1 means no connectivity
    var data = this.data;
    if (data == null || data.length < 3 * maxTriCount) {
      data = Int32List(3 * maxTriCount);
    }

    data.fillRange(0, data.length, -1);

    // iterate over all triangles
    int matchedEdges = 0;
    List<int> unmatchedSet = [];
    for (int i = offset, l = triCount * 3 + offset; i < l; i += 3) {
      int i3 = i;

      for (int e = 0; e < 3; e++) {
        int i0 = i3 + e;
        if (indexAttr != null) {
          i0 = indexAttr.getX(i0)!.toInt();
        }

        _hashes[e] = hashFunction(i0);
      }

      for (int e = 0; e < 3; e++) {
        int nextE = (e + 1) % 3;
        String vh0 = _hashes[e];
        String vh1 = _hashes[nextE];
        String reverseHash = '${vh1}_$vh0';

        if (map.containsKey(reverseHash)) {
          // create a reference between the two triangles and clear the hash
          int index = i3 + e;
          int otherIndex = map[reverseHash]!;
          data[index] = otherIndex;
          data[otherIndex] = index;
          map.remove(reverseHash);
          matchedEdges += 2;
          unmatchedSet.remove(otherIndex);
        } else {
          // save the triangle and triangle edge index captured in one value
          // triIndex = ~ ~ ( i0 / 3 );
          // edgeIndex = i0 % 3;
          String hash = '${vh0}_$vh1';
          int index = i3 + e;
          map[hash] = index;
          unmatchedSet.add(index);
        }
      }
    }

    if (matchDisjointEdges) {
      var result = computeDisjointEdges(geometry, unmatchedSet, degenerateEpsilon);

      unmatchedSet.clear();
      result['fragmentMap'].forEach((key, value) {
        value['forward'].forEach((item) => unmatchedSet.add(item['index']));
        value['reverse'].forEach((item) => unmatchedSet.add(item['index']));
      });

      unmatchedDisjointEdges = result['fragmentMap'];
      disjointConnections = result['disjointConnectivityMap'];
      matchedEdges = triCount * 3 - unmatchedSet.length;
    }

    this.matchedEdges = matchedEdges;
    unmatchedEdges = unmatchedSet.length;
    this.data = data;
  }

  // hashPositionAttribute and hashAllAttributes old location
}
