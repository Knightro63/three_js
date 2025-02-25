import 'package:three_js_math/three_js_math.dart';
import 'vertex.dart';
import 'polygon.dart';

// Represents a plane in 3D space.
class Plane {
  Vector3 normal;
  double w;

  Plane(this.normal, this.w);

  Plane clone() {
    return Plane(normal.clone(),w);
  }

  void flip() {
    normal.negate();
    w = -w;
  }

  static Plane fromPoints(Vector3 a, Vector3 b, Vector3 c) {
    final n = Vector3().setFrom(b).sub(a).cross(Vector3().setFrom(c).sub(a)).normalize();
    return Plane(n.clone(),n.dot(a));
  }

  void splitPolygon(
    Polygon polygon,
    List<Polygon> coplanarFront, 
    List<Polygon> coplanarBack, 
    List<Polygon> front, 
    List<Polygon> back,
  ) {
    const coplanar_ = 0;
    const front_ = 1;
    const back_ = 2;
    const spanning_ = 3;

    // Classify each point as well as the entire polygon into one of the above
    // four classes.
    int polygonType = 0;
    List<int> types = [];
    for (int i = 0; i < polygon.vertices.length; i++) {
      double t = normal.dot(polygon.vertices[i].position) - w;
      final type = (t < -1e-4) ? back_ : (t > 1e-4) ? front_ : coplanar_;
      polygonType |= type;
      types.add(type);
    }

    // Put the polygon in the correct list, splitting it when necessary.
    switch (polygonType) {
    case coplanar_:
      (normal.dot(polygon.plane.normal) > 0 ? coplanarFront : coplanarBack).add(polygon);
      break;
    case front_:
      front.add(polygon);
      break;
    case back_:
      back.add(polygon);
      break;
    case spanning_:
      final List<Vertex> f = [], b = [];
      for (int i = 0; i < polygon.vertices.length; i++) {
        int j = (i + 1) % polygon.vertices.length;
        int ti = types[i], tj = types[j];
        final Vertex vi = polygon.vertices[i], vj = polygon.vertices[j];
        if (ti != back_){
          f.add(vi);
        }
        if (ti != front_){
          b.add(ti != back_ ? vi.clone() : vi);
        }
        if ((ti | tj) == spanning_) {
          double t = (w - normal.dot(vi.position)) / normal.dot(Vector3().setFrom(vj.position).sub(vi.position));
          Vertex v = vi.interpolate(vj, t);
          f.add(v);
          b.add(v.clone());
        }
      }
      if (f.length >= 3){
        front.add(Polygon(f,polygon.shared));
      }
      if (b.length >= 3){
        back.add(Polygon(b,polygon.shared));
      }
      break;
    }
  }
}