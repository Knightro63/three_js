import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'convex_hull.dart';
import 'package:three_js_math/three_js_math.dart';

class ConvexGeometry extends BufferGeometry {
  ConvexGeometry(List<Vector3> points) : super() {
    List<double> vertices = [];
    List<double> normals = [];

    // buffers

    final convexHull = ConvexHull().setFromPoints(points);

    // generate vertices and normals

    final faces = convexHull.faces;

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      HalfEdge? edge = face.edge;

      // we move along a doubly-connected edge list to access all face points (see HalfEdge docs)

      do {
        final point = edge!.head().point;

        vertices.addAll(
            [point.x.toDouble(), point.y.toDouble(), point.z.toDouble()]);
        normals.addAll([
          face.normal.x.toDouble(),
          face.normal.y.toDouble(),
          face.normal.z.toDouble()
        ]);

        edge = edge.next;
      } while (edge != face.edge);
    }

    // build geometry

    setAttribute(Semantic.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
    setAttribute(Semantic.normal,Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3, false));
  }
}
