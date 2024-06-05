import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// Parametric Surfaces Geometry
/// based on the brilliant article by [prideout](https://prideout.net/blog/old/blog/index.html@p=44.html)
/// 
/// ```
/// final geometry = ParametricGeometry(ParametricGeometries.klein, 25, 25 );
/// final material = MeshBasicMaterial.fromMap( { 'color': 0x00ff00 } );
/// final klein = Mesh( geometry, material );
/// scene.add( klein );
///```
class ParametricGeometry extends BufferGeometry {

  /// [func] — A function that takes in a [u] and [v] value each between 0 and 1 and 
  /// modifies a third [Vector3] argument. Default is a function that generates a curved plane surface.
  /// 
  /// [slices] — The count of slices to use for the parametric function. Default is *8*.
  /// 
  /// [stacks] — The count of stacks to use for the parametric function. Default is *8*.
  ParametricGeometry(Function(double,double,Vector3) func, int slices, int stacks) : super() {
    type = "ParametricGeometry";
    parameters = {"func": func, "slices": slices, "stacks": stacks};

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    const eps = 0.00001;

    final normal = Vector3.zero();

    final p0 = Vector3.zero(), p1 = Vector3.zero();
    final pu = Vector3.zero(), pv = Vector3.zero();

    final sliceCount = slices + 1;

    for (int i = 0; i <= stacks; i++) {
      final v = i / stacks;

      for (int j = 0; j <= slices; j++) {
        final u = j / slices;

        // vertex

        func(u, v, p0);
        vertices.addAll([p0.x.toDouble(), p0.y.toDouble(), p0.z.toDouble()]);

        // normal

        // approximate tangent vectors via finite differences

        if (u - eps >= 0) {
          func(u - eps, v, p1);
          pu.sub2(p0, p1);
        } else {
          func(u + eps, v, p1);
          pu.sub2(p1, p0);
        }

        if (v - eps >= 0) {
          func(u, v - eps, p1);
          pv.sub2(p0, p1);
        } else {
          func(u, v + eps, p1);
          pv.sub2(p1, p0);
        }

        // cross product of tangent vectors returns surface normal

        normal.cross2(pu, pv).normalize();
        normals.addAll(
            [normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);

        // uv

        uvs.addAll([u, v]);
      }
    }

    // generate indices

    for (int i = 0; i < stacks; i++) {
      for (int j = 0; j < slices; j++) {
        final a = i * sliceCount + j;
        final b = i * sliceCount + j + 1;
        final c = (i + 1) * sliceCount + j + 1;
        final d = (i + 1) * sliceCount + j;

        // faces one and two

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
