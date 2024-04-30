import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gl/flutter_gl.dart';
import 'mtl_loader.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

// o object_name | g group_name
final _objectPattern = RegExp("^[og]\s*(.+)?");
// mtllib file_reference
final _materialLibraryPattern = RegExp("^mtllib ");
// usemtl material_name
final _materialUsePattern = RegExp("^usemtl ");
// usemap map_name
final _mapUsePattern = RegExp("^usemap ");

final _vA = Vector3();
final _vB = Vector3();
final _vC = Vector3();

final _ab = Vector3();
final _cb = Vector3();

class ParseStateMaterial {
  late dynamic index;
  late dynamic name;
  late dynamic mtllib;
  late dynamic smooth;
  late int groupStart;
  late int groupEnd;
  late int groupCount;
  late dynamic inherited;

  ParseStateMaterial(Map<String, dynamic> options) {
    index = options["index"];
    name = options["name"];
    mtllib = options["mtllib"];
    smooth = options["smooth"];
    groupStart = options["groupStart"] ?? 0;
    groupEnd = options["groupEnd"] ?? 0;
    groupCount = options["groupCount"] ?? 0;
    inherited = options["inherited"];
  }

  ParseStateMaterial clone(index) {
    final cloned = ParseStateMaterial({
      "index": (index is num ? index : this.index),
      "name": name,
      "mtllib": mtllib,
      "smooth": smooth,
      "groupStart": 0,
      "groupEnd": -1,
      "groupCount": -1,
      "inherited": false
    });

    return cloned;
  }
}

class ParseStateObject {
  String name = "";
  bool fromDeclaration = false;
  List materials = [];
  Map<String, dynamic> geometry = {
    "vertices": [],
    "normals": [],
    "colors": [],
    "uvs": [],
    "hasUVIndices": false
  };
  bool smooth = true;

  ParseStateObject(Map<String, dynamic> options) {
    name = options["name"];
    fromDeclaration = options["fromDeclaration"];
  }

  ParseStateMaterial startMaterial(String? name, libraries) {
    final ParseStateMaterial? previous = _finalize(false);

    // New usemtl declaration overwrites an inherited material, except if faces were declared
    // after the material, then it must be preserved for proper MultiMaterial continuation.
    if (previous != null && (previous.inherited || previous.groupCount <= 0)) {
      materials.removeAt(previous.index);
    }

    final material = ParseStateMaterial({
      "index": materials.length,
      "name": name ?? '',
      "mtllib": (libraries is List && libraries.isNotEmpty? libraries[libraries.length - 1]: ''),
      "smooth": (previous != null ? previous.smooth : smooth),
      "groupStart": (previous != null ? previous.groupEnd : 0),
      "groupEnd": -1,
      "groupCount": -1,
      "inherited": false
    });

    materials.add(material);

    return material;
  }

  ParseStateMaterial? currentMaterial() {
    if (materials.isNotEmpty) {
      return materials[materials.length - 1];
    }

    return null;
  }

  ParseStateMaterial? _finalize(bool end) {
    final ParseStateMaterial? lastMultiMaterial = currentMaterial();
    if (lastMultiMaterial != null && lastMultiMaterial.groupEnd == -1) {
      lastMultiMaterial.groupEnd = geometry["vertices"]!.length ~/ 3;
      lastMultiMaterial.groupCount = lastMultiMaterial.groupEnd - lastMultiMaterial.groupStart;
      lastMultiMaterial.inherited = false;
    }

    // Ignore objects tail materials if no face declarations followed them before a o/g started.
    if (end && materials.length > 1) {
      for (int mi = materials.length - 1; mi >= 0; mi--) {
        if (materials[mi].groupCount <= 0) {
          materials.removeAt(mi);
        }
      }
    }

    // Guarantee at least one empty material, this makes the creation later more straight forward.
    if (end && materials.isEmpty) {
      materials.add(ParseStateMaterial({"name": '', "smooth": smooth}));
    }

    return lastMultiMaterial;
  }
}

class ParserState {
  final objects = [];
  ParseStateObject? object;

  List<double> vertices = [];
  List<double> normals = [];
  List<double> colors = [];
  List<double> uvs = [];

  final materials = {};
  final materialLibraries = [];

  ParserState() {
    startObject("", false);
  }

  void startObject(String? name, bool? fromDeclaration) {
    // print(" startObject name: ${name} fromDeclaration: ${fromDeclaration} ");
    // print(" startObject object: ${this.object} this.object.fromDeclaration: ${this.object?.fromDeclaration} ");
    // If the current object (initial from reset) is not from a g/o declaration in the parsed
    // file. We need to use it for the first parsed g/o to keep things in sync.
    if (object != null && object!.fromDeclaration == false) {
      object!.name = name ?? '';
      object!.fromDeclaration = (fromDeclaration != false);
      return;
    }

    final previousMaterial = object?.currentMaterial();

    if (object != null) {
      object!._finalize(true);
    }

    object = ParseStateObject({
      "name": name ?? '',
      "fromDeclaration": (fromDeclaration != false),
    });

    // Inherit previous objects material.
    // Spec tells us that a declared material must be set to all objects until a material is declared.
    // If a usemtl declaration is encountered while this object is being parsed, it will
    // overwrite the inherited material. Exception being that there was already face declarations
    // to the inherited material, then it will be preserved for proper MultiMaterial continuation.

    if (previousMaterial != null && previousMaterial.name != null) {
      final declared = previousMaterial.clone(0);
      declared.inherited = true;
      object!.materials.add(declared);
    }

    objects.add(object);
  }

  void finalize() {
    if (object != null) {
      object!._finalize(true);
    }
  }

  int parseVertexIndex(String value, int len) {
    final int index = int.parse(value, radix: 10);
    return (index >= 0 ? index - 1 : index + len ~/ 3) * 3;
  }

  int parseNormalIndex(String value, int len) {
    final index = int.parse(value, radix: 10);
    return (index >= 0 ? index - 1 : index + len ~/ 3) * 3;
  }

  int parseUVIndex(String value, int len) {
    final index = int.parse(value, radix: 10);
    return (index >= 0 ? index - 1 : index + len ~/ 2) * 2;
  }

  void addVertex(int a, int b, int c) {
    final src = vertices;
    final dst = object!.geometry["vertices"];

    dst.addAll([src[a + 0], src[a + 1], src[a + 2]]);
    dst.addAll([src[b + 0], src[b + 1], src[b + 2]]);
    dst.addAll([src[c + 0], src[c + 1], src[c + 2]]);
  }

  void addVertexPoint(int a) {
    final src = vertices;
    final dst = object!.geometry["vertices"];

    dst.addAll([src[a + 0], src[a + 1], src[a + 2]]);
  }

  void addVertexLine(int a) {
    final src = vertices;
    final dst = object!.geometry["vertices"];

    dst.addAll([src[a + 0], src[a + 1], src[a + 2]]);
  }

  void addNormal(int a, int b, int c) {
    final src = normals;
    final dst = object!.geometry["normals"];

    dst.addAll([src[a + 0], src[a + 1], src[a + 2]]);
    dst.addAll([src[b + 0], src[b + 1], src[b + 2]]);
    dst.addAll([src[c + 0], src[c + 1], src[c + 2]]);
  }

  void addFaceNormal(int a, int b, int c) {
    final src = vertices;
    final dst = object!.geometry["normals"];

    _vA.copyFromArray(src, a);
    _vB.copyFromArray(src, b);
    _vC.copyFromArray(src, c);

    _cb.sub2(_vC, _vB);
    _ab.sub2(_vA, _vB);
    _cb.cross(_ab);

    _cb.normalize();

    dst.addAll([_cb.x, _cb.y, _cb.z]);
    dst.addAll([_cb.x, _cb.y, _cb.z]);
    dst.addAll([_cb.x, _cb.y, _cb.z]);
  }

  void addColor(int a, [int? b, int? c]) {
    final src = colors;
    final dst = object!.geometry["colors"];

    if (src.length > a){// && src[a] != null
      dst.addAll([src[a + 0], src[a + 1], src[a + 2]]);
    }
    if (b != null && src.length > b){// && src[b] != null
      dst.addAll([src[b + 0], src[b + 1], src[b + 2]]);
    }
    if (c != null && src.length > c){// && src[c] != null
      dst.addAll([src[c + 0], src[c + 1], src[c + 2]]);
    }
  }

  void addUV(int a, int b, int c) {
    final src = uvs;
    final dst = object!.geometry["uvs"];

    dst.addAll([src[a + 0], src[a + 1]]);
    dst.addAll([src[b + 0], src[b + 1]]);
    dst.addAll([src[c + 0], src[c + 1]]);
  }

  void addDefaultUV() {
    final dst = object!.geometry["uvs"];

    dst.addAll([0, 0]);
    dst.addAll([0, 0]);
    dst.addAll([0, 0]);
  }

  void addUVLine(int a) {
    final src = uvs;
    final dst = object!.geometry["uvs"];

    dst.addAll([src[a + 0], src[a + 1]]);
  }

  void addFace(String a, String b, String c, String? ua, String? ub, String? uc, String? na, String? nb, String? nc) {
    final vLen = vertices.length;

    int ia = parseVertexIndex(a, vLen);
    int ib = parseVertexIndex(b, vLen);
    int ic = parseVertexIndex(c, vLen);

    addVertex(ia, ib, ic);
    addColor(ia, ib, ic);

    // normals

    if (na != null && na != '') {
      final nLen = normals.length;

      ia = parseNormalIndex(na, nLen);
      ib = parseNormalIndex(nb!, nLen);
      ic = parseNormalIndex(nc!, nLen);

      addNormal(ia, ib, ic);
    } 
    else {
      addFaceNormal(ia, ib, ic);
    }

    // uvs

    if (ua != null && ua != '') {
      final uvLen = uvs.length;

      ia = parseUVIndex(ua, uvLen);
      ib = parseUVIndex(ub!, uvLen);
      ic = parseUVIndex(uc!, uvLen);

      addUV(ia, ib, ic);

      object!.geometry["hasUVIndices"] = true;
    } 
    else {
      // add placeholder values (for inconsistent face definitions)
      addDefaultUV();
    }
  }

  void addPointGeometry(List<String> vertices) {
    object!.geometry["type"] = 'Points';

    final vLen = this.vertices.length;

    for (int vi = 0, l = vertices.length; vi < l; vi++) {
      final index = parseVertexIndex(vertices[vi], vLen);

      addVertexPoint(index);
      addColor(index, null, null);
    }
  }

  void addLineGeometry(List<String> vertices,List<String> uvs) {
    object!.geometry["type"] = 'Line';

    final vLen = this.vertices.length;
    final uvLen = this.uvs.length;

    for (int vi = 0, l = vertices.length; vi < l; vi++) {
      addVertexLine(parseVertexIndex(vertices[vi], vLen));
    }

    for (int uvi = 0, l = uvs.length; uvi < l; uvi++) {
      addUVLine(parseUVIndex(uvs[uvi], uvLen));
    }
  }
}

//

class OBJLoader extends Loader {
  late final FileLoader _loader;
  MaterialCreator? materials;

  OBJLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<Group?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  OBJLoader setMaterials(MaterialCreator? materials) {
    this.materials = materials;
    return this;
  }

  Future<Group> _parse(Uint8List bytes) async {
    String text = String.fromCharCodes(bytes);
    final state = ParserState();

    if (text.contains('\r\n')) {
      // This is faster than String.split with regex that splits on both
      text = text.replaceAll(RegExp("\r\n", multiLine: true), '\n');
    }

    if (text.contains('\\\n')) {
      // join lines separated by a line continuation character (\)
      text = text.replaceAll(RegExp("\\\n"), '');
    }

    List<String> lines = text.split('\n');
    String line = '', lineFirstChar = '';
    int lineLength = 0;

    // Faster to just trim left side of the line. Use if available.

    for (int i = 0, l = lines.length; i < l; i++) {
      line = lines[i];

      line = line.trimLeft();

      // print("i: ${i} line: ${line} ");

      lineLength = line.length;

      if (lineLength == 0) continue;

      lineFirstChar = line[0];

      // @todo invoke passed in handler if any
      if (lineFirstChar == '#') continue;

      if (lineFirstChar == 'v') {
        final data = line.split(RegExp(r"\s+"));

        switch (data[0]) {
          case 'v':
            state.vertices.addAll([
              double.parse(data[1]),
              double.parse(data[2]),
              double.parse(data[3])
            ]);
            if (data.length >= 7) {
              state.colors.addAll([
                double.parse(data[4]),
                double.parse(data[5]),
                double.parse(data[6])
              ]);
            } else {
              // if no colors are defined, add placeholders so color and vertex indices match
              state.colors.addAll([]);
            }

            break;
          case 'vn':
            state.normals.addAll([
              double.parse(data[1]),
              double.parse(data[2]),
              double.parse(data[3])
            ]);
            break;
          case 'vt':
            state.uvs.addAll([double.parse(data[1]), double.parse(data[2])]);
            break;
        }
      } else if (lineFirstChar == 'f') {
        final lineData = line.substring(1).trim();
        final vertexData = lineData.split(RegExp(r"\s+"));
        List<List> faceVertices = [];

        // Parse the face vertex data into an easy to work with format

        // print(" lineFirstChar is f .................. ");
        // print(vertexData);

        for (int j = 0, jl = vertexData.length; j < jl; j++) {
          final vertex = vertexData[j];

          if (vertex.isNotEmpty) {
            final vertexParts = vertex.split('/');
            faceVertices.add(vertexParts);
          }
        }

        // Draw an edge between the first vertex and all subsequent vertices to form an n-gon

        final v1 = faceVertices[0];

        for (int j = 1, jl = faceVertices.length - 1; j < jl; j++) {
          final v2 = faceVertices[j];
          final v3 = faceVertices[j + 1];

          state.addFace(
              v1[0],
              v2[0],
              v3[0],
              v1.length > 1 ? v1[1] : null,
              v2.length > 1 ? v2[1] : null,
              v3.length > 1 ? v3[1] : null,
              v1.length > 2 ? v1[2] : null,
              v2.length > 2 ? v2[2] : null,
              v3.length > 2 ? v3[2] : null);
        }
      } else if (lineFirstChar == 'l') {
        final lineParts = line.substring(1).trim().split(' ');
        List<String> lineVertices = [];
        List<String> lineUVs = [];

        if (!line.contains('/')) {
          lineVertices = lineParts;
        } 
        else {
          for (int li = 0, llen = lineParts.length; li < llen; li++) {
            final parts = lineParts[li].split('/');

            if (parts[0] != '') lineVertices.add(parts[0]);
            if (parts[1] != '') lineUVs.add(parts[1]);
          }
        }

        state.addLineGeometry(lineVertices, lineUVs);
      } 
      else if (lineFirstChar == 'p') {
        final lineData = line.substring(1).trim();
        final pointData = lineData.split(' ');

        state.addPointGeometry(pointData);
      } 
      else if (_objectPattern.hasMatch(line)) {
        List<RegExpMatch> result = _objectPattern.allMatches(line).toList();

        // o object_name
        // or
        // g group_name

        // WORKAROUND: https://bugs.chromium.org/p/v8/issues/detail?id=2869
        // final name = result[ 0 ].substr( 1 ).trim();
        final name = (' ${(result[0].group(0)?.substring(1).trim() ?? '')}').substring(1);

        state.startObject(name, null);
      } 
      else if (_materialUsePattern.hasMatch(line)) {
        // material

        state.object!
            .startMaterial(line.substring(7).trim(), state.materialLibraries);
      } 
      else if (_materialLibraryPattern.hasMatch(line)) {
        // mtl file

        state.materialLibraries.add(line.substring(7).trim());
      } 
      else if (_mapUsePattern.hasMatch(line)) {
        // the line is parsed but ignored since the loader assumes textures are defined MTL files
        // (according to https://www.okino.com/conv/imp_wave.htm, 'usemap' is the old-style Wavefront texture reference method)

        console.error('OBJLoader: Rendering identifier "usemap" not supported. Textures must be defined in MTL files.');
      } 
      else if (lineFirstChar == 's') {
        List<String> result = line.split(' ');

        // smooth shading

        // @todo Handle files that have varying smooth values for a set of faces inside one geometry,
        // but does not define a usemtl for each face set.
        // This should be detected and a dummy material created (later MultiMaterial and geometry groups).
        // This requires some care to not create extra material on each smooth value for "normal" obj files.
        // where explicit usemtl defines geometry groups.
        // Example asset: examples/models/obj/cerberus/Cerberus.obj

        /*
					 * http://paulbourke.net/dataformats/obj/
					 * or
					 * http://www.cs.utah.edu/~boulos/cs3505/obj_spec.pdf
					 *
					 * From chapter "Grouping" Syntax explanation "s group_number":
					 * "group_number is the smoothing group number. To turn off smoothing groups, use a value of 0 or off.
					 * Polygonal elements use group numbers to put elements in different smoothing groups. For free-form
					 * surfaces, smoothing groups are either turned on or off; there is no difference between values greater
					 * than 0."
					 */
        if (result.length > 1) {
          final value = result[1].trim().toLowerCase();
          state.object!.smooth = (value != '0' && value != 'off');
        } 
        else {
          // ZBrush can produce "s" lines #11707
          state.object!.smooth = true;
        }

        final material = state.object!.currentMaterial();
        if (material != null) material.smooth = state.object!.smooth;
      } 
      else {
        // Handle null terminated files without exception
        if (line == '\0') continue;
        console.warning('OBJLoader: Unexpected line: "$line"');
      }
    }

    state.finalize();

    final container = Group();
    // container.materialLibraries = [].concat( state.materialLibraries );

    final hasPrimitives = !(state.objects.length == 1 &&
        state.objects[0].geometry["vertices"].length == 0);

    if (hasPrimitives == true) {
      for (int i = 0, l = state.objects.length; i < l; i++) {
        final object = state.objects[i];
        final geometry = object.geometry;
        final materials = object.materials;
        final isLine = (geometry["type"] == 'Line');
        final isPoints = (geometry["type"] == 'Points');
        bool hasVertexColors = false;

        // Skip o/g line declarations that did not follow with any faces
        if (geometry["vertices"].length == 0) continue;

        final buffergeometry = BufferGeometry();

        buffergeometry.setAttributeFromString('position', Float32BufferAttribute(Float32Array.fromList( List<double>.from(geometry["vertices"]) ), 3));

        if (geometry["normals"].length > 0) {
          buffergeometry.setAttributeFromString('normal', Float32BufferAttribute(Float32Array.fromList( List<double>.from(geometry["normals"]) ), 3));
        }

        if (geometry["colors"].length > 0) {
          hasVertexColors = true;
          buffergeometry.setAttributeFromString('color', Float32BufferAttribute(Float32Array.fromList( List<double>.from(geometry["colors"])), 3));
        }

        if (geometry["hasUVIndices"] == true) {
          buffergeometry.setAttributeFromString('uv', Float32BufferAttribute(Float32Array.fromList( List<double>.from(geometry["uvs"])), 2));
        }

        // Create materials
        final gm = GroupMaterial();
        final createdMaterials = gm.children = [];

        for (int mi = 0, miLen = materials.length; mi < miLen; mi++) {
          final sourceMaterial = materials[mi];
          final materialHash = '${sourceMaterial.name}_${sourceMaterial.smooth}_$hasVertexColors';
          Material? material = state.materials[materialHash];

          if (this.materials != null) {
            material = await this.materials!.create(sourceMaterial.name);

            // mtl etc. loaders probably can't create line materials correctly, copy properties to a line material.
            if (isLine && material != null && (material is! LineBasicMaterial)) {
              final materialLine = LineBasicMaterial({});
              materialLine.copy(material);
              // Material.prototype.copy.call( materialLine, material );
              materialLine.color.setFrom(material.color);
              material = materialLine;
            } else if (isPoints && material != null && (material is! PointsMaterial)) {
              final materialPoints = PointsMaterial.fromMap({"size": 10, "sizeAttenuation": false});
              // Material.prototype.copy.call( materialPoints, material );
              materialPoints.copy(material);
              materialPoints.color.setFrom(material.color);
              materialPoints.map = material.map;
              material = materialPoints;
            }
          }

          if (material == null) {
            if (isLine) {
              material = LineBasicMaterial({});
            } else if (isPoints) {
              material = PointsMaterial.fromMap({"size": 1, "sizeAttenuation": false});
            } else {
              material = MeshPhongMaterial();
            }

            material?.name = sourceMaterial.name;
            material?.flatShading = sourceMaterial.smooth ? false : true;
            material?.vertexColors = hasVertexColors;

            state.materials[materialHash] = material;
          }

          createdMaterials.add(material!);
        }

        // Create mesh
        Object3D mesh;

        if (createdMaterials.length > 1) {
          for (int mi = 0, miLen = materials.length; mi < miLen; mi++) {
            final sourceMaterial = materials[mi];
            buffergeometry.addGroup(sourceMaterial.groupStart.toInt(),
                sourceMaterial.groupCount.toInt(),
                mi);
          }

          if (isLine) {
            mesh = LineSegments(buffergeometry, gm);
          } else if (isPoints) {
            mesh = Points(buffergeometry, gm);
          } else {
            mesh = Mesh(buffergeometry, gm);
          }
        } else {
          if (isLine) {
            mesh = LineSegments(buffergeometry, createdMaterials[0]);
          } else if (isPoints) {
            mesh = Points(buffergeometry, createdMaterials[0]);
          } else {
            mesh = Mesh(buffergeometry, createdMaterials[0]);
          }
        }

        mesh.name = object.name;

        container.add(mesh);
      }
    } else {
      // if there is only the default parser state object with no geometry data, interpret data as point cloud

      if (state.vertices.isNotEmpty) {
        final material = PointsMaterial.fromMap({"size": 1, "sizeAttenuation": false});

        final buffergeometry = BufferGeometry();

        buffergeometry.setAttributeFromString('position', Float32BufferAttribute(Float32Array.fromList(state.vertices), 3));

        if (state.colors.isNotEmpty) {// && state.colors[0] != null
          buffergeometry.setAttributeFromString('color', Float32BufferAttribute(Float32Array.fromList(state.colors), 3));
          material.vertexColors = true;
        }

        final points = Points(buffergeometry, material);
        container.add(points);
      }
    }

    return container;
  }
}
