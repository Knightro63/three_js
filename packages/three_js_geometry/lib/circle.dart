import 'dart:math';
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// [CircleGeometry] is a simple shape of Euclidean geometry. It is constructed from a
/// number of triangular segments that are oriented around a central point and
/// extend as far out as a given radius. It is built counter-clockwise from a
/// start angle and a given central angle. It can also be used to create
/// regular polygons, where the number of segments determines the number of
/// sides.
/// 
/// ```
/// final geometry = CircleGeometry(radius:5, segments:32); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class CircleGeometry extends BufferGeometry {

  /// [radius] — Radius of the circle, default = 1.
  /// 
  /// [segments] — Number of segments (triangles), minimum = `3`, default = `32`.
  /// 
  /// [thetaStart] — Start angle for first segment, default = `0` (three o'clock
  /// position).
  /// 
  /// [thetaLength] — The central angle, often called theta, of the circular
  /// sector. The default is `2`*pi, which makes for a complete circle.
  CircleGeometry({
    double radius = 1, 
    int segments = 8, 
    double thetaStart = 0, 
    double thetaLength = pi * 2
  }):super() {
    parameters = {
      "radius": radius,
      "segments": segments,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength
    };

    segments = max(3, segments);

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    final vertex = Vector3.zero();
    final uv = Vector2.zero();

    // center point

    vertices.addAll([0, 0, 0]);
    normals.addAll([0, 0, 1]);
    uvs.addAll([0.5, 0.5]);

    for (int s = 0, i = 3; s <= segments; s++, i += 3) {
      final segment = thetaStart + s / segments * thetaLength;

      // vertex

      vertex.x = radius * cos(segment);
      vertex.y = radius * sin(segment);

      vertices.addAll([vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

      // normal

      normals.addAll([0.0, 0.0, 1.0]);

      // uvs

      uv.x = (vertices[i] / radius + 1) / 2;
      uv.y = (vertices[i + 1] / radius + 1) / 2;

      uvs.addAll([uv.x.toDouble(), uv.y.toDouble()]);
    }

    // indices

    for (int i = 1; i <= segments; i++) {
      indices.addAll([i, i + 1, 0]);
    }

    // build geometry

    setIndex(indices);
    setAttribute(Semantic.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
    setAttribute(Semantic.normal,Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3, false));
    setAttribute(Semantic.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2, false));
  }
}
