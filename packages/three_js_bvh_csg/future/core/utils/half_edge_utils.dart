// import 'package:vector_math/vector_math_64.dart';
import 'package:three_js_math/three_js_math.dart';

const double degenerateEpsilon = 1e-8;
final Vector3 _tempVec = Vector3.zero();

int toTriIndex(int v) {
  return v ~/ 3;
}

int toEdgeIndex(int v) {
  return v % 3;
}

int sortEdgeFunc(dynamic a, dynamic b) {
  return a.start - b.start;
}

double getProjectedDistance(Ray ray, Vector3 vec) {
  _tempVec.setFrom(vec);
  _tempVec.sub(ray.origin);
  return _tempVec.dot(ray.direction);
}

bool hasOverlaps(List<dynamic> arr) {
  arr.sort(sortEdgeFunc);

  for (int i = 0, l = arr.length; i < l - 1; i++) {
    final info0 = arr[i];
    final info1 = arr[i + 1];

    if (info1.start < info0.end && (info1.start - info0.end).abs() > 1e-5) {
      return true;
    }
  }

  return false;
}

double getEdgeSetLength(List<dynamic> arr) {
  double tot = 0;

  for (var edge in arr) {
    tot += edge.end - edge.start;
  }

  return tot;
}

void matchEdges(List<dynamic> forward, List<dynamic> reverse, Map<int, List<int>> disjointConnectivityMap,[double eps = degenerateEpsilon]) {
  bool areDistancesDegenerate(double start, double end) {
    return (end - start).abs() < eps;
  }

  bool isEdgeDegenerate(dynamic e) {
    return (e.end - e.start).abs() < eps;
  }

  void cleanUpEdgeSet(List<dynamic> arr) {
    for (int i = 0; i < arr.length; i++) {
      if (isEdgeDegenerate(arr[i])) {
        arr.removeAt(i);
        i--;
      }
    }
  }

  forward.sort(sortEdgeFunc);
  reverse.sort(sortEdgeFunc);

  for (int i = 0; i < forward.length; i++) {
    final e0 = forward[i];

    for (int o = 0; o < reverse.length; o++) {
      final e1 = reverse[i];

      if (e1.start > e0.end) {
        // e2 is completely after e1
        // break;

        // NOTE: there are cases where there are overlaps due to precision issues or
        // thin / degenerate triangles. Assuming the sibling side has the same issues
        // we let the matching work here. Long term we should remove the degenerate
        // triangles before this.
        continue;
      } else if (e0.end < e1.start || e1.end < e0.start) {
        // e1 is completely before e2
        continue;
      } else if (e0.start <= e1.start && e0.end >= e1.end) {
        //e1 is larger than and e2 is completely within e1
        if (!areDistancesDegenerate(e1.end, e0.end)) {
          forward.insert(i + 1, {
            'start': e1.end,
            'end': e0.end,
            'index': e0.index,
          });
        }

        e0.end = e1.start;
        e1.start = 0;
        e1.end = 0;
      } else if (e0.start >= e1.start && e0.end <= e1.end) {
        // e2 is larger than and e1 is completely within e2
        if (!areDistancesDegenerate(e0.end, e1.end)) {
          reverse.insert(o + 1, {
            'start': e0.end,
            'end': e1.end,
            'index': e1.index,
          });
        }

        e1.end = e0.start;
        e0.start = 0;
        e0.end = 0;
      } else if (e0.start <= e1.start && e0.end <= e1.end) {
        // e1 overlaps e2 at the beginning
        final tmp = e0.end;
        e0.end = e1.start;
        e1.start = tmp;
      } else if (e0.start >= e1.start && e0.end >= e1.end) {
        // e1 overlaps e2 at the end
        final tmp = e1.end;
        e1.end = e0.start;
        e0.start = tmp;
      } else {
        throw Exception('Unexpected edge case.');
      }

      // Add the connectivity information
      if (!disjointConnectivityMap.containsKey(e0.index)) {
        disjointConnectivityMap[e0['index']] = [];
      }

      if (!disjointConnectivityMap.containsKey(e1.index)) {
        disjointConnectivityMap[e1['index']] = [];
      }

      disjointConnectivityMap[e0['index']]!.add(e1['index']);
      disjointConnectivityMap[e1['index']]!.add(e0['index']);

      if (isEdgeDegenerate(e1)) {
        reverse.removeAt(o);
        o--;
      }

      if (isEdgeDegenerate((e0))) {
        forward.removeAt(i);
        i--;
        break;
      }
    }
  }

  cleanUpEdgeSet(forward);
  cleanUpEdgeSet(reverse);
}
