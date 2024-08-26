
// ## License
// 
// Copyright (c) 2011 Evan Wallace (http://madebyevan.com/), under the MIT license.
// THREE.js rework by thrax

// # class CSG
// Holds a binary space partition tree representing a 3D solid. Two solids can
// be combined using the `union()`, `subtract()`, and `intersect()` methods.

import 'dart:typed_data';
import 'package:three_js/three_js.dart';
import 'vertex.dart';
import 'polygon.dart';
import 'node.dart';

class CSG {
  List<Polygon> polygons = [];

  CSG();

  factory CSG.fromJSON(Map<String,dynamic> json){
    return CSG.fromPolygons(
      (json['polygons'] as List<Polygon>).map(
        (p){
          return Polygon(
            p.vertices.sublist(0),
            p.shared
          );
        }
      ).toList()
    );
  }

  CSG clone() {
    final csg = CSG();
    csg.polygons = polygons.sublist(0);
    return csg;
  }

  List toPolygons() {
    return polygons;
  }

  CSG union(CSG csg) {
    final a = Node(polygons.sublist(0));
    final b = Node(csg.polygons.sublist(0));
    a.clipTo(b);
    b.clipTo(a);
    b.invert();
    b.clipTo(a);
    b.invert();
    a.build(b.allPolygons());
    return CSG.fromPolygons(a.allPolygons());
  }

  CSG subtract(CSG csg) {
    final a = Node(polygons.sublist(0));
    final b = Node(csg.polygons.sublist(0));
    a.invert();
    a.clipTo(b);
    b.clipTo(a);
    b.invert();
    b.clipTo(a);
    b.invert();
    a.build(b.allPolygons());
    a.invert();
    return fromPolygons(a.allPolygons());
  }

  CSG intersect(CSG csg) {
    final a = Node(polygons.sublist(0));
    final b = Node(csg.polygons.sublist(0));
    a.invert();
    b.clipTo(a);
    b.invert();
    a.clipTo(b);
    b.clipTo(a);
    a.build(b.allPolygons());
    a.invert();
    return CSG.fromPolygons(a.allPolygons());
  }

  // Return a new CSG solid with solid and empty space switched. This solid is
  // not modified.
  CSG inverse() {
    final csg = clone();
    csg.polygons.forEach((p)=>p.flip());
    return csg;
  }

  // Construct a CSG solid from a list of `Polygon` instances.
  static CSG fromPolygons(List<Polygon> polygons) {
    final csg = CSG();
    csg.polygons = polygons;
    return csg;
  }

  static CSG fromGeometry(BufferGeometry geom, [int? objectIndex]) {
    List<Polygon> polys = [];

    Float32BufferAttribute posattr = geom.attributes['position'];
    Float32BufferAttribute normalattr = geom.attributes['normal'];
    Float32BufferAttribute uvattr = geom.attributes['uv'];
    Float32BufferAttribute? colorattr = geom.attributes['color'];
    Uint16List index;

    if (geom.index != null){
      index = geom.index!.array.toDartList() as Uint16List;
    }
    else {
      index = Uint16List((posattr.array.length ~/ posattr.itemSize) | 0);
      for (int i = 0; i < index.length; i++){
        index[i] = i;
      }
    }

    for (int i = 0, pli = 0, l = index.length; i < l; i += 3, pli++) {
      List<Vertex> vertices = []; 
      for (int j = 0; j < 3; j++) {
        int vi = index[i + j];
        int vp = vi * 3;
        int vt = vi * 2;
        double x = posattr.array[vp];
        double y = posattr.array[vp + 1];
        double z = posattr.array[vp + 2];
        double nx = normalattr.array[vp];
        double ny = normalattr.array[vp + 1];
        double nz = normalattr.array[vp + 2];
        double u = uvattr.array[vt];
        double v = uvattr.array[vt + 1];
        vertices.add(Vertex(
          Vector3(x,y,z), Vector3(nx,ny,nz), 
          Vector3(u,v,0), 
          colorattr != null?Vector3(colorattr.array[vt],colorattr.array[vt + 1],colorattr.array[vt + 2]): null
          )
        );
      }
      polys.add(Polygon(vertices, objectIndex));
    }

    return CSG.fromPolygons(polys);
  }

  static CSG fromMesh(Mesh mesh, [int? objectIndex]) {
    final tmpm3 = Matrix3.identity();
    final ttvv0 = Vector3();
    final csg = CSG.fromGeometry(mesh.geometry!, objectIndex);
    tmpm3.getNormalMatrix(mesh.matrix);
    for (int i = 0; i < csg.polygons.length; i++) {
      final p = csg.polygons[i];
      for (int j = 0; j < p.vertices.length; j++) {
        final v = p.vertices[j];
        //v.position.setFrom(ttvv0.setFrom(v.position).applyMatrix4(mesh.matrix));
        v.normal.setFrom(ttvv0.setFrom(v.normal).applyMatrix3(tmpm3));
      }
    }
    return csg;
  }

  static NBuf nbuf3(int ct){
    final nb = NBuf(
      top: 0,
      array: Float32List(ct),
    );
    nb.write = (v) { 
      (nb.array[nb.top++] = v.x); 
      (nb.array[nb.top++] = v.y);
      (nb.array[nb.top++] = v.z);
    };
    return nb;
  }
  static NBuf nbuf2(int ct){
    final nb = NBuf(
      top: 0,
      array: Float32List(ct),
    );
    nb.write = (v) { 
      (nb.array[nb.top++] = v.x); 
      (nb.array[nb.top++] = v.y);
    };
    return nb;
  }

  static Mesh toMesh(CSG csg, Matrix4 toMatrix, [Material? toMaterial]) {
    final ps = csg.polygons;
    final geom = BufferGeometry();

    int triCount = 0;
    ps.forEach((p){triCount += (p.vertices.length - 2);});

    final vertices = nbuf3(triCount * 3 * 3);
    final normals = nbuf3(triCount * 3 * 3);
    final uvs = nbuf2(triCount * 2 * 3);
    NBuf? colors;
    Map<int,List<double>> grps = {};

    ps.forEach((p){
      final pvs = p.vertices;
      final pvlen = pvs.length;

      if (p.shared != null) {
        if (grps[p.shared!] == null) grps[p.shared!] = [];
      }
      if (pvlen > 0 && pvs[0].color != null) {
        colors ??= nbuf3(triCount * 3 * 3);
      }
      for (int j = 3; j <= pvlen; j++) {
        if(p.shared != null){
          grps[p.shared]!.addAll([vertices.top / 3, (vertices.top / 3) + 1, (vertices.top / 3) + 2]);
        }
        vertices.write?.call(pvs[0].position);
        vertices.write?.call(pvs[j - 2].position);
        vertices.write?.call(pvs[j - 1].position);
        normals.write?.call(pvs[0].normal);
        normals.write?.call(pvs[j - 2].normal);
        normals.write?.call(pvs[j - 1].normal);
        uvs.write?.call(pvs[0].uv);
        uvs.write?.call(pvs[j - 2].uv);
        uvs.write?.call(pvs[j - 1].uv);
        if(colors != null)colors?.write?.call(pvs[0].color ?? pvs[j - 2].color ?? pvs[j - 1].color!);
      }
    });

    geom.setAttributeFromString('position', Float32BufferAttribute.fromList(vertices.array, 3));
    geom.setAttributeFromString('normal', Float32BufferAttribute.fromList(normals.array, 3));
    geom.setAttributeFromString('uv', Float32BufferAttribute.fromList(uvs.array, 2));
    if(colors != null)geom.setAttributeFromString('color', Float32BufferAttribute.fromList(colors!.array, 3));
    if (grps.isNotEmpty) {
      List<double> index = [];
      int gbase = 0;
      for (int gi = 0; gi < grps.length; gi++) {
        geom.addGroup(gbase, grps[gi]!.length, gi);
        gbase += grps[gi]!.length;
        index.addAll(grps[gi]!);
      }
      geom.setIndex(index);
    }

    final inv = Matrix4().setFrom(toMatrix).invert();
    geom.applyMatrix4(inv);
    geom.computeBoundingSphere();
    geom.computeBoundingBox();

    final m = Mesh(geom, toMaterial);
    m.matrix.setFrom(toMatrix);
    m.matrix.decompose(m.position, m.quaternion, m.scale);
    m.rotation.setFromQuaternion(m.quaternion);
    m.updateMatrixWorld();
    //m.castShadow = m.receiveShadow = true;
    return m;
  }
}

class NBuf{
  NBuf({
    this.top = 0,
    required this.array,
    this.write
  });

  int top;
  Float32List array;
  void Function(Vector3)? write;
}




