import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// A class for generating a two-dimensional ring geometry.
/// 
/// ```
/// final geometry = RingGeometry( 1,5,32); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class RingGeometry extends BufferGeometry {
  /// [innerRadius] — Default is `0.5`.
  /// 
  /// [outerRadius] — Default is `1`.
  /// 
  /// [thetaSegments] — Number of segments. A higher number means the ring will be
  /// more round. Minimum is `3`. Default is `32`.
  /// 
  /// [phiSegments] — Number of segments per ring segment. Minimum is `1`. Default is `1`.
  /// 
  /// [thetaStart] — Starting angle. Default is `0`.
  /// 
  /// [thetaLength] — Central angle. Default is `pi` * 2.
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
    setAttribute(Attribute.position, Float32BufferAttribute.fromList(vertices, 3));
    setAttribute(Attribute.normal, Float32BufferAttribute.fromList(normals, 3));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromList(uvs, 2));
  }
}
