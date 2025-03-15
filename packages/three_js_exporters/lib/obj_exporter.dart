//@author mrdoob / http://mrdoob.com/

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';

/// An exporter for the [OBJ](https://en.wikipedia.org/wiki/Wavefront_.obj_file) file format.
///
/// [OBJExporter] is not able to export material data into MTL files so only geometry data are supported.
/// 
/// ```
/// // Instantiate an exporter
/// final exporter = OBJExporter();
///
/// // Parse the input and generate the OBJ output
/// final data = exporter.parseMesh( scene );
/// downloadFile( data );
/// ```
class OBJExporter{
  static String parseMesh(Mesh mesh){
    return _parseMesh(mesh,0,0,0,false).file;
  }

  static _OBJPM _parseMesh(Mesh mesh,int indexVertex,int indexUvs,int indexNormals,bool usingParse){
    String output = '';
    final Vector3 vertex = Vector3();
		final Vector3 normal = Vector3();
		final Vector2 uv = Vector2();
    List<String> face = ['','',''];

    int nbVertex = indexVertex;
    int nbNormals = indexNormals;
    int nbVertexUvs = indexUvs;

    BufferGeometry? geometry = mesh.geometry;

    Matrix3 normalMatrixWorld = Matrix3.identity();

    // shortcuts
    final Float32BufferAttribute? vertices = geometry?.getAttribute(Attribute.position);
    final Float32BufferAttribute? normals = geometry?.getAttribute( Attribute.normal);
    final Float32BufferAttribute? uvs = geometry?.getAttribute(Attribute.uv);
    final indices = geometry?.getIndex();

    if(!usingParse){
      output = "# Flutter OBJ File: \n";
    }

    // name of the mesh object
    output += 'o ${mesh.name}\n';

    if ( mesh.material != null && mesh.material?.name != null && mesh.material?.name != '') {
      output += 'usemtl ${mesh.material!.name}\n';
    }

    // vertices
    if(vertices != null) {
      for (int i = 0, l = vertices.length; i < l; i ++, nbVertex++ ) {
        vertex.fromBuffer( vertices, i );
        vertex.applyMatrix4( mesh.matrixWorld );
        output += 'v ${vertex.x} ${vertex.y} ${vertex.z}\n';
      }
    }

    // uvs

    if(uvs != null){
      for (int i = 0, l = uvs.count; i < l; i ++, nbVertexUvs++ ) {
        uv.fromBuffer( uvs, i );
        // transform the uv to export format
        output += 'vt ${uv.x} ${uv.y}\n';
      }
    }

    // normals

    if(normals != null) {
      normalMatrixWorld.getNormalMatrix( mesh.matrixWorld );
      for (int i = 0, l = normals.count; i < l; i ++, nbNormals++ ) {
        normal.fromBuffer( normals, i );
        normal.applyMatrix3( normalMatrixWorld );
        output += 'vn ${normal.x} ${normal.y} ${normal.z}\n';
      }
    }

    // faces
    if(indices != null) {
      for (int i = 0, l = indices.count; i < l; i += 3 ) {
        for(int m = 0; m < 3; m ++ ){
          final j = indices.getX(i + m)!.toInt() + 1;
          face[m] = '${indexVertex + j}/${uvs != null? ( indexUvs + j ) : ''}/${indexNormals + j}';
        }

        // transform the face to export format
        output += 'f ${face.join(' ')}\n';
      }
    } 
    else{
      for (int i = 0, l = vertices!.length; i < l; i += 3 ) {
        for(int m = 0; m < 3; m ++ ){
          final j = i + m + 1;
          face[m] = '${indexVertex + j}/${uvs != null? ( indexUvs + j ) : ''}/${indexNormals + j}';
        }
        // transform the face to export format
        output += 'f ${face.join(' ')}\n';
      }
    }

    return _OBJPM(output, nbVertex, nbNormals, nbVertexUvs);
  }

  static _OBJPM _parseLine(Line line, int indexVertex ) {
    String output = '';
    int nbVertex = 0;
    BufferGeometry? geometry = line.geometry;
    final type = line.type;
    final Vector3 vertex = Vector3();

    final Float32BufferAttribute? vertices = geometry?.getAttribute( Attribute.position);
    output += 'o ${line.name}\n';

    if( vertices != null) {
      for (int i = 0, l = vertices.length; i < l; i ++, nbVertex++ ) {
        vertex.fromBuffer( vertices, i );
        vertex.applyMatrix4( line.matrixWorld );
        output += 'v ${vertex.x} ${vertex.y} ${vertex.z}\n';
      }
    }

    if(type == 'Line'){
      output += 'l ';
      for (int j = 1, l = vertices!.length; j <= l; j++ ) {
        output += '${indexVertex + j} ';
      }
      output += '\n';
    }

    if ( type == 'LineSegments' ) {
      for (int j = 1, k = j + 1, l = vertices!.length; j < l; j += 2, k = j + 1 ) {
        output += 'l ${indexVertex + j} ${indexVertex + k}\n';
      }
    }

    return _OBJPM(output, nbVertex);
  }

  static _OBJPM _parsePoints(Points point, int indexVertex ) {
    String output = '';
    int nbVertex = 0;
    BufferGeometry? geometry = point.geometry;
    final Vector3 vertex = Vector3();
    final Color color = Color();

    final Float32BufferAttribute? vertices = geometry?.getAttribute( Attribute.position);
    final Float32BufferAttribute? colors = geometry?.getAttribute( Attribute.color );

    output += 'o ${point.name}\n';

    if( vertices != null) {
      for (int i = 0, l = vertices.length; i < l; i ++, nbVertex++ ) {
        vertex.fromBuffer( vertices, i );
        vertex.applyMatrix4( point.matrixWorld );
        output += 'v ${vertex.x} ${vertex.y} ${vertex.z}';

        if ( colors != null ) {
          color.fromBuffer( colors, i );
          ColorManagement.fromWorkingColorSpace( color, ColorSpace.srgb );
          output += ' ${color.red} ${color.green} ${color.blue}';
        }
        output += '\n';
      }
    }

    output += 'p ';
    for (int j = 1, l = vertices!.length; j <= l; j++ ) {
      output += '${indexVertex + j} ';
    }
    output += '\n';

    return _OBJPM(output, nbVertex);
  }

	static String parse(Scene object){
    String output = '';
    int indexVertex = 0;
    int indexUvs = 0;
    int indexNormals = 0;

    output = "# Flutter OBJ File: \n";
		object.traverse((child){
			if(child is Mesh) {
        _OBJPM out = _parseMesh(child,indexVertex,indexUvs,indexNormals,true);
        output += out.file;
        indexVertex = out.indexVertex;
        indexUvs = out.indexUvs;
        indexNormals = out.indexNormals;
			}

			if(child is Line) {
				_OBJPM out = _parseLine(child,indexVertex);
        output += out.file;
        indexVertex = out.indexVertex;
			}

			if(child is Points) {
				_OBJPM out = _parsePoints(child,indexVertex);
        output += out.file;
        indexVertex = out.indexVertex;
			}
		});
		return output;
	}

  static void exportScene(String fileName, Scene scene, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'obj', data: parse(scene), path: path);
  }
  static void exportMesh(String fileName, Mesh mesh, [String? path]){
    SaveFile.saveString(printName: fileName, fileType: 'obj', data: parseMesh(mesh), path: path);
  }
}

class _OBJPM{
  _OBJPM(this.file, this.indexVertex,[ this.indexNormals = 0,this.indexUvs = 0]);
  int indexVertex;
  int indexNormals;
  int indexUvs;
  String file;
}