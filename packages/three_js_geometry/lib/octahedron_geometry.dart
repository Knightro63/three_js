import 'polyhedron.dart';

class OctahedronGeometry extends PolyhedronGeometry {
  OctahedronGeometry.create(super.vertices, super.indices, super.radius, super.detail);

  factory OctahedronGeometry([double radius = 1, int detail = 0]) {
    final List<double> vertices = [1, 0, 0, -1, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 1, 0, 0, -1];

    final indices = [
      0,
      2,
      4,
      0,
      4,
      3,
      0,
      3,
      5,
      0,
      5,
      2,
      1,
      2,
      5,
      1,
      5,
      3,
      1,
      3,
      4,
      1,
      4,
      2
    ];

    final octahedronGeometry = OctahedronGeometry.create(vertices, indices, radius, detail);
    octahedronGeometry.type = 'OctahedronGeometry';
    octahedronGeometry.parameters = {"radius": radius, "detail": detail};
    return octahedronGeometry;
  }
}
