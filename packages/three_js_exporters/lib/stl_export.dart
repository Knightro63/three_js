// @author kovacsv / http://kovacsv.hu/
// @author mrdoob / http://mrdoob.com/

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
/// final exporter = STLExporter();
///
/// // Parse the input and generate the STL encoded output
/// final result = exporter.parseMesh(mesh);
/// ```
class STLExporter{
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

  static String parseMesh(Mesh object,[bool usingParse = false]){
    String output = '';
    if(!usingParse){
      output = 'solid exported\n';
    }
    BufferGeometry? geometry = object.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final indices = geometry?.getIndex();
    if(indices != null){
      for(int i = 0, l = indices.length; i < l; i+=3) {
        final faces = [indices.getX(i)!.toInt(), indices.getX(i+1)!.toInt(), indices.getX(i+2)!.toInt()];
        String verts = '';
        List<Vector3> vecsToNormal = [];
        for(int j = 0; j < 3; j ++){
          vecsToNormal.add(Vector3(vertices!.getX(faces[j])!.toDouble(),vertices.getY(faces[j])!.toDouble(),vertices.getZ(faces[j])!.toDouble()));
          verts += '\t\t\tvertex ${vecsToNormal[j].x} ${vecsToNormal[j].y} ${vecsToNormal[j].z}\n';
        }
        Vector3 toNormal = _computeNormal(vecsToNormal[0],vecsToNormal[1],vecsToNormal[2]);
        output += '\tfacet normal ${toNormal.x} ${toNormal.y} ${toNormal.z}\n';
        output += '\t\touter loop\n';
        output += verts;
        output += '\t\tendloop\n';
        output += '\tendfacet\n';
      }
    }

    if(!usingParse){
      output += 'endsolid exported\n';
    }

    return output;
  }

  static String parse(Scene scene) {
    String output = '';
    output = 'solid exported\n';

    scene.traverse((object) {
      if(object is Mesh) {
        output += parseMesh(object,true);
      }
    });

    output += 'endsolid exported\n';
    return output;
  }

  static void exportScene(String fileName, Scene scene, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'stl', data: parse(scene), path: path);
  }
  static void exportMesh(String fileName, Mesh mesh, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'stl', data: parseMesh(mesh), path: path);
  }
}