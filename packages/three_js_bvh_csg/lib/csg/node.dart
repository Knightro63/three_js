import 'polygon.dart';
import 'plane.dart';

// Holds a node in a BSP tree. A BSP tree is built from a collection of polygons
// by picking a polygon to split along. That polygon (and all other coplanar
// polygons) are added directly to that node and the other polygons are added to
// the front and/or back subtrees. This is not a leafy BSP tree since there is
// no distinction between internal and leaf nodes.
class Node {
  Plane? plane;
  Node? front;
  Node? back; 
  late List<Polygon> polygons;

  Node([List<Polygon>? polygons]) {
    this.polygons = [];
    if (polygons != null){
      build(polygons);
    }
  }
  
  Node clone() {
    final node = Node();
    node.plane = plane?.clone();
    node.front = front?.clone();
    node.back = back?.clone();
    node.polygons = polygons.map((p) => p.clone()).toList();
    return node;
  }

  // Convert solid space to empty space and empty space to solid space.
  void invert() {
    for (int i = 0; i < polygons.length; i++){
      polygons[i].flip();
    }
    
    plane?.flip();
    front?.invert();
    back?.invert();
    final temp = front;
    front = back;
    back = temp;
  }

  // Recursively remove all polygons in `polygons` that are inside this BSP
  // tree.
  List<Polygon> clipPolygons(List<Polygon> polygons) {
    if (plane == null){
      return polygons.sublist(0);
    }
    List<Polygon> front = [], back = [];
    for (int i = 0; i < polygons.length; i++) {
      plane?.splitPolygon(polygons[i], front, back, front, back);
    }
    if (this.front != null) front = this.front!.clipPolygons(front);
    this.back != null? (back = this.back!.clipPolygons(back)) : back = [];
    return List.from(front)..addAll(back);
  }

  // Remove all polygons in this BSP tree that are inside the other BSP tree
  // `bsp`.
  void clipTo(Node bsp) {
    polygons = bsp.clipPolygons(polygons);
    front?.clipTo(bsp);
    back?.clipTo(bsp); 
  }

  // Return a list of all polygons in this BSP tree.
  List<Polygon> allPolygons() {
    List<Polygon> polygons = [];
    polygons.addAll(this.polygons.sublist(0));
    if (front != null) polygons = List.from(polygons)..addAll(front!.allPolygons());
    if (back != null) polygons = List.from(polygons)..addAll(back!.allPolygons());
    return polygons;
  }

  // Build a BSP tree out of `polygons`. When called on an existing tree, the
  // new polygons are filtered down to the bottom of the tree and become new
  // nodes there. Each set of polygons is partitioned using the first polygon
  // (no heuristic is used to pick a good split).
  void build(List<Polygon> polygons) {
    if (polygons.isEmpty){
      return;
    }
    plane ??= polygons[0].plane.clone();
    final List<Polygon> front = [];
    final List<Polygon> back = [];

    for (int i = 0; i < polygons.length; i++) {
      plane?.splitPolygon(polygons[i], this.polygons, this.polygons, front, back);
    }
    if (front.isNotEmpty) {
      this.front ??= Node();
      this.front!.build(front);
    }
    if (back.isNotEmpty) {
      this.back ??= Node();
      this.back!.build(back);
    }
  }
}

// Return a new CSG solid representing space in either this solid or in the
// solid `csg`. Neither this solid nor the solid `csg` are modified.
// 
//     A.union(B)
// 
//     +-------+            +-------+
//     |       |            |       |
//     |   A   |            |       |
//     |    +--+----+   =   |       +----+
//     +----+--+    |       +----+       |
//          |   B   |            |       |
//          |       |            |       |
//          +-------+            +-------+
// 
// Return a new CSG solid representing space in this solid but not in the
// solid `csg`. Neither this solid nor the solid `csg` are modified.
// 
//     A.subtract(B)
// 
//     +-------+            +-------+
//     |       |            |       |
//     |   A   |            |       |
//     |    +--+----+   =   |    +--+
//     +----+--+    |       +----+
//          |   B   |
//          |       |
//          +-------+
// 
// Return a new CSG solid representing space both this solid and in the
// solid `csg`. Neither this solid nor the solid `csg` are modified.
// 
//     A.intersect(B)
// 
//     +-------+
//     |       |
//     |   A   |
//     |    +--+----+   =   +--+
//     +----+--+    |       +--+
//          |   B   |
//          |       |
//          +-------+
// 

