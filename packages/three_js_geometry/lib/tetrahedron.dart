import 'polyhedron.dart';

/// A class for generating a tetrahedron geometries.
class TetrahedronGeometry extends PolyhedronGeometry {
  TetrahedronGeometry.create(super.vertices, super.indices, super.radius, super.detail);

  /// [radius] — Radius of the tetrahedron. Default is `1`.
  /// 
  /// [detail] — Default is `0`. Setting this to a value greater than `0` adds
  /// vertices making it no longer a tetrahedron.
  factory TetrahedronGeometry([double radius = 1, int detail = 0]) {
    final List<double> vertices = [1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1];
    final indices = [2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1];
    final tetrahedronGeometry = TetrahedronGeometry.create(vertices, indices, radius, detail);
    
    tetrahedronGeometry.type = 'TetrahedronGeometry';
    tetrahedronGeometry.parameters = {"radius": radius, "detail": detail};
    return tetrahedronGeometry;
  }
}
