import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class LatheGeometry extends BufferGeometry {
  LatheGeometry(List<Vector2> points,{int segments = 12, double phiStart = 0, double phiLength = math.pi * 2}): super() {
    type = 'LatheGeometry';
    parameters = {
      "points": points,
      "segments": segments,
      "phiStart": phiStart,
      "phiLength": phiLength
    };

    segments = segments.floor();

    // clamp phiLength so it's in range of [ 0, 2PI ]

    phiLength = MathUtils.clamp(phiLength, 0, math.pi * 2);

    // buffers

    final indices = [];
    List<double> vertices = [];
    List<double> uvs = [];
    final initNormals = [];
    List<double> normals = [];

    // helper variables

    final inverseSegments = 1.0 / segments;
    final vertex = Vector3.zero();
    final uv = Vector2.zero();
    final normal = Vector3.zero();
    final curNormal = Vector3.zero();
    final prevNormal = Vector3.zero();
    double dx = 0;
    double dy = 0;

    // pre-compute normals for initial "meridian"

    for (int j = 0; j <= (points.length - 1); j++) {
      // special handling for 1st vertex on path
      if (j == 0) {
        dx = points[j + 1].x - points[j].x;
        dy = points[j + 1].y - points[j].y;

        normal.x = dy * 1.0;
        normal.y = -dx;
        normal.z = dy * 0.0;

        prevNormal.setFrom(normal);

        normal.normalize();

        initNormals.addAll([normal.x, normal.y, normal.z]);
      } else if (j == points.length - 1) {
        // special handling for last Vertex on path
        initNormals.addAll([prevNormal.x, prevNormal.y, prevNormal.z]);
      } else {
        // default handling for all vertices in between
        dx = points[j + 1].x - points[j].x;
        dy = points[j + 1].y - points[j].y;

        normal.x = dy * 1.0;
        normal.y = -dx;
        normal.z = dy * 0.0;

        curNormal.setFrom(normal);

        normal.x += prevNormal.x;
        normal.y += prevNormal.y;
        normal.z += prevNormal.z;

        normal.normalize();

        initNormals.addAll([normal.x, normal.y, normal.z]);

        prevNormal.setFrom(curNormal);
      }
    }

    // generate vertices, uvs and normals

    // generate vertices and uvs

    for (int i = 0; i <= segments; i++) {
      final phi = phiStart + i * inverseSegments * phiLength;

      final sin = math.sin(phi);
      final cos = math.cos(phi);

      for (int j = 0; j <= (points.length - 1); j++) {
        // vertex

        vertex.x = points[j].x * sin;
        vertex.y = points[j].y;
        vertex.z = points[j].x * cos;

        vertices.addAll(
            [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // uv

        uv.x = i / segments;
        uv.y = j / (points.length - 1);

        uvs.addAll([uv.x.toDouble(), uv.y.toDouble()]);

        // normal

        final x = initNormals[3 * j + 0] * sin;
        final y = initNormals[3 * j + 1];
        final z = initNormals[3 * j + 0] * cos;

        normals.addAll([x, y, z]);
      }
    }

    // indices

    for (int i = 0; i < segments; i++) {
      for (int j = 0; j < (points.length - 1); j++) {
        final base = j + i * points.length;

        final a = base;
        final b = base + points.length;
        final c = base + points.length + 1;
        final d = base + 1;

        // faces

        indices.addAll([a, b, d]);
        indices.addAll([c, d, b]);
      }
    }

    // build geometry

    setIndex(indices);
    setAttribute(Semantic.position, Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
    setAttribute(Semantic.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2, false));
    setAttribute(Semantic.normal,Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3, false));
  }
}
