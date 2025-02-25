import 'dart:typed_data';
import 'nbuf.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'vertex.dart';
import 'polygon.dart';
import 'node.dart';

// ## License
// 
// Copyright (c) 2011 Evan Wallace (http://madebyevan.com/), under the MIT license.
// THREE.js rework by thrax

// Holds a binary space partition tree representing a 3D solid. Two solids can
// be combined using the `union()`, `subtract()`, and `intersect()` methods.
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
    csg.polygons = polygons.where((p) => p.plane.w.isFinite).toList();//.sublist(0);
    return csg;
  }

  List toPolygons() {
    return polygons;
  }

  static BufferGeometry toGeometry(CSG csg, Matrix4 toMatrix){
    int triCount = 0;
    final ps = csg.polygons;
    for (final p in ps) {
      triCount += p.vertices.length - 2;
    }
    final geom = BufferGeometry();

    final vertices = NBuf3(triCount * 3 * 3);
    final normals = NBuf3(triCount * 3 * 3);
    final uvs = NBuf2(triCount * 2 * 3);
    NBuf3? colors;
    final Map<int,List<int>> grps = {};
    final List<int> dgrp = [];
    for (final p in ps) {
      final pvs = p.vertices;
      final pvlen = pvs.length;
      if (p.shared != null) {
        if (grps[p.shared!] == null) grps[p.shared!] = [];
      }
      if (pvlen > 0 && pvs[0].color != null) {
        colors ??= NBuf3(triCount * 3 * 3);
      }
      for (int j = 3; j <= pvlen; j++) {
        final grp = p.shared == null ? dgrp : grps[p.shared!];
        grp!.addAll([vertices.top ~/ 3, vertices.top ~/ 3 + 1, vertices.top ~/ 3 + 2]);
        vertices.write(pvs[0].position);
        vertices.write(pvs[j - 2].position);
        vertices.write(pvs[j - 1].position);
        normals.write(pvs[0].normal);
        normals.write(pvs[j - 2].normal);
        normals.write(pvs[j - 1].normal);
        //if (uvs != null) {
          uvs.write(pvs[0].uv);
          uvs.write(pvs[j - 2].uv);
          uvs.write(pvs[j - 1].uv);
        //}

        if (colors != null) {
          colors.write(pvs[0].color!);
          colors.write(pvs[j - 2].color!);
          colors.write(pvs[j - 1].color!);
        }
      }
    }
    geom.setAttributeFromString('position', Float32BufferAttribute.fromList(vertices.array, 3));
    geom.setAttributeFromString('normal', Float32BufferAttribute.fromList(normals.array, 3));
    //if(uvs != null) 
    geom.setAttributeFromString('uv', Float32BufferAttribute.fromList(uvs.array, 2));
    if(colors != null) geom.setAttributeFromString('color', Float32BufferAttribute.fromList(colors.array, 3));
    for (int gi = 0; gi < grps.length; gi++) {
      if (grps[gi] == null) {
        grps[gi] = [];
      }
    }
    if (grps.isNotEmpty) {
      List<int> index = [];
      int gbase = 0;
      for (int gi = 0; gi < grps.length; gi++) {
        geom.addGroup(gbase, grps[gi]!.length, gi);
        gbase += grps[gi]!.length;
        index = List.from(index)..addAll(grps[gi]!);
      }
      geom.addGroup(gbase, dgrp.length, grps.length);
      index = List.from(index)..addAll(dgrp);
      geom.setIndex(index);
    }
    final inv = Matrix4().setFrom(toMatrix).invert();
    geom.applyMatrix4(inv);
    geom.computeBoundingSphere();
    geom.computeBoundingBox();

    return geom;
  }

  static Mesh toMesh2(CSG csg,Matrix4 toMatrix,Material? toMaterial){
    final geom = CSG.toGeometry(csg, toMatrix);
    final m = Mesh(geom, toMaterial);
    m.matrix.setFrom(toMatrix);
    m.matrix.decompose(m.position, m.quaternion, m.scale);
    m.rotation.setFromQuaternion(m.quaternion);
    m.updateMatrixWorld();
    m.castShadow = m.receiveShadow = true;
    return m;
  }
  static Mesh unionMesh(Mesh meshA, Mesh meshB){
    final csgA = CSG.fromMesh(meshA);
    final csgB = CSG.fromMesh(meshB);
    return CSG.toMesh2(csgA.union(csgB), meshA.matrix, meshA.material);
  }
  static Mesh subtractMesh(Mesh meshA, Mesh meshB) {
    final csgA = CSG.fromMesh(meshA);
    final csgB = CSG.fromMesh(meshB);
    return CSG.toMesh2(csgA.subtract(csgB), meshA.matrix, meshA.material);
  }
  static Mesh intersectMesh(Mesh meshA, Mesh meshB) {
    final csgA = CSG.fromMesh(meshA);
    final csgB = CSG.fromMesh(meshB);
    return CSG.toMesh2(csgA.intersect(csgB), meshA.matrix, meshA.material);
  }

  CSG union(CSG csg) {
    final a = Node(clone().polygons);
    final b = Node(csg.clone().polygons);
    a.clipTo(b);
    b.clipTo(a);
    b.invert();
    b.clipTo(a);
    b.invert();
    a.build(b.allPolygons());
    return CSG.fromPolygons(a.allPolygons());
  }
  CSG subtract(CSG csg) {
    final a = Node(clone().polygons);
    final b = Node(csg.clone().polygons);
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
    final a = Node(clone().polygons);
    final b = Node(csg.clone().polygons);
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
    for (final p in csg.polygons) {
      p.flip();
    }
    return csg;
  }

  // Construct a CSG solid from a list of `Polygon` instances.
  static CSG fromPolygons(List<Polygon> polygons) {
    final csg = CSG();
    csg.polygons = polygons;
    return csg;
  }
  
  static CSG fromMesh(Mesh mesh) {
    final transformedGeometry = mesh.geometry!.clone();
    transformedGeometry.applyMatrix4(mesh.matrix);
    return fromGeometry(transformedGeometry);
  }
  static CSG fromGeometry(BufferGeometry geometry){
    List<Polygon> polys = [];

    if (geometry.index != null) {
      geometry = geometry.toNonIndexed();
    }

    final positions = geometry.attributes['position'];
    final normals = geometry.attributes['normal'];
    final uvs = geometry.attributes['uv'];
    final colorattr = geometry.attributes['color'];

    // TODO
    // const colors = geometry.attributes.color;

    Vertex createVertex(int index) {
      final position = Vector3(
        positions.getX(index),
        positions.getY(index),
        positions.getZ(index)
      );
      final normal = Vector3(
            normals.getX(index),
            normals.getY(index),
            normals.getZ(index)
          );

      final uv = Vector3(uvs.getX(index), uvs.getY(index),0);
      final color = colorattr != null?Vector3(colorattr.getX(index),colorattr.getY(index),colorattr.getZ(index)): null;
      return Vertex(position, normal, uv, color);
    }

    for (int i = 0; i < positions.count; i += 3) {
      final v1 = createVertex(i);
      final v2 = createVertex(i + 1);
      final v3 = createVertex(i + 2);
      polys.add(Polygon([v1, v2, v3]));
    }

    //return this;
    return CSG.fromPolygons(polys.where((p) => !p.plane.normal.x.isNaN).toList());
  }
  
  static CSG fromGeometryOld(BufferGeometry geom, [int? objectIndex]) {
    List<Polygon?> polys = [];

    final Float32BufferAttribute posattr = geom.attributes['position'];
    final Float32BufferAttribute normalattr = geom.attributes['normal'];
    final Float32BufferAttribute uvattr = geom.attributes['uv'];
    final Float32BufferAttribute? colorattr = geom.attributes['color'];
    final grps = geom.groups;
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

    final triCount = (index.length ~/ 3) | 0;
    polys = List.filled(triCount, null);

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
          Vector3(x,y,z), 
          Vector3(nx,ny,nz), 
          Vector3(u,v,0), 
          colorattr != null?Vector3(colorattr.array[vt],colorattr.array[vt + 1],colorattr.array[vt + 2]): null
          )
        );
      }

      if (objectIndex == null && grps.isNotEmpty) {
        for (final grp in grps) {
          if (i >= grp['start'] && i < grp['start'] + grp['count']) {
            polys[pli] = Polygon(vertices, grp['materialIndex']);
          }
        }
      } 
      else {
        polys[pli] = Polygon(vertices, objectIndex);
      }
    }

    return CSG.fromPolygons(polys.where((p) => p != null && !p.plane.normal.x.isNaN).nonNulls.toList());
  }
  static CSG fromMeshOld(Mesh mesh, [int? objectIndex]) {
    final tmpm3 = Matrix3.identity();
    final csg = CSG.fromGeometryOld(mesh.geometry!, objectIndex);
    tmpm3.getNormalMatrix(mesh.matrix);
    for (int i = 0; i < csg.polygons.length; i++) {
      final p = csg.polygons[i];
      for (int j = 0; j < p.vertices.length; j++) {
        final v = p.vertices[j];
        v.position.setFrom(Vector3().setFrom(v.position).applyMatrix4(mesh.matrix));
        v.normal.setFrom(Vector3().setFrom(v.normal).applyMatrix3(tmpm3));
      }
    }
    return csg;
  }
  static Mesh toMesh(CSG csg, Matrix4 toMatrix, [Material? toMaterial]) {
    final ps = csg.polygons;
    final geom = BufferGeometry();

    int triCount = 0;
    ps.forEach((p){triCount += (p.vertices.length - 2);});

    final vertices = NBuf3(triCount * 3 * 3);
    final normals = NBuf3(triCount * 3 * 3);
    final uvs = NBuf2(triCount * 2 * 3);
    NBuf3? colors;
    Map<int,List<double>> grps = {};

    ps.forEach((p){
      final pvs = p.vertices;
      final pvlen = pvs.length;

      if (p.shared != null) {
        if (grps[p.shared!] == null) grps[p.shared!] = [];
      }
      if (pvlen > 0 && pvs[0].color != null) {
        colors ??= NBuf3(triCount * 3 * 3);
      }
      for (int j = 3; j <= pvlen; j++) {
        if(p.shared != null){
          grps[p.shared]!.addAll([vertices.top / 3, (vertices.top / 3) + 1, (vertices.top / 3) + 2]);
        }
        vertices.write(pvs[0].position);
        vertices.write(pvs[j - 2].position);
        vertices.write(pvs[j - 1].position);
        normals.write(pvs[0].normal);
        normals.write(pvs[j - 2].normal);
        normals.write(pvs[j - 1].normal);
        uvs.write(pvs[0].uv);
        uvs.write(pvs[j - 2].uv);
        uvs.write(pvs[j - 1].uv);
        if(colors != null)colors?.write(pvs[0].color ?? pvs[j - 2].color ?? pvs[j - 1].color!);
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






