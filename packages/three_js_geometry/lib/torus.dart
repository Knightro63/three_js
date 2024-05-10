import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// A class for generating torus geometries.
/// 
/// ```
/// final geometry = TorusGeometry( 10, 3, 16, 100); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class TorusGeometry extends BufferGeometry {
  /// [radius] - Radius of the torus, from the center of the torus to the center
  /// of the tube. Default is `1`. 
  /// 
  /// [tube] — Radius of the tube. Default is `0.4`.
  /// 
  /// [radialSegments] — Default is `12`
  /// 
  /// [tubularSegments] — Default is `48`.
  /// 
  /// [arc] — Central angle. Default is `pi` * 2.
  TorusGeometry([
    double radius = 1,
    double tube = 0.4,
    int radialSegments = 8,
    int tubularSegments = 6,
    double arc = math.pi * 2
  ]):super() {
    type = "TorusGeometry";
    parameters = {
      "radius": radius,
      "tube": tube,
      "radialSegments": radialSegments,
      "tubularSegments": tubularSegments,
      "arc": arc
    };

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    final center = Vector3.zero();
    final vertex = Vector3.zero();
    final normal = Vector3.zero();

    // generate vertices, normals and uvs

    for (int j = 0; j <= radialSegments; j++) {
      for (int i = 0; i <= tubularSegments; i++) {
        final u = i / tubularSegments * arc;
        final v = j / radialSegments * math.pi * 2;

        // vertex

        vertex.x = (radius + tube * math.cos(v)) * math.cos(u);
        vertex.y = (radius + tube * math.cos(v)) * math.sin(u);
        vertex.z = tube * math.sin(v);

        vertices.addAll(
            [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // normal

        center.x = radius * math.cos(u);
        center.y = radius * math.sin(u);
        normal.sub2(vertex, center).normalize();

        normals.addAll(
            [normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);

        // uv

        uvs.add(i / tubularSegments);
        uvs.add(j / radialSegments);

        if(i > 0 && j > 0){
          final a = (tubularSegments + 1) * j + i - 1;
          final b = (tubularSegments + 1) * (j - 1) + i - 1;
          final c = (tubularSegments + 1) * (j - 1) + i;
          final d = (tubularSegments + 1) * j + i;

          indices.addAll([a,b,d]);
          indices.addAll([b,c,d]);
        }
      }
    }

    // generate indices

    // for (int j = 1; j <= radialSegments; j++) {
    //   for (int i = 1; i <= tubularSegments; i++) {
    //     // indices

    //     final a = (tubularSegments + 1) * j + i - 1;
    //     final b = (tubularSegments + 1) * (j - 1) + i - 1;
    //     final c = (tubularSegments + 1) * (j - 1) + i;
    //     final d = (tubularSegments + 1) * j + i;

    //     // faces

    //     indices.addAll([a, b, d]);
    //     indices.addAll([b, c, d]);
    //   }
    // }

    // build geometry

    setIndex(indices);
    setAttribute(Attribute.position, Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3));
    setAttribute(Attribute.normal, Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2));
  }

  static fromJson(data) {
    return TorusGeometry(data.radius, data.tube, data.radialSegments,
        data.tubularSegments, data.arc);
  }
}
