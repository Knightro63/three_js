import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// This can be used as a helper object to view a [BufferGeometry] as a wireframe.
/// 
/// ```
/// final geometry = SphereGeometry( 100, 100, 100 );
///
/// final wireframe = WireframeGeometry( geometry );
///
/// final line = LineSegments(wireframe);
/// line.material.depthTest = false;
/// line.material.opacity = 0.25;
/// line.material.transparent = true;
///
/// scene.add( line );
/// ```
class WireframeGeometry extends BufferGeometry {

  /// [geometry] — any geometry object.
  WireframeGeometry(BufferGeometry geometry) : super() {
    type = "WireframeGeometry";
    // buffer

    List<double> vertices = [];
    final edges = <dynamic>{};

    // helper variables

    final start = Vector3.zero();
    final end = Vector3.zero();

    if (geometry.index != null) {
      // indexed BufferGeometry

      final position = geometry.attributes[Attribute.position.name];
      final indices = geometry.index;
      List<Map<String,dynamic>> groups = geometry.groups;

      if (groups.isEmpty) {
        groups = [{"start": 0, "count": indices!.count, "materialIndex": 0}];
      }

      // create a data structure that contains all eges without duplicates

      for (int o = 0, ol = groups.length; o < ol; ++o) {
        final group = groups[o];

        final groupStart = group["start"]!;
        final groupCount = group["count"]!;

        for (int i = groupStart, l = (groupStart + groupCount); i < l; i += 3) {
          for (int j = 0; j < 3; j++) {
            int index1 = indices!.getX(i + j)!.toInt();
            int index2 = indices.getX(i + (j + 1) % 3)!.toInt();

            start.fromBuffer(position!, index1);
            end.fromBuffer(position, index2);

            if (isUniqueEdge(start, end, edges) == true) {
              vertices.addAll(
                  [start.x.toDouble(), start.y.toDouble(), start.z.toDouble()]);
              vertices.addAll(
                  [end.x.toDouble(), end.y.toDouble(), end.z.toDouble()]);
            }
          }
        }
      }
    } 
    else {
      // non-indexed BufferGeometry

      final position = geometry.attributes[Attribute.position.name];

      for (int i = 0, l = (position!.count ~/ 3); i < l; i++) {
        for (int j = 0; j < 3; j++) {
          // three edges per triangle, an edge is represented as (index1, index2)
          // e.g. the first triangle has the following edges: (0,1),(1,2),(2,0)

          final index1 = 3 * i + j;
          final index2 = 3 * i + ((j + 1) % 3);

          start.fromBuffer(position, index1);
          end.fromBuffer(position, index2);

          if (isUniqueEdge(start, end, edges) == true) {
            vertices.addAll(
                [start.x.toDouble(), start.y.toDouble(), start.z.toDouble()]);
            vertices
                .addAll([end.x.toDouble(), end.y.toDouble(), end.z.toDouble()]);
          }
        }
      }
    }

    // build geometry

    setAttribute(Attribute.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
  }
}

bool isUniqueEdge(Vector3 start, Vector3 end, edges) {
  final hash1 = "${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}";
  final hash2 =
      "${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}"; // coincident edge

  if (edges.contains(hash1) == true || edges.contains(hash2) == true) {
    return false;
  } else {
    edges.addAll([hash1, hash2]);
    return true;
  }
}
