/**
 * @author mrdoob / http://mrdoob.com/
 */
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class OBJExporter{
  String _output = '';
  int _indexVertex = 0;
  int _indexVertexUvs = 0;
  int _indexNormals = 0;

  bool _usingParse = false;

  OBJExporter();

  String parseMesh(Mesh mesh){
    final Vector3 vertex = Vector3();
		final Vector3 normal = Vector3();
		final Vector2 uv = Vector2();
    List<String> face = ['','',''];

    int nbVertex = 0;
    int nbNormals = 0;
    int nbVertexUvs = 0;
    int j = 0;

    BufferGeometry? geometry = mesh.geometry;

    Matrix3 normalMatrixWorld = Matrix3.identity();

    // shortcuts
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Semantic.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute( Semantic.normal);
    final Float32BufferAttribute? uvs = geometry?.getAttribute(Semantic.uv);
    final indices = geometry?.getIndex();

    if(!_usingParse){
      _output = "# Flutter OBJ File: \n";
    }

    // name of the mesh object
    _output += 'o ' + mesh.name + '\n';

    // vertices
    if(vertices != null) {
      for (int i = 0, l = vertices.length; i < l; i ++, nbVertex++ ) {
        vertex.x = vertices.getX(i)!.toDouble();
        vertex.y = vertices.getY(i)!.toDouble();
        vertex.z = vertices.getZ(i)!.toDouble();
        // transfrom the vertex to world space
        vertex.applyMatrix4( mesh.matrixWorld );
        // transform the vertex to export format
        _output += 'v ${vertex.x} ${vertex.y} ${vertex.z}\n';
      }
    }

    // uvs

    if(uvs != null){
      for (int i = 0, l = uvs.count; i < l; i ++, nbVertexUvs++ ) {
        uv.x = uvs.getX(i)!.toDouble();
        uv.y = uvs.getY(i)!.toDouble();
        // transform the uv to export format
        _output += 'vt ${uv.x} ${uv.y}\n';
      }
    }

    // normals

    if(normals != null) {
      normalMatrixWorld.getNormalMatrix( mesh.matrixWorld );
      for (int i = 0, l = normals.count; i < l; i ++, nbNormals++ ) {
        normal.x = normals.getX(i)!.toDouble();
        normal.y = normals.getY(i)!.toDouble();
        normal.z = normals.getZ(i)!.toDouble();
        // transfrom the normal to world space
        normal.applyMatrix3( normalMatrixWorld );
        // transform the normal to export format
        _output += 'vn ${normal.x} ${normal.y} ${normal.z}\n';
      }
    }

    // faces
    if(indices != null) {
      for (int i = 0, l = indices.count; i < l; i += 3 ) {
        for(int m = 0; m < 3; m ++ ){
          j = indices.getX(i + m)!.toInt() + 1;
          face[m] = '${_indexVertex + j}/${uvs != null? ( _indexVertexUvs + j ) : ''}/${_indexNormals + j}';
        }

        // transform the face to export format
        _output += 'f ${face.join(' ')}\n';
      }
    } 
    else{
      for (int i = 0, l = vertices!.length; i < l; i += 3 ) {
        for(int m = 0; m < 3; m ++ ){
          j = i + m + 1;
          face[m] = '${_indexVertex + j}/${uvs != null? ( _indexVertexUvs + j ) : ''}/${_indexNormals + j}';
        }
        // transform the face to export format
        _output += 'f ${face.join(' ')}\n';
      }
    }

    // update index
    _indexVertex += nbVertex;
    _indexVertexUvs += nbVertexUvs;
    _indexNormals += nbNormals;

    return _output;
  }

  String parseLine(Line line) {
    int nbVertex = 0;
    BufferGeometry? geometry = line.geometry;
    final type = line.type;
    final Vector3 vertex = Vector3();

    // shortcuts
    Float32BufferAttribute? vertices = geometry?.getAttribute( Semantic.position);
    //final indices = geometry?.getIndex();

    // name of the line object
    _output += 'o ' + line.name + '\n';

    if( vertices != null) {
      for (int i = 0, l = vertices.length; i < l; i ++, nbVertex++ ) {
        vertex.x = vertices.getX(i)!.toDouble();
        vertex.y = vertices.getY(i)!.toDouble();
        vertex.z = vertices.getZ(i)!.toDouble();
        // transfrom the vertex to world space
        vertex.applyMatrix4( line.matrixWorld );
        // transform the vertex to export format
        _output += 'v ${vertex.x} ${vertex.y} ${vertex.z}\n';
      }
    }

    if(type == 'Line'){
      _output += 'l ';
      for (int j = 1, l = vertices!.length; j <= l; j++ ) {
        _output += '${_indexVertex + j} ';
      }
      _output += '\n';
    }

    if ( type == 'LineSegments' ) {
      for (int j = 1, k = j + 1, l = vertices!.length; j < l; j += 2, k = j + 1 ) {
        _output += 'l ${_indexVertex + j} ${_indexVertex + k}\n';
      }
    }

    // update index
    _indexVertex += nbVertex;

    return _output;
  }

	String parse(Scene object){
    _usingParse = true;
    _output = "# Flutter OBJ File: \n";
		object.traverse((child){
			if(child is Mesh) {
				parseMesh(child);
			}

			if(child is Line) {
				parseLine(child);
			}
		});
    _usingParse = false;
		return _output;
	}
}