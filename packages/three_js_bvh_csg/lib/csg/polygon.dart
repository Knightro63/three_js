import 'vertex.dart';import 'plane.dart';

// Represents a convex polygon. The vertices used to initialize a polygon must
// be coplanar and form a convex loop. They do not have to be `Vertex`
// instances but they must behave similarly (duck typing can be used for
// customization).
// 
// Each convex polygon has a `shared` property, which is shared between all
// polygons that are clones of each other or were split from the same polygon.
// This can be used to define per-polygon properties (such as surface color).
class Polygon {
  late Plane plane;
  List<Vertex> vertices;
  int? shared;

  Polygon(this.vertices, [this.shared]) {
    plane = Plane.fromPoints(vertices[0].position, vertices[1].position, vertices[2].position);
  }
  Polygon clone() {
    return Polygon(vertices.map((v) => v.clone()).toList(),shared);
  }
  void flip() {
    vertices.reversed.map((v) => v.flip());
    plane.flip();
  }
}