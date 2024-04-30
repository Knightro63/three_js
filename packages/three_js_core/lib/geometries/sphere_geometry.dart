import 'package:flutter_gl/flutter_gl.dart';
import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class SphereGeometry extends BufferGeometry {
  SphereGeometry([
    double radius = 1,
    int widthSegments = 32,
    int heightSegments = 16,
    double phiStart = 0,
    double phiLength = math.pi * 2,
    double thetaStart = 0,
    double thetaLength = math.pi
  ]):super() {
    type = "SphereGeometry";
    parameters = {
      "radius": radius,
      "widthSegments": widthSegments,
      "heightSegments": heightSegments,
      "phiStart": phiStart,
      "phiLength": phiLength,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength
    };

    widthSegments = math.max(3, widthSegments);
    heightSegments = math.max(2, heightSegments);

    final thetaEnd = math.min<double>(thetaStart + thetaLength, math.pi);

    int index = 0;
    final grid = [];

    final vertex = Vector3.zero();
    final normal = Vector3.zero();

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // generate vertices, normals and uvs

    for (int iy = 0; iy <= heightSegments; iy++) {
      final verticesRow = [];
      final v = iy / heightSegments;
      double uOffset = 0;

      if (iy == 0 && thetaStart == 0) {
        uOffset = 0.5 / widthSegments;
      } else if (iy == heightSegments && thetaEnd == math.pi) {
        uOffset = -0.5 / widthSegments;
      }

      for (int ix = 0; ix <= widthSegments; ix++) {
        final u = ix / widthSegments;

        vertex.x = -radius *
            math.cos(phiStart + u * phiLength) *
            math.sin(thetaStart + v * thetaLength);
        vertex.y = radius * math.cos(thetaStart + v * thetaLength);
        vertex.z = radius *
            math.sin(phiStart + u * phiLength) *
            math.sin(thetaStart + v * thetaLength);

        vertices.addAll([vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        normal.setFrom(vertex);
        normal.normalize();
        normals.addAll([normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);
        uvs.addAll([u + uOffset, 1 - v]);
        verticesRow.add(index++);
      }

      grid.add(verticesRow);
    }

    // indices

    for (int iy = 0; iy < heightSegments; iy++) {
      for (int ix = 0; ix < widthSegments; ix++) {
        final a = grid[iy][ix + 1];
        final b = grid[iy][ix];
        final c = grid[iy + 1][ix];
        final d = grid[iy + 1][ix + 1];

        if (iy != 0 || thetaStart > 0) indices.addAll([a, b, d]);
        if (iy != heightSegments - 1 || thetaEnd < math.pi) {
          indices.addAll([b, c, d]);
        }
      }
    }

    // build geometry

    setIndex(indices);
    setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    setAttributeFromString('normal',Float32BufferAttribute(Float32Array.from(normals), 3, false));
    setAttributeFromString('uv', Float32BufferAttribute(Float32Array.from(uvs), 2, false));
  }

  static fromJson(data) {
    return SphereGeometry(
        data["radius"],
        data["widthSegments"],
        data["heightSegments"],
        data["phiStart"],
        data["phiLength"],
        data["thetaStart"],
        data["thetaLength"]);
  }
}
