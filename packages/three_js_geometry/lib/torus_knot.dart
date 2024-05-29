import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// Creates a torus knot, the particular shape of which is defined by a pair
/// of coprime integers, p and q. If p and q are not coprime, the result will
/// be a torus link.
/// 
/// ```
/// final geometry = TorusKnotGeometry( 10, 3, 100, 16 ); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class TorusKnotGeometry extends BufferGeometry {

  /// [radius] - Radius of the torus. Default is `1`.
  /// 
  /// [tube] — Radius of the tube. Default is `0.4`.
  /// 
  /// [radialSegments] — Default is `8`.
  /// 
  /// [p] — This value determines, how many times the geometry winds around its
	/// axis of rotational symmetry. Default is `2`.
  /// 
  /// [q] — This value determines, how many times the geometry winds around a
	/// circle in the interior of the torus. Default is `3`.
  TorusKnotGeometry([
    double radius = 1,
    double tube = 0.4,
    int tubularSegments = 64,
    int radialSegments = 8,
    double p = 2,
    double q = 3
  ]):super() {
    type = "TorusKnotGeometry";
    parameters = {
      "radius": radius,
      "tube": tube,
      "tubularSegments": tubularSegments,
      "radialSegments": radialSegments,
      "p": p,
      "q": q
    };

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    final vertex = Vector3.zero();
    final normal = Vector3.zero();

    final p1 = Vector3.zero();
    final p2 = Vector3.zero();

    final B = Vector3.zero();
    final T = Vector3.zero();
    final N = Vector3.zero();

    calculatePositionOnCurve(u, p, q, radius, position) {
      final cu = math.cos(u);
      final su = math.sin(u);
      final quOverP = q / p * u;
      final cs = math.cos(quOverP);

      position.x = radius * (2 + cs) * 0.5 * cu;
      position.y = radius * (2 + cs) * su * 0.5;
      position.z = radius * math.sin(quOverP) * 0.5;
    }

    // generate vertices, normals and uvs

    for (int i = 0; i <= tubularSegments; ++i) {
      // the radian "u" is used to calculate the position on the torus curve of the current tubular segement

      final u = i / tubularSegments * p * math.pi * 2;

      // now we calculate two points. p1 is our current position on the curve, p2 is a little farther ahead.
      // these points are used to create a special "coordinate space", which is necessary to calculate the correct vertex positions

      calculatePositionOnCurve(u, p, q, radius, p1);
      calculatePositionOnCurve(u + 0.01, p, q, radius, p2);

      // calculate orthonormal basis

      T.sub2(p2, p1);
      N.add2(p2, p1);
      B.cross2(T, N);
      N.cross2(B, T);

      // normalize B, N. T can be ignored, we don't use it

      B.normalize();
      N.normalize();

      for (int j = 0; j <= radialSegments; ++j) {
        // now calculate the vertices. they are nothing more than an extrusion of the torus curve.
        // because we extrude a shape in the xy-plane, there is no need to calculate a z-value.

        final v = j / radialSegments * math.pi * 2;
        final cx = -tube * math.cos(v);
        final cy = tube * math.sin(v);

        // now calculate the final vertex position.
        // first we orient the extrusion with our basis vectos, then we add it to the current position on the curve

        vertex.x = p1.x + (cx * N.x + cy * B.x);
        vertex.y = p1.y + (cx * N.y + cy * B.y);
        vertex.z = p1.z + (cx * N.z + cy * B.z);

        vertices.addAll(
            [vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // normal (p1 is always the center/origin of the extrusion, thus we can use it to calculate the normal)

        normal.sub2(vertex, p1).normalize();

        normals.addAll(
            [normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);

        // uv

        uvs.add(i / tubularSegments);
        uvs.add(j / radialSegments);
      }
    }

    // generate indices

    for (int j = 1; j <= tubularSegments; j++) {
      for (int i = 1; i <= radialSegments; i++) {
        // indices

        final a = (radialSegments + 1) * (j - 1) + (i - 1);
        final b = (radialSegments + 1) * j + (i - 1);
        final c = (radialSegments + 1) * j + i;
        final d = (radialSegments + 1) * (j - 1) + i;

        // faces

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }

    // build geometry

    setIndex(indices);
    setAttribute(Attribute.position,Float32BufferAttribute.fromList(vertices, 3, false));
    setAttribute(Attribute.normal,Float32BufferAttribute.fromList(normals, 3, false));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromList(uvs, 2, false));
  }
}
