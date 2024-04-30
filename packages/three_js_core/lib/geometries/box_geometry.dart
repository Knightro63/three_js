import 'package:flutter_gl/flutter_gl.dart';
import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';

class BoxGeometry extends BufferGeometry {
  late int groupStart;
  late int numberOfVertices;

  BoxGeometry([
    double width = 1,
    double height = 1,
    double depth = 1,
    int widthSegments = 1,
    int heightSegments = 1,
    int depthSegments = 1
  ]):super() {
    type = "BoxGeometry";

    parameters = {
      "width": width,
      "height": height,
      "depth": depth,
      "widthSegments": widthSegments,
      "heightSegments": heightSegments,
      "depthSegments": depthSegments
    };

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    numberOfVertices = 0;
    groupStart = 0;

    void buildPlane(int u, int v, int w, double udir, double vdir, double width, double height, double depth, int gridX, int gridY, int materialIndex) {
      final segmentWidth = width / gridX;
      final segmentHeight = height / gridY;

      final widthHalf = width / 2;
      final heightHalf = height / 2;
      final depthHalf = depth / 2;

      final gridX1 = gridX + 1;
      final gridY1 = gridY + 1;

      int vertexCounter = 0;
      int groupCount = 0;

      final vector = Vector3.zero();

      for (int iy = 0; iy < gridY1; iy++) {
        final y = iy * segmentHeight - heightHalf;

        for (int ix = 0; ix < gridX1; ix++) {
          final x = ix * segmentWidth - widthHalf;

          vector[u] = x * udir;
          vector[v] = y * vdir;
          vector[w] = depthHalf;

          vertices.addAll([vector.x.toDouble(), vector.y.toDouble(), vector.z.toDouble()]);

          vector[u] = 0;
          vector[v] = 0;
          vector[w] = depth > 0 ? 1 : -1;

          normals.addAll([vector.x.toDouble(), vector.y.toDouble(), vector.z.toDouble()]);
          uvs.add(ix / gridX);
          uvs.add(1 - (iy / gridY));

          vertexCounter += 1;
        }
      }

      // indices

      // 1. you need three indices to draw a single face
      // 2. a single segment consists of two faces
      // 3. so we need to generate six (2*3) indices per segment

      for (int iy = 0; iy < gridY; iy++) {
        for (int ix = 0; ix < gridX; ix++) {
          final a = numberOfVertices + ix + gridX1 * iy;
          final b = numberOfVertices + ix + gridX1 * (iy + 1);
          final c = numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
          final d = numberOfVertices + (ix + 1) + gridX1 * iy;

          indices.addAll([a, b, d]);
          indices.addAll([b, c, d]);
          groupCount += 6;
        }
      }

      // add a group to the geometry. this will ensure multi material support

      addGroup(groupStart, groupCount, materialIndex);
      groupStart += groupCount;
      numberOfVertices += vertexCounter;
    }

    // build each side of the box geometry

    buildPlane(2,1,0, -1, -1, depth, height, width, depthSegments,heightSegments, 0); // px
    buildPlane(2,1,0, 1, -1, depth, height, -width, depthSegments,heightSegments, 1); // nx
    buildPlane(0,2,1, 1, 1, width, depth, height, widthSegments,depthSegments, 2); // py
    buildPlane(0,2,1, 1, -1, width, depth, -height, widthSegments,depthSegments, 3); // ny
    buildPlane(0,1,2, 1, -1, width, height, depth, widthSegments,heightSegments, 4); // pz
    buildPlane(0,1,2, -1, -1, width, height, -depth, widthSegments,heightSegments, 5); // nz

    // build geometry

    setIndex(indices);
    setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    setAttributeFromString('normal',Float32BufferAttribute(Float32Array.from(normals), 3, false));
    setAttributeFromString('uv', Float32BufferAttribute(Float32Array.from(uvs), 2, false));
  }

  static BoxGeometry fromJson(Map<String,dynamic> data) {
    return BoxGeometry(data["width"], data["height"], data["depth"],
        data["widthSegments"], data["heightSegments"], data["depthSegments"]);
  }
}
