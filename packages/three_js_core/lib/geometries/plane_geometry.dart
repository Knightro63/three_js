import 'package:flutter_gl/flutter_gl.dart';
import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';

class PlaneGeometry extends BufferGeometry {
  PlaneGeometry([
    double width = 1,
    double height = 1,
    int widthSegments = 1,
    int heightSegments = 1]
  ): super() {
    type = 'PlaneGeometry';

    parameters = {
      "width": width,
      "height": height,
      "widthSegments": widthSegments,
      "heightSegments": heightSegments
    };

    double widthHalf = width / 2.0;
    double heightHalf = height / 2.0;

    int gridX1 = widthSegments + 1;
    int gridY1 = heightSegments + 1;

    double segmentWidth = width / widthSegments;
    double segmentHeight = height / heightSegments;

    //

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    for (int iy = 0; iy < gridY1; iy++) {
      final y = iy * segmentHeight - heightHalf;

      for (int ix = 0; ix < gridX1; ix++) {
        final x = ix * segmentWidth - widthHalf;

        vertices.addAll([x.toDouble(), -y.toDouble(), 0.0]);

        normals.addAll([0.0, 0.0, 1.0]);

        uvs.add(ix / widthSegments);
        uvs.add(1 - (iy / heightSegments));
      }
    }

    for (int iy = 0; iy < widthSegments; iy++) {
      for (int ix = 0; ix < heightSegments; ix++) {
        final a = ix + gridX1 * iy;
        final b = ix + gridX1 * (iy + 1);
        final c = (ix + 1) + gridX1 * (iy + 1);
        final d = (ix + 1) + gridX1 * iy;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }

    setIndex(indices);
    setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    setAttributeFromString('normal',Float32BufferAttribute(Float32Array.from(normals), 3, false));
    setAttributeFromString('uv', Float32BufferAttribute(Float32Array.from(uvs), 2, false));
  }

  static fromJson(data) {
    return PlaneGeometry(data["width"], data["height"],
        data["widthSegments"], data["heightSegments"]);
  }
}
