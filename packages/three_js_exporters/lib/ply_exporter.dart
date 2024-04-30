import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class PLYExporter{
  String _file = '';
  String _ploygon = '';
  int _faces = 0;
  int _numVerticies = 0;
  bool _usingParse = false;

  PLYExporter();

  void _init(bool hasColor){
    _file = 'ply\n';
    _file += 'format ascii 1.0\n';
    _file += 'comment Created by Flutter\n';
    _file += 'element vertex xxx\n';
    _file += 'property float x\n';
    _file += 'property float y\n';
    _file += 'property float z\n';
    _file += 'property float nx\n';
    _file += 'property float ny\n';
    _file += 'property float nz\n';
    if(hasColor){
      _file += 'property uchar red\n';
      _file += 'property uchar green\n';
      _file += 'property uchar blue\n';
    }
    // _file += 'property float s\n';
    // _file += 'property float t\n';
    _file += 'element face yyy\n';
    _file += 'property list uchar uint vertex_indices\n';
    _file += 'end_header\n';
  }
  void _end(){
    _file = _file.replaceAll('xxx', _numVerticies.toString());
    _file = _file.replaceAll('yyy', _faces.toString());
    _file += _ploygon+'\n';
  }

  String parseMesh(Mesh mesh, [bool hasColor = false]){
    if(!_usingParse){
      _init(hasColor);
    }
    int vertexOffset = _numVerticies;
    BufferGeometry? geometry = mesh.geometry;
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Semantic.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute(Semantic.normal);

    if(vertices != null){
      for(int j = 0; j < vertices.length;j++){
        _file += '${vertices.getX(j)!.toStringAsFixed(6)} ${vertices.getZ(j)!.toStringAsFixed(6)} ${vertices.getY(j)!.toStringAsFixed(6)}';
        if(normals != null){
          _file += ' ${normals.getX(j)!.toStringAsFixed(6)} ${normals.getZ(j)!.toStringAsFixed(6)} ${normals.getY(j)!.toStringAsFixed(6)}';
        }
        if(hasColor){
          _file += ' ${mesh.material?.color.red} ${mesh.material?.color.green} ${mesh.material?.color.blue}';
        }
        _file += '\n';
        _numVerticies++;
      }
    }
    final indices = geometry?.getIndex();
    if(indices != null){
      for(int j = 0; j < indices.length; j+=3){
        _ploygon += '3 ${indices.getX(j)!.toInt() + vertexOffset} ${indices.getX(j+1)!.toInt() + vertexOffset} ${indices.getX(j+2)!.toInt() + vertexOffset}\n';
        _faces++;
      }
    }
    if(!_usingParse){
      _end();
    }
    return _file;
  }

  String parse(Scene scene,[bool hasColor = false]) {
    _usingParse = true;
    _init(hasColor);

    scene.traverse((mesh){
      if(mesh is Mesh) {
        parseMesh(mesh,hasColor);
      }
    });

    _end();
    _usingParse = false;
    return _file;
  }
}