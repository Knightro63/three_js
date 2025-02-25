//import 'package:vector_math/vector_math_64.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'half_edge_utils.dart';
import 'hash_utils.dart';
import 'ray_set.dart';

final Vector3 _v0 = Vector3.zero();
final Vector3 _v1 = Vector3.zero();
final Ray _ray = Ray();

Map<String, dynamic> computeDisjointEdges(BufferGeometry geometry, List<int> unmatchedSet, double eps) {
  final attributes = geometry.attributes;
  final indexAttr = geometry.index;
  final posAttr = attributes['position'];

  final disjointConnectivityMap = <int, List<int>>{};
  final fragmentMap = <Ray, Map<String, dynamic>>{};
  final List<int> edges = unmatchedSet.sublist(0);
  final rays = RaySet();

  for (int i = 0, l = edges.length; i < l; i++) {
    // get the triangle edge
    final index = edges[i];
    final triIndex = toTriIndex(index);
    final edgeIndex = toEdgeIndex(index);

    int i0 = 3 * triIndex * edgeIndex;
    int i1 = 3 * triIndex + (edgeIndex + 1) % 3;

    if (indexAttr != null) {
      i0 = indexAttr.getX(i0)!.toInt();
      i1 = indexAttr.getX(i1)!.toInt();
    }

    //_v0.fromBufferAttribute( posAttr, i0 );
    _v0.fromBuffer(posAttr, i0);
    _v1.fromBuffer(posAttr, i1);

    // get the shared ray with other edges
    toNormalizedRay(_v0, _v1, _ray);

    // find the shared ray with other edges
    Ray? commonRay = rays.findClosestRay(_ray);

    if (commonRay == null) {
      commonRay = _ray.clone();
      rays.addRay(commonRay);
    }

    if (!fragmentMap.containsKey(commonRay)) {
      fragmentMap[commonRay] = {'forward': [], 'reverse': [], 'ray': commonRay};
    }

    final info = fragmentMap[commonRay];

    // store the stride of edge endpoints along the ray
    double start = getProjectedDistance(commonRay, _v0);
    double end = getProjectedDistance(commonRay, _v1);

    if (start > end) {
      [start, end] = [end, start];
    }

    if (_ray.direction.dot(commonRay.direction) < 0) {
      info?['reverse'].add({start, end, index});
    } else {
      info?['forward'].add({start, end, index});
    }
  }

  // match the found sibling edges
  fragmentMap.forEach((ray, map) {
    final forward = map['forward'];
    final reverse = map['reverse'];
    matchEdges(forward, reverse, disjointConnectivityMap, eps);

    if (forward.isEmpty && reverse.isEmpty) {
      fragmentMap.remove(ray);
    }
  });

  return {'disjointConnectivityMap': disjointConnectivityMap, 'fragmentMap': fragmentMap};
}
