import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// A class for generating cylinder geometries.
/// 
/// ```
/// final geometry = CylinderGeometry( 5, 5, 20, 32 ); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class CylinderGeometry extends BufferGeometry {
  /// [radiusTop] — Radius of the cylinder at the top. Default is `1`.
  /// 
  /// [radiusBottom] — Radius of the cylinder at the bottom. Default is `1`.
  /// 
  /// [height] — Height of the cylinder. Default is `1`.
  /// 
  /// [radialSegments] — Number of segmented faces around the circumference of the
  /// cylinder. Default is `32`
  /// 
  /// [heightSegments] — Number of rows of faces along the height of the cylinder.
  /// Default is `1`.
  /// 
  /// [openEnded] — A Boolean indicating whether the ends of the cylinder are open
  /// or capped. Default is false, meaning capped.
  /// 
  /// [thetaStart] — Start angle for first segment, default = 0 (three o'clock
  /// position).
  /// 
  /// [thetaLength] — The central angle, often called theta, of the circular
  /// sector. The default is `2`*Pi, which makes for a complete cylinder.
  CylinderGeometry([
    double radiusTop = 1,
    double radiusBottom = 1,
    double height = 1,
    int radialSegments = 8,
    int heightSegments = 1,
    bool openEnded = false,
    num thetaStart = 0,
    double thetaLength = math.pi * 2
  ]): super() {
    type = "Cylinder";
    parameters = {
      "radiusTop": radiusTop,
      "radiusBottom": radiusBottom,
      "height": height,
      "radialSegments": radialSegments,
      "heightSegments": heightSegments,
      "openEnded": openEnded,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength
    };

    final scope = this;

    // radialSegments = math.floor(radialSegments);
    // heightSegments = math.floor(heightSegments);

    // buffers

    List<num> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    int index = 0;
    final indexArray = [];
    final halfHeight = height / 2;
    int groupStart = 0;

    // generate geometry

    void generateTorso() {
      final normal = Vector3.zero();
      final vertex = Vector3.zero();

      int groupCount = 0;

      // this will be used to calculate the normal
      final slope = (radiusBottom - radiusTop) / height;

      // generate vertices, normals and uvs

      for (int y = 0; y <= heightSegments; y++) {
        final indexRow = [];

        final v = y / heightSegments;

        // calculate the radius of the current row

        final radius = v * (radiusBottom - radiusTop) + radiusTop;

        for (int x = 0; x <= radialSegments; x++) {
          final u = x / radialSegments;

          final theta = u * thetaLength + thetaStart;

          final sinTheta = math.sin(theta);
          final cosTheta = math.cos(theta);

          // vertex

          vertex.x = radius * sinTheta;
          vertex.y = -v * height + halfHeight;
          vertex.z = radius * cosTheta;
          vertices.addAll(
              [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

          // normal

          normal..setValues(sinTheta, slope, cosTheta)..normalize();
          normals.addAll(
              [normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);

          // uv

          uvs.addAll([u, 1 - v]);

          // save index of vertex in respective row

          indexRow.add(index++);
        }

        // now save vertices of the row in our index array

        indexArray.add(indexRow);
      }

      // generate indices

      for (int x = 0; x < radialSegments; x++) {
        for (int y = 0; y < heightSegments; y++) {
          // we use the index array to access the correct indices

          final a = indexArray[y][x];
          final b = indexArray[y + 1][x];
          final c = indexArray[y + 1][x + 1];
          final d = indexArray[y][x + 1];

          // faces

          indices.addAll([a, b, d]);
          indices.addAll([b, c, d]);

          // update group counter

          groupCount += 6;
        }
      }

      // add a group to the geometry. this will ensure multi material support

      scope.addGroup(groupStart, groupCount, 0);

      // calculate new start value for groups

      groupStart += groupCount;
    }

    void generateCap(bool top) {
      // save the index of the first center vertex
      final centerIndexStart = index;

      final uv = Vector2.zero();
      final vertex = Vector3.zero();

      int groupCount = 0;

      final radius = (top == true) ? radiusTop : radiusBottom;
      final sign = (top == true) ? 1 : -1;

      // first we generate the center vertex data of the cap.
      // because the geometry needs one set of uvs per face,
      // we must generate a center vertex per face/segment

      for (int x = 1; x <= radialSegments; x++) {
        // vertex

        vertices.addAll([0, halfHeight * sign, 0]);

        // normal

        normals.addAll([0, sign.toDouble(), 0]);

        // uv

        uvs.addAll([0.5, 0.5]);

        // increase index

        index++;
      }

      // save the index of the last center vertex
      final centerIndexEnd = index;

      // now we generate the surrounding vertices, normals and uvs

      for (int x = 0; x <= radialSegments; x++) {
        final u = x / radialSegments;
        final theta = u * thetaLength + thetaStart;

        final cosTheta = math.cos(theta);
        final sinTheta = math.sin(theta);

        // vertex

        vertex.x = radius * sinTheta;
        vertex.y = halfHeight * sign;
        vertex.z = radius * cosTheta;
        vertices.addAll(
            [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // normal

        normals.addAll([0, sign.toDouble(), 0]);

        // uv

        uv.x = (cosTheta * 0.5) + 0.5;
        uv.y = (sinTheta * 0.5 * sign) + 0.5;
        uvs.addAll([uv.x.toDouble(), uv.y.toDouble()]);

        // increase index

        index++;
      }

      // generate indices

      for (int x = 0; x < radialSegments; x++) {
        final c = centerIndexStart + x;
        final i = centerIndexEnd + x;

        if (top == true) {
          // face top

          indices.addAll([i, i + 1, c]);
        } else {
          // face bottom

          indices.addAll([i + 1, i, c]);
        }

        groupCount += 3;
      }

      // add a group to the geometry. this will ensure multi material support

      scope.addGroup(groupStart, groupCount,
          top == true ? 1 : 2);

      // calculate new start value for groups

      groupStart += groupCount;
    }

    generateTorso();

    if (openEnded == false) {
      if (radiusTop > 0) generateCap(true);
      if (radiusBottom > 0) generateCap(false);
    }

    // build geometry

    setIndex(indices);
    setAttribute(Attribute.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3, false));
    setAttribute(Attribute.normal, Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3, false));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2, false));
  }

  static CylinderGeometry fromJson(Map<String,dynamic> data) {
    return CylinderGeometry(
      data["radiusTop"],
      data["radiusBottom"],
      data["height"],
      data["radialSegments"],
      data["heightSegments"],
      data["openEnded"],
      data["thetaStart"],
      data["thetaLength"]
    );
  }
}
