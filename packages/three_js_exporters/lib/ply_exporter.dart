import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';

class PLYOptions{
  bool littleEndian;
  ExportTypes type;
  PLYOptions({
    this.type = ExportTypes.ascii,
    this.littleEndian = true
  });
}

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
  static String _init(
    bool hasNormals, 
    bool hasColor, 
    bool hasUVs,
    bool binary,
    bool littleEndian
  ){
    String file = 'ply\n';
    file += 'format ${ binary ? ( littleEndian ? 'binary_little_endian' : 'binary_big_endian' ) : 'ascii' } 1.0\n';
    file += 'comment Created by Flutter\n';
    file += 'element vertex xxx\n';
    file += 'property float x\n';
    file += 'property float y\n';
    file += 'property float z\n';
    if(hasNormals){
      file += 'property float nx\n';
      file += 'property float ny\n';
      file += 'property float nz\n';
    }
    if(hasUVs){
      file += 'property float s\n';
      file += 'property float t\n';
    }
    if(hasColor){
      file += 'property uchar red\n';
      file += 'property uchar green\n';
      file += 'property uchar blue\n';
    }
    file += 'element face yyy\n';
    file += 'property list uchar uint vertex_indices\n';
    file += 'end_header\n';

    return file;
  }

  static List<int> parseMesh(Mesh mesh, [PLYOptions? options]){
    options ??= PLYOptions();
    if(options.type == ExportTypes.ascii){
      return _parseMeshAscii(mesh,true,options).file;
    }
    return _parseMeshBinary(mesh,true,options).file;
  }

  static _PLYPM _parseMeshAscii(Mesh mesh, bool start, PLYOptions options){
    String file = '';
    String polygon = '';
    int numFaces = 0;
    int numVerticies = 0;

    final Color tempColor = Color();
		final vertex = Vector3();
		final normalMatrixWorld = Matrix3.identity();

    int vertexOffset = numVerticies;
    BufferGeometry? geometry = mesh.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute(Attribute.normal);
    final Float32BufferAttribute? uvs = geometry?.getAttribute(Attribute.uv);
    final Float32BufferAttribute? colors = geometry?.getAttribute(Attribute.color);

    if(start){
      file += _init(
        normals != null,
        colors != null,
        uvs != null,
        options.type == ExportTypes.binary,
        options.littleEndian
      );
    }
    if(vertices != null){
      for(int j = 0; j < vertices.length;j++){
				vertex.fromBuffer( vertices, j );
				vertex.applyMatrix4( mesh.matrixWorld );
        file += '  ${vertex.x} ${vertex.y} ${vertex.z} ';
        if(normals != null){
					vertex.fromBuffer( normals, j );
					vertex.applyMatrix3( normalMatrixWorld ).normalize();
          file += '  ${vertex.x} ${vertex.y} ${vertex.z} ';
        }
        if(uvs != null){
          file += ' ${uvs.getX(j)!.toStringAsFixed(6)} ${uvs.getY(j)!.toStringAsFixed(6)} ';
        }
        if(colors != null){
          tempColor.fromBuffer( colors, j );
					ColorManagement.fromWorkingColorSpace( tempColor, ColorSpace.srgb );
					file += ' ${( tempColor.red * 255 ).floor()} ${( tempColor.green * 255 ).floor()} ${( tempColor.blue * 255 ).floor()} ';
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
    return _PLYPM(file, null ,polygon, numVerticies, numFaces);
  }

  static _PLYPM _parseMeshBinary(Mesh mesh, bool start, PLYOptions options){
    Endian e = options.littleEndian?Endian.little:Endian.big;
    String header = '';
    final List<int> data = [];
    final List<int> polygon = [];
    int numFaces = 0;
    int numVerticies = 0;

    final Color tempColor = Color();
		final vertex = Vector3();
		final normalMatrixWorld = Matrix3.identity();

    int vertexOffset = numVerticies;
    BufferGeometry? geometry = mesh.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute(Attribute.normal);
    final Float32BufferAttribute? uvs = geometry?.getAttribute(Attribute.uv);
    final Float32BufferAttribute? colors = geometry?.getAttribute(Attribute.color);

    if(start){
      header = _init(
        normals != null,
        colors != null,
        uvs != null,
        options.type == ExportTypes.binary,
        options.littleEndian
      );
    }

    if(vertices != null){
      for(int j = 0; j < vertices.length;j++){
				vertex.fromBuffer( vertices, j );
				vertex.applyMatrix4( mesh.matrixWorld );
        ByteData s = ByteData(Float32List.bytesPerElement*3);
        s.setFloat32(0, vertex.x, e);
        s.setFloat32(4, vertex.y, e);
        s.setFloat32(8, vertex.z, e);
        data.addAll(s.buffer.asUint8List());
        if(normals != null){
					vertex.fromBuffer( normals, j );
					vertex.applyMatrix3( normalMatrixWorld ).normalize();
          ByteData s = ByteData(Float32List.bytesPerElement*3);
          s.setFloat32(0, vertex.x, e);
          s.setFloat32(4, vertex.y, e);
          s.setFloat32(8, vertex.z, e);
          data.addAll(s.buffer.asUint8List());
        }
        if(uvs != null){
          ByteData s = ByteData(Float32List.bytesPerElement*2);
          s.setFloat32(0, uvs.getX(j)!.toDouble(), e);
          s.setFloat32(4, uvs.getY(j)!.toDouble(), e);
          data.addAll(s.buffer.asUint8List());
        }
        if(colors != null){
          tempColor.fromBuffer( colors, j );
					ColorManagement.fromWorkingColorSpace( tempColor, ColorSpace.srgb );
          data.addAll([(tempColor.red * 255 ).floor(),( tempColor.green * 255 ).floor(),( tempColor.blue * 255 ).floor()]);
        }
        numVerticies++;
      }
    }
    final indices = geometry?.getIndex();
    if(indices != null){
      for(int j = 0; j < indices.length; j+=3){
        polygon.add(3);
        ByteData s = ByteData(Uint32List.bytesPerElement*3);
        s.setUint32(0, indices.getX(j)!.toInt()+ vertexOffset, e);
        s.setUint32(4, indices.getX(j+1)!.toInt() + vertexOffset, e);
        s.setUint32(8, indices.getX(j+2)!.toInt() + vertexOffset, e);
        polygon.addAll(s.buffer.asUint8List());
        numFaces++;
      }
    }
    return _PLYPM(header, data, polygon, numVerticies, numFaces);
  }

  static List<int> parse(Scene scene,[PLYOptions? options]) {
    options ??= PLYOptions();
    if(options.type == ExportTypes.ascii){
      String header = '';
      String polygon = '';
      int numFaces = 0;
      int numVerticies = 0;
      bool start = true;

      late _PLYPM pm;

      scene.traverse((mesh){
        if(mesh is Mesh) {
          pm = _parseMeshAscii(mesh,start,options!);
          header += pm.header;
          polygon += pm.polygon;
          numFaces += pm.numFaces;
          numVerticies += pm.numVerticies;
          start = false;
        }
      });

      return _PLYPM(header, null, polygon, numVerticies, numFaces).file;
    }
    else{
      String header = '';
      final List<int> data = [];
      final List<int> polygon = [];
      int numFaces = 0;
      int numVerticies = 0;
      bool start = true;

      scene.traverse((mesh){
        if(mesh is Mesh) {
          final pm = _parseMeshBinary(mesh,start,options!);
          header += pm.header;
          data.addAll(pm.file);
          polygon.addAll(pm.polygon);
          numFaces += pm.numFaces;
          numVerticies += pm.numVerticies;
          start = false;
        }
      });

      return _PLYPM(header, data, polygon, numVerticies, numFaces).file;
    }
  }

  static void exportScene(String fileName, Scene scene, [PLYOptions? options, String? path]){
    options ??= PLYOptions();
    if(options.type == ExportTypes.ascii){
      SaveFile.saveString(
        printName: fileName, 
        fileType: 'ply', 
        data: String.fromCharCodes(parse(scene,options)), 
        path: path
      );
    }
    else{
      SaveFile.saveBytes(
        printName: fileName, 
        fileType: 'ply', 
        bytes: Uint8List.fromList(parse(scene,options)), 
        path: path
      );
    }  }
  static void exportMesh(String fileName, Mesh mesh, [PLYOptions? options, String? path]){
    options ??= PLYOptions();
    if(options.type == ExportTypes.ascii){
      SaveFile.saveString(
        printName: fileName, 
        fileType: 'ply', 
        data: String.fromCharCodes(parseMesh(mesh,options)), 
        path: path
      );
    }
    else{
      SaveFile.saveBytes(
        printName: fileName, 
        fileType: 'ply', 
        bytes: Uint8List.fromList(parseMesh(mesh,options)), 
        path: path
      );
    }
  }
}

class _PLYPM{
  _PLYPM(this.header, this.data, this.polygon, this.numVerticies, this.numFaces);
  int numFaces;
  int numVerticies;
  dynamic polygon;
  String header;
  dynamic data;

  List<int> get file => _end();
  List<int> _end(){
    if(data == null && polygon is String){
      String file = header.replaceAll('xxx', numVerticies.toString());
      file = file.replaceAll('yyy', numFaces.toString());
      file += '$polygon\n';
      return file.codeUnits;
    }
    else if(data is String && polygon is String){
      String file = header.replaceAll('xxx', numVerticies.toString());
      file = file.replaceAll('yyy', numFaces.toString());
      file += '$data\n$polygon\n';
      return file.codeUnits;
    }
    else{
      String file = header.replaceAll('xxx', numVerticies.toString());
      file = file.replaceAll('yyy', numFaces.toString());

      return file.codeUnits+data+polygon;
    }
  }
}