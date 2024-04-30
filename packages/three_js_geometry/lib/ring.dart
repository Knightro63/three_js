import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class RingGeometry extends BufferGeometry {
  RingGeometry([
    double innerRadius = 0.5,
    double outerRadius = 1,
    int thetaSegments = 8,
    int phiSegments = 1,
    double thetaStart = 0,
    double thetaLength = math.pi * 2
  ]): super() {
    type = 'RingGeometry';
    parameters = {
      "innerRadius": innerRadius,
      "outerRadius": outerRadius,
      "thetaSegments": thetaSegments,
      "phiSegments": phiSegments,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength
    };

    thetaSegments = math.max(3, thetaSegments);
    phiSegments = math.max(1, phiSegments);

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // some helper variables

    double radius = innerRadius;
    final radiusStep = ((outerRadius - innerRadius) / phiSegments);
    final vertex = Vector3.zero();
    final uv = Vector2.zero();

    // generate vertices, normals and uvs

    for (int j = 0; j <= phiSegments; j++) {
      for (int i = 0; i <= thetaSegments; i++) {
        // values are generate from the inside of the ring to the outside

        final segment = thetaStart + i / thetaSegments * thetaLength;

        // vertex

        vertex.x = radius * math.cos(segment);
        vertex.y = radius * math.sin(segment);

        vertices.addAll(
            [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // normal

        normals.addAll([0, 0, 1]);

        // uv

        uv.x = (vertex.x / outerRadius + 1) / 2;
        uv.y = (vertex.y / outerRadius + 1) / 2;

        uvs.addAll([uv.x.toDouble(), uv.y.toDouble()]);
      }

      // increase the radius for next row of vertices

      radius += radiusStep;
    }

    // indices

    for (int j = 0; j < phiSegments; j++) {
      final thetaSegmentLevel = j * (thetaSegments + 1);
      for (int i = 0; i < thetaSegments; i++) {
        final segment = i + thetaSegmentLevel;

        final a = segment;
        final b = segment + thetaSegments + 1;
        final c = segment + thetaSegments + 2;
        final d = segment + 1;

        // faces

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }

    // build geometry

    setIndex(indices);
    setAttribute(Semantic.position, Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3));
    setAttribute(Semantic.normal, Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3));
    setAttribute(Semantic.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2));
  }
}
