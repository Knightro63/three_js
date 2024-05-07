//@author kovacsv / http://kovacsv.hu/
//@author mrdoob / http://mrdoob.com/
//@author mudcube / http://mudcu.be/

import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
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
  late ByteData _output;
  bool _usingParse = false;
  int offset = 80; // skip header
  STLBinaryExporter();

  Vector3 _computeNormal(Vector3 va, Vector3 vb, Vector3 vc) {
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

  Uint8List parseMesh(Mesh object){
    BufferGeometry? geometry = object.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Semantic.position);
    final indices = geometry?.getIndex();
    if(vertices != null && indices != null){
      if(!_usingParse){
        int triangles = indices.length~/3;
        offset = 80; // skip header
        int bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
        //var arrayBuffer = new ArrayBuffer( bufferLength );
        _output = ByteData(bufferLength);
        _output.setUint32( offset, triangles, Endian.little ); offset += 4;
      }

      for (int i = 0, l = indices.length; i < l; i+=3) {
        final faces = [indices.getX(i)!.toInt(), indices.getX(i+1)!.toInt(), indices.getX(i+2)!.toInt()];

        List<Vector3> vecsToNormal = [];
        for(int j = 0; j < 3; j ++){
          vecsToNormal.add(Vector3(vertices.getX(faces[j])!.toDouble(),vertices.getY(faces[j])!.toDouble(),vertices.getZ(faces[j])!.toDouble()));
        }

        Vector3 toNormal = _computeNormal(vecsToNormal[0],vecsToNormal[1],vecsToNormal[2]);

        _output.setFloat32( offset, toNormal.x, Endian.little ); offset += 4; // normal
        _output.setFloat32( offset, toNormal.y, Endian.little ); offset += 4;
        _output.setFloat32( offset, toNormal.z, Endian.little ); offset += 4;

        for ( var j = 0; j < 3; j ++ ) {
          _output.setFloat32( offset, vecsToNormal[j].x, Endian.little ); offset += 4; // vertices
          _output.setFloat32( offset, vecsToNormal[j].y, Endian.little ); offset += 4;
          _output.setFloat32( offset, vecsToNormal[j].z, Endian.little ); offset += 4;
        }

        _output.setUint16( offset, 0, Endian.little ); offset += 2; // attribute byte count
      }
    }
    else{
      throw("There are no verticies or indicies for this mesh.");
    }

    return _output.buffer.asUint8List();
  }

	Uint8List parse(Scene scene){
    _usingParse = true;
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

    offset = 80; // skip header
    int bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
    //var arrayBuffer = new ArrayBuffer( bufferLength );
    _output = ByteData(bufferLength);
    _output.setUint32( offset, triangles, Endian.little ); offset += 4;

    // Traversing our collected objects
    ///objects.forEach(( mesh ){
    for(Mesh mesh in objects){
      parseMesh(mesh);
    }
    _usingParse = false;
    return _output.buffer.asUint8List();
  }
}