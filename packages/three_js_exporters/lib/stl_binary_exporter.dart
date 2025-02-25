//@author kovacsv / http://kovacsv.hu/
//@author mrdoob / http://mrdoob.com/
//@author mudcube / http://mudcu.be/

import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';

/// An exporter for the STL file format.
/// 
/// [STL](https://en.wikipedia.org/wiki/STL_(file_format)) files describe only the surface geometry
/// of a three-dimensional object without any representation of color, texture or other common model attributes.
/// The STL format specifies both ASCII and binary representations, with binary being more compact. 
/// STL files contain no scale information or indexes, and the units are arbitrary.
/// 
/// ```
/// // Instantiate an exporter
/// final exporter = STLBinaryExporter();
///
/// // Parse the input and generate the STL encoded output
/// final result = exporter.parseMesh(mesh);
/// ```
class STLBinaryExporter{
  static Vector3 _computeNormal(Vector3 va, Vector3 vb, Vector3 vc) {
    Vector3 cb = Vector3.copy(vc);
    Vector3 ab = Vector3.copy(vb);

    ab.sub(va);
    cb.sub(vb);
    cb.cross(ab);
    if(cb.x != 0 && cb.y != 0 && cb.z != 0) {
      cb.normalize();
    }

    return cb;
  }

  static Uint8List parseMesh(Mesh object, int offset, [ByteData? output]){
    BufferGeometry? geometry = object.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final indices = geometry?.getIndex();
    if(vertices != null && indices != null){
      if(output == null){
        int triangles = indices.length~/3;
        offset = 80; // skip header
        int bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
        //final arrayBuffer = new ArrayBuffer( bufferLength );
        output = ByteData(bufferLength);
        output.setUint32( offset, triangles, Endian.little ); offset += 4;
      }

      for (int i = 0, l = indices.length; i < l; i+=3) {
        final faces = [indices.getX(i)!.toInt(), indices.getX(i+1)!.toInt(), indices.getX(i+2)!.toInt()];

        List<Vector3> vecsToNormal = [];
        for(int j = 0; j < 3; j ++){
          vecsToNormal.add(Vector3(vertices.getX(faces[j])!.toDouble(),vertices.getY(faces[j])!.toDouble(),vertices.getZ(faces[j])!.toDouble()));
        }

        Vector3 toNormal = _computeNormal(vecsToNormal[0],vecsToNormal[1],vecsToNormal[2]);

        output.setFloat32( offset, toNormal.x, Endian.little ); offset += 4; // normal
        output.setFloat32( offset, toNormal.y, Endian.little ); offset += 4;
        output.setFloat32( offset, toNormal.z, Endian.little ); offset += 4;

        for ( int j = 0; j < 3; j ++ ) {
          output.setFloat32( offset, vecsToNormal[j].x, Endian.little ); offset += 4; // vertices
          output.setFloat32( offset, vecsToNormal[j].y, Endian.little ); offset += 4;
          output.setFloat32( offset, vecsToNormal[j].z, Endian.little ); offset += 4;
        }

        output.setUint16( offset, 0, Endian.little ); offset += 2; // attribute byte count
      }
    }
    else{
      throw("There are no verticies or indicies for this mesh.");
    }

    return output.buffer.asUint8List();
  }

	static Uint8List parse(Scene scene){
    // We collect objects first, as we may need to convert from BufferGeometry to Geometry
    List<Mesh> objects = [];
    int triangles = 0;
    scene.traverse((object){
      if(object is Mesh){
        BufferGeometry? geometry = object.geometry;
        final indices = geometry?.getIndex();
        if(indices != null){
          triangles += indices.length~/3;
          objects.add(object);
        }
      }
    });

    int offset = 80; // skip header
    int bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
    //final arrayBuffer = new ArrayBuffer( bufferLength );
    ByteData output = ByteData(bufferLength);
    output.setUint32( offset, triangles, Endian.little ); offset += 4;

    // Traversing our collected objects
    ///objects.forEach(( mesh ){
    for(Mesh mesh in objects){
      parseMesh(mesh, offset, output);
    }
    return output.buffer.asUint8List();
  }

  static void exportScene(String fileName, Scene scene, [String? path]){
    SaveFile.saveBytes(printName: fileName, fileType: 'stl', bytes: parse(scene), path: path);
  }
  static void exportMesh(String fileName, Mesh mesh, [String? path]){
    SaveFile.saveBytes(printName: fileName, fileType: 'stl', bytes: parseMesh(mesh,0), path: path);
  }
}