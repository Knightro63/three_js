import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// A polyhedron is a solid in three dimensions with flat faces. This class
/// will take an array of vertices, project them onto a sphere, and then
/// divide them up to the desired level of detail. This class is used by
/// [DodecahedronGeometry], [IcosahedronGeometry],
/// [OctahedronGeometry], and [TetrahedronGeometry] to generate
/// their respective geometries.
class PolyhedronGeometry extends BufferGeometry {
  /// [vertices] — [List<double>] of points of the form [1,1,1, -1,-1,-1, ... ]
  /// 
  /// [indices] — [List<int>] of indices that make up the faces of the form
  /// [0,1,2, 2,3,0, ... ] 
  /// 
  /// [radius] — [double] - The radius of the final shape 
  /// 
  /// [detail] — [int] - How many levels to subdivide the geometry. The
  /// more detail, the smoother the shape.
  PolyhedronGeometry(List<double> vertices, List<int> indices, [double radius = 1, int detail = 0]) : super() {
    type = "PolyhedronGeometry";
    // default buffer data
    List<double> vertexBuffer = [];
    List<double> uvBuffer = [];

    // helper functions ----------------- start
    void pushVertex(vertex) {
      vertexBuffer.addAll([vertex.x, vertex.y, vertex.z]);
    }

    void subdivideFace(Vector3 a, Vector3 b, Vector3 c, int detail) {
      final cols = detail + 1;

      // we use this multidimensional array as a data structure for creating the subdivision

      List<List<Vector3>> v = List<List<Vector3>>.filled(cols + 1, []);

      // construct all of the vertices for this subdivision

      for (int i = 0; i <= cols; i++) {
        final aj = a.clone().lerp(c, i / cols);
        final bj = b.clone().lerp(c, i / cols);

        final rows = cols - i;

        v[i] = List<Vector3>.filled(rows + 1, Vector3.zero());

        for (int j = 0; j <= rows; j++) {
          if (j == 0 && i == cols) {
            v[i][j] = aj;
          } else {
            v[i][j] = aj.clone().lerp(bj, j / rows);
          }
        }
      }

      // construct all of the faces

      for (int i = 0; i < cols; i++) {
        for (int j = 0; j < 2 * (cols - i) - 1; j++) {
          int k =(j / 2).floor();

          if (j % 2 == 0) {
            pushVertex(v[i][k + 1]);
            pushVertex(v[i + 1][k]);
            pushVertex(v[i][k]);
          } else {
            pushVertex(v[i][k + 1]);
            pushVertex(v[i + 1][k + 1]);
            pushVertex(v[i + 1][k]);
          }
        }
      }
    }

    void getVertexByIndex(int index, Vector3 vertex) {
      final stride = index * 3;

      vertex.x = vertices[stride + 0].toDouble();
      vertex.y = vertices[stride + 1].toDouble();
      vertex.z = vertices[stride + 2].toDouble();
    }

    void subdivide(int detail) {
      final a = Vector3.zero();
      final b = Vector3.zero();
      final c = Vector3.zero();

      // iterate over all faces and apply a subdivison with the given detail value

      for (int i = 0; i < indices.length; i += 3) {
        // get the vertices of the face

        getVertexByIndex(indices[i + 0], a);
        getVertexByIndex(indices[i + 1], b);
        getVertexByIndex(indices[i + 2], c);

        // perform subdivision

        subdivideFace(a, b, c, detail);
      }
    }

    void applyRadius(double radius) {
      final vertex = Vector3.zero();

      // iterate over the entire buffer and apply the radius to each vertex

      for (int i = 0; i < vertexBuffer.length; i += 3) {
        vertex.x = vertexBuffer[i + 0];
        vertex.y = vertexBuffer[i + 1];
        vertex.z = vertexBuffer[i + 2];

        vertex..normalize()..scale(radius);

        vertexBuffer[i + 0] = vertex.x.toDouble();
        vertexBuffer[i + 1] = vertex.y.toDouble();
        vertexBuffer[i + 2] = vertex.z.toDouble();
      }
    }

    void correctUV(uv, stride, vector, azimuth) {
      if ((azimuth < 0) && (uv.x == 1)) {
        uvBuffer[stride] = uv.x - 1;
      }

      if ((vector.x == 0) && (vector.z == 0)) {
        uvBuffer[stride] = azimuth / 2 / math.pi + 0.5;
      }
    }

    // Angle around the Y axis, counter-clockwise when looking from above.

    double azimuth(Vector3 vector) {
      return math.atan2(vector.z, -vector.x);
    }

    // Angle above the XZ plane.

    double inclination(Vector3 vector) {
      return math.atan2(-vector.y, math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));
    }

    void correctUVs() {
      final a = Vector3.zero();
      final b = Vector3.zero();
      final c = Vector3.zero();

      final centroid = Vector3.zero();

      final uvA = Vector2.zero();
      final uvB = Vector2.zero();
      final uvC = Vector2.zero();

      for (int i = 0, j = 0; i < vertexBuffer.length; i += 9, j += 6) {
        a.setValues(vertexBuffer[i + 0], vertexBuffer[i + 1], vertexBuffer[i + 2]);
        b.setValues(vertexBuffer[i + 3], vertexBuffer[i + 4], vertexBuffer[i + 5]);
        c.setValues(vertexBuffer[i + 6], vertexBuffer[i + 7], vertexBuffer[i + 8]);

        uvA.setValues(uvBuffer[j + 0], uvBuffer[j + 1]);
        uvB.setValues(uvBuffer[j + 2], uvBuffer[j + 3]);
        uvC.setValues(uvBuffer[j + 4], uvBuffer[j + 5]);

        centroid..setFrom(a)..add(b)..add(c)..divideScalar(3);

        final azi = azimuth(centroid);

        correctUV(uvA, j + 0, a, azi);
        correctUV(uvB, j + 2, b, azi);
        correctUV(uvC, j + 4, c, azi);
      }
    }

    void correctSeam() {
      // handle case when face straddles the seam, see #3269

      for (int i = 0; i < uvBuffer.length; i += 6) {
        // uv data of a single face

        final x0 = uvBuffer[i + 0];
        final x1 = uvBuffer[i + 2];
        final x2 = uvBuffer[i + 4];

        final max = math.max(math.max(x0, x1), x2);
        final min = math.min(math.min(x0, x1), x2);

        // 0.9 is somewhat arbitrary

        if (max > 0.9 && min < 0.1) {
          if (x0 < 0.2) uvBuffer[i + 0] += 1;
          if (x1 < 0.2) uvBuffer[i + 2] += 1;
          if (x2 < 0.2) uvBuffer[i + 4] += 1;
        }
      }
    }

    void generateUVs() {
      final vertex = Vector3.zero();

      for (int i = 0; i < vertexBuffer.length; i += 3) {
        vertex.x = vertexBuffer[i + 0];
        vertex.y = vertexBuffer[i + 1];
        vertex.z = vertexBuffer[i + 2];

        final u = azimuth(vertex) / 2 / math.pi + 0.5;
        double v = inclination(vertex) / math.pi + 0.5;
        uvBuffer.addAll([u, 1 - v]);
      }

      correctUVs();

      correctSeam();
    }

    // helper functions ----------------- end

    parameters = {
      "vertices": vertices,
      "indices": indices,
      "radius": radius,
      "detail": detail
    };

    // the subdivision creates the vertex buffer data

    subdivide(detail);

    // all vertices should lie on a conceptual sphere with a given radius

    applyRadius(radius);

    // finally, create the uv data

    generateUVs();

    // build non-indexed geometry

    setAttribute(Attribute.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertexBuffer), 3, false));
    setAttribute(Attribute.normal,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertexBuffer.sublist(0)), 3, false));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvBuffer), 2, false));

    if (detail == 0) {
      computeVertexNormals(); // flat normals
    } 
    else {
      normalizeNormals(); // smooth normals
    }
  }
}
