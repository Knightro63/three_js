import 'polyhedron.dart';
import 'dart:math' as math;

class IcosahedronGeometry extends PolyhedronGeometry {
  IcosahedronGeometry.create(
    super.vertices, 
    super.indices, 
  [
    super.radius = 1, 
    super.detail = 0
  ]){
    type = "IcosahedronGeometry";
  }

  factory IcosahedronGeometry([double radius = 1, int detail = 0]) {
    final t = (1 + math.sqrt(5)) / 2;

    final List<double> vertices = [
      -1,
      t,
      0,
      1,
      t,
      0,
      -1,
      -t,
      0,
      1,
      -t,
      0,
      0,
      -1,
      t,
      0,
      1,
      t,
      0,
      -1,
      -t,
      0,
      1,
      -t,
      t,
      0,
      -1,
      t,
      0,
      1,
      -t,
      0,
      -1,
      -t,
      0,
      1
    ];

    final List<int> indices = [
      0,
      11,
      5,
      0,
      5,
      1,
      0,
      1,
      7,
      0,
      7,
      10,
      0,
      10,
      11,
      1,
      5,
      9,
      5,
      11,
      4,
      11,
      10,
      2,
      10,
      7,
      6,
      7,
      1,
      8,
      3,
      9,
      4,
      3,
      4,
      2,
      3,
      2,
      6,
      3,
      6,
      8,
      3,
      8,
      9,
      4,
      9,
      5,
      2,
      4,
      11,
      6,
      2,
      10,
      8,
      6,
      7,
      9,
      8,
      1
    ];

    IcosahedronGeometry ibg = IcosahedronGeometry.create(vertices, indices, radius, detail);

    ibg.parameters = {"radius": radius, "detail": detail};

    return ibg;
  }
}
