import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';

/// An exporter for `PLY`.
///
/// [PLY](https://en.wikipedia.org/wiki/PLY_(file_format)) (Polygon or Stanford Triangle Format) is a
/// file format for efficient delivery and loading of simple, static 3D content in a dense format.
/// Both binary and ascii formats are supported. PLY can store vertex positions, colors, normals and
/// uv coordinates. No textures or texture references are saved.
/// 
/// ```
/// // Instantiate an exporter
/// final exporter = PLYExporter();
///
/// // Parse the input and generate the ply output
/// final data = exporter.parseMesh( scene, options );
/// downloadFile( data );
/// ```
class PLYExporter{
  static String _init(bool hasColor){
    String file = 'ply\n';
    file += 'format ascii 1.0\n';
    file += 'comment Created by Flutter\n';
    file += 'element vertex xxx\n';
    file += 'property float x\n';
    file += 'property float y\n';
    file += 'property float z\n';
    file += 'property float nx\n';
    file += 'property float ny\n';
    file += 'property float nz\n';
    if(hasColor){
      file += 'property uchar red\n';
      file += 'property uchar green\n';
      file += 'property uchar blue\n';
    }
    // _file += 'property float s\n';
    // _file += 'property float t\n';
    file += 'element face yyy\n';
    file += 'property list uchar uint vertex_indices\n';
    file += 'end_header\n';

    return file;
  }
  static String _end(String start, int numVerticies, int numFaces, String polygon){
    String file = start.replaceAll('xxx', numVerticies.toString());
    file = file.replaceAll('yyy', numFaces.toString());
    file += '$polygon\n';

    return file;
  }

  static String parseMesh(Mesh mesh, [bool hasColor = false]){
    return _parseMesh(mesh,hasColor,false).file;
  }

  static _PLYPM _parseMesh(Mesh mesh, bool hasColor, bool usingParse){
    String file = '';
    String polygon = '';
    int numFaces = 0;
    int numVerticies = 0;

    if(!usingParse){
      _init(hasColor);
    }
    int vertexOffset = numVerticies;
    BufferGeometry? geometry = mesh.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute(Attribute.normal);

    if(vertices != null){
      for(int j = 0; j < vertices.length;j++){
        file += '${vertices.getX(j)!.toStringAsFixed(6)} ${vertices.getZ(j)!.toStringAsFixed(6)} ${vertices.getY(j)!.toStringAsFixed(6)}';
        if(normals != null){
          file += ' ${normals.getX(j)!.toStringAsFixed(6)} ${normals.getZ(j)!.toStringAsFixed(6)} ${normals.getY(j)!.toStringAsFixed(6)}';
        }
        if(hasColor){
          file += ' ${mesh.material?.color.red} ${mesh.material?.color.green} ${mesh.material?.color.blue}';
        }
        file += '\n';
        numVerticies++;
      }
    }
    final indices = geometry?.getIndex();
    if(indices != null){
      for(int j = 0; j < indices.length; j+=3){
        polygon += '3 ${indices.getX(j)!.toInt() + vertexOffset} ${indices.getX(j+1)!.toInt() + vertexOffset} ${indices.getX(j+2)!.toInt() + vertexOffset}\n';
        numFaces++;
      }
    }
    if(!usingParse){
      file = _end(file,numVerticies,numFaces, polygon);
    }
    return _PLYPM(file, polygon, numVerticies, numFaces);
  }

  static String parse(Scene scene,[bool hasColor = false]) {
    String file = _init(hasColor);
    String ploygon = '';
    int numFaces = 0;
    int numVerticies = 0;

    scene.traverse((mesh){
      if(mesh is Mesh) {
        final pm = _parseMesh(mesh,hasColor,true);
        file += pm.file;
        ploygon += pm.polygon;
        numFaces += pm.numFaces;
        numVerticies += pm.numVerticies;
      }
    });

    file = _end(file,numVerticies,numFaces,ploygon);

    return file;
  }

  static void exportScene(String fileName, Scene scene, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'ply', data: parse(scene), path: path);
  }
  static void exportMesh(String fileName, Mesh mesh, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'ply', data: parseMesh(mesh), path: path);
  }
}

class _PLYPM{
  _PLYPM(this.file, this.polygon, this.numVerticies, this.numFaces);
  int numFaces;
  int numVerticies;
  String polygon;
  String file;
}