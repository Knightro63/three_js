import 'package:three_js/three_js.dart';

// Represents a vertex of a polygon. Use your own vertex class instead of this
// one to provide additional features like texture coordinates and vertex
// colors. Custom vertex classes need to provide a `pos` property and `clone()`,
// `flip()`, and `interpolate()` methods that behave analogous to the ones
// defined by `CSG.Vertex`. This class provides `normal` so convenience
// functions like `CSG.sphere()` can return a smooth vertex normal, but `normal`
// is not used anywhere else.
class Vertex {
  late Vector3 position;
  late Vector3 normal;
  late Vector3 uv;
  late Vector3? color;

  Vertex(Vector3 pos,Vector3 normal,Vector3 uv,[ Vector3? color]) {
    position = Vector3.copy(pos);
    this.normal = Vector3.copy(normal);
    this.uv = Vector3.copy(uv);
    this.color = color != null?Vector3.copy(color):null;
  }

  Vertex clone() {
    return Vertex(position,normal,uv,color);
  }

  // Invert all orientation-specific data (e.g. vertex normal). Called when the
  // orientation of a polygon is flipped.
  void flip() {
    normal.negate();
  }

  // Create a new vertex between this vertex and `other` by linearly
  // interpolating all properties using a parameter of `t`. Subclasses should
  // override this to interpolate additional properties.
  Vertex interpolate(Vertex other, double t) {
    return Vertex(
      position.clone().lerp(other.position, t),
      normal.clone().lerp(other.normal, t),
      uv.clone().lerp(other.uv, t), 
      other.color != null?color?.clone().lerp(other.color!,t):null
    );
  }
}