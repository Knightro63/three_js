import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

class StringParseResult {
  final int start;
  final int end;
  final int next;
  final String parsedString;

  StringParseResult({
    required this.start,
    required this.end,
    required this.next,
    required this.parsedString,
  });
}

// Custom container matching your JS dynamic Map schema
class XmlJsonNode {
  Map<String, String> attributes = {};
  Map<String, dynamic> children = {};
  String? text;

  dynamic operator [](String key) {
    if (key == '#text') return text;
    return children[key];
  }
}

class VTKLoader  extends Loader {
  late final FileLoader _loader;

  VTKLoader({LoadingManager? manager}):super(manager){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<BufferGeometry?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  BufferGeometry _parse(Uint8List bufferBytes) {
		// get the 5 first lines of the files to check if there is the key word binary
		final meta = String.fromCharCodes( new Uint8List.sublistView( bufferBytes, 0, 250 ) ).split( '\n' );

		if ( meta[ 0 ].indexOf( 'xml' ) != - 1 ) {
			return parseXML( String.fromCharCodes( bufferBytes ) );
		} 
    else if ( meta[ 2 ].contains( 'ASCII' ) ) {
			return parseASCII( String.fromCharCodes( bufferBytes ) );
		} 
    else {
			return parseBinary( bufferBytes.buffer );
		}
  }

  BufferGeometry parseASCII(String data) {
    // Connectivity of the triangles
    List<int> indices = [];
    // Triangles vertices
    List<double> positions = [];
    // Red, green, blue colors in the range 0 to 1
    List<double> colors = [];
    // Normal vector, one per vertex
    List<double> normals = [];

    // Patterns for regex matching
    final patWord = RegExp(r'^[^\d.\s-]+');
    final pat3Floats = RegExp(r'(-?\d+\.?[\d\-+e]*)\s+(-?\d+\.?[\d\-+e]*)\s+(-?\d+\.?[\d\-+e]*)');
    final patConnectivity = RegExp(r'^(\d+)\s+([\s\d]*)');
    final patPOINTS = RegExp(r'^POINTS ');
    final patLINES = RegExp(r'^LINES ');
    final patPOLYGONS = RegExp(r'^POLYGONS ');
    final patTRIANGLE_STRIPS = RegExp(r'^TRIANGLE_STRIPS ');
    final patPOINT_DATA = RegExp(r'^POINT_DATA[ ]+(\d+)');
    final patCELL_DATA = RegExp(r'^CELL_DATA[ ]+(\d+)');
    final patCOLOR_SCALARS = RegExp(r'^COLOR_SCALARS[ ]+(\w+)[ ]+3');
    final patNORMALS = RegExp(r'^NORMALS[ ]+(\w+)[ ]+(\w+)');

    bool inPointsSection = false;
    bool inLinesSection = false;
    bool inPolygonsSection = false;
    bool inTriangleStripSection = false;
    bool inPointDataSection = false;
    bool inCellDataSection = false;
    bool inColorSection = false;
    bool inNormalsSection = false;

    List<String> lines = data.split('\n');

    for (String lineText in lines) {
      String line = lineText.trim();
      if (line.isEmpty) continue; // Skip empty lines safely

      if (line.indexOf('DATASET') == 0) {
        String dataset = line.split(' ')[1];
        if (dataset != 'POLYDATA') {
          throw Exception('Unsupported DATASET type: ' + dataset);
        }
      } else if (inPointsSection) {
        if (patWord.hasMatch(line)) {
          // Instead of continuing the main loop, turn off the flag so it catches section triggers
          inPointsSection = false; 
        } 
        else {
          for (final match in pat3Floats.allMatches(line)) {
            double x = double.parse(match.group(1)!);
            double y = double.parse(match.group(2)!);
            double z = double.parse(match.group(3)!);
            positions.addAll([x, y, z]);
          }
        }
      } else if (inLinesSection) {
        final match = patConnectivity.firstMatch(line);
        if (match != null) {
          int numVertices = int.parse(match.group(1)!);
          List<String> inds = match.group(2)!.trim().split(RegExp(r'\s+'));
          for (int j = 0; j < numVertices; ++j) {
            int vertex = int.parse(inds[j]);
            indices.add(vertex);
          }
        }
      } else if (inPolygonsSection) {
        final match = patConnectivity.firstMatch(line);
        if (match != null) {
          int numVertices = int.parse(match.group(1)!);
          List<String> inds = match.group(2)!.trim().split(RegExp(r'\s+'));
          if (numVertices >= 3) {
            int i0 = int.parse(inds[0]);
            int i1, i2;
            int k = 1;
            for (int j = 0; j < numVertices - 2; ++j) {
              i1 = int.parse(inds[k]);
              i2 = int.parse(inds[k + 1]);
              indices.addAll([i0, i1, i2]);
              k++;
            }
          }
        }
      } else if (inTriangleStripSection) {
        final match = patConnectivity.firstMatch(line);
        if (match != null) {
          int numVertices = int.parse(match.group(1)!);
          List<String> inds = match.group(2)!.trim().split(RegExp(r'\s+'));
          if (numVertices >= 3) {
            int i0, i1, i2;
            for (int j = 0; j < numVertices - 2; j++) {
              if (j % 2 == 1) {
                i0 = int.parse(inds[j]);
                i1 = int.parse(inds[j + 2]);
                i2 = int.parse(inds[j + 1]);
                indices.addAll([i0, i1, i2]);
              } else {
                i0 = int.parse(inds[j]);
                i1 = int.parse(inds[j + 1]);
                i2 = int.parse(inds[j + 2]);
                indices.addAll([i0, i1, i2]);
              }
            }
          }
        }
      } else if (inPointDataSection || inCellDataSection) {
        if (inColorSection) {
          if (patWord.hasMatch(line)) {
            inColorSection = false;
          } else {
            for (final match in pat3Floats.allMatches(line)) {
              double r = double.parse(match.group(1)!);
              double g = double.parse(match.group(2)!);
              double b = double.parse(match.group(3)!);
              colors.addAll([r, g, b]);
            }
          }
        } else if (inNormalsSection) {
          if (patWord.hasMatch(line)) {
            inNormalsSection = false;
          } else {
            for (final match in pat3Floats.allMatches(line)) {
              colors.addAll([
                double.parse(match.group(1)!),
                double.parse(match.group(2)!),
                double.parse(match.group(3)!)
              ]);
            }
          }
        }
      }

      // Section triggers
      if (patPOLYGONS.hasMatch(line)) {
        inPolygonsSection = true;
        inPointsSection = false;
        inTriangleStripSection = false;
        inLinesSection = false;
      } else if (patPOINTS.hasMatch(line)) {
        inPolygonsSection = false;
        inPointsSection = true;
        inTriangleStripSection = false;
        inLinesSection = false;
      } else if (patTRIANGLE_STRIPS.hasMatch(line)) {
        inPolygonsSection = false;
        inPointsSection = false;
        inTriangleStripSection = true;
        inLinesSection = false;
      } else if (patLINES.hasMatch(line)) {
        inPolygonsSection = false;
        inPointsSection = false;
        inTriangleStripSection = false;
        inLinesSection = true;
      } else if (patPOINT_DATA.hasMatch(line)) {
        inPointDataSection = true;
        inPointsSection = false;
        inPolygonsSection = false;
        inTriangleStripSection = false;
        inLinesSection = false;
      } else if (patCELL_DATA.hasMatch(line)) {
        inCellDataSection = true;
        inPointsSection = false;
        inPolygonsSection = false;
        inTriangleStripSection = false;
        inLinesSection = false;
      } else if (patCOLOR_SCALARS.hasMatch(line)) {
        inColorSection = true;
        inNormalsSection = false;
        inPointsSection = false;
        inPolygonsSection = false;
        inTriangleStripSection = false;
        inLinesSection = false;
      } else if (patNORMALS.hasMatch(line)) {
        inNormalsSection = true;
        inColorSection = false;
        inPointsSection = false;
        inPolygonsSection = false;
        inTriangleStripSection = false;
        inLinesSection = false;
      }
    }

    BufferGeometry geometry = BufferGeometry();
    geometry.setIndex(indices);
    geometry.setAttributeFromString('position', Float32BufferAttribute(Float32List.fromList(positions), 3));

    if (normals.length == positions.length) {
      geometry.setAttributeFromString('normal', Float32BufferAttribute(Float32List.fromList(normals), 3));
    }

    if (colors.length != indices.length) {
      if (colors.length == positions.length) {
        geometry.setAttributeFromString('color', Float32BufferAttribute(Float32List.fromList(colors), 3));
      }
    } else {
      geometry = geometry.toNonIndexed();
      int numTriangles = geometry.attributes['position'].count ~/ 3;
      if (colors.length == (numTriangles * 3)) {
        List<double> newColors = [];
        for (int i = 0; i < numTriangles; i++) {
          double r = colors[3 * i + 0];
          double g = colors[3 * i + 1];
          double b = colors[3 * i + 2];
          newColors.addAll([r, g, b]);
          newColors.addAll([r, g, b]);
          newColors.addAll([r, g, b]);
        }
        geometry.setAttributeFromString('color', Float32BufferAttribute(Float32List.fromList(newColors), 3));
      }
    }
    return geometry;
  }

  BufferGeometry parseBinary(ByteBuffer data) {
    int count;
    int pointIndex;
    int i;
    int numberOfPoints;
    int s;

    Uint8List buffer = Uint8List.view(data);
    ByteData dataView = ByteData.view(data);

    // Default empty collections using Dart's typed lists
    Float32List points = Float32List(0);
    Float32List normals = Float32List(0);
    Uint32List indices = Uint32List(0);

    List<String> vtk = [];
    int index = 0;

    // Internal helper function to read lines separated by LF (ASCII 10)
    StringParseResult findString(Uint8List buffer, int start) {
      int currentIndex = start;
      int c = buffer[currentIndex];
      List<int> bytes = [];

      while (c != 10) {
        bytes.add(c);
        currentIndex++;
        // Boundary safety check
        if (currentIndex >= buffer.length) break;
        c = buffer[currentIndex];
      }
      
      String parsed = utf8.decode(bytes);
      return StringParseResult(
        start: start,
        end: currentIndex,
        next: currentIndex + 1,
        parsedString: parsed,
      );
    }

    while (true) {
      StringParseResult state = findString(buffer, index);
      String line = state.parsedString;
      int nextPointer = state.next;

      if (line.startsWith('DATASET')) {
        String dataset = line.split(' ')[1];
        if (dataset != 'POLYDATA') {
          throw Exception('Unsupported DATASET type: $dataset');
        }
      } else if (line.startsWith('POINTS')) {
        vtk.add(line);
        numberOfPoints = int.parse(line.split(' ')[1], radix: 10);
        
        // Each point is 3 elements * 4 bytes
        count = numberOfPoints * 4 * 3;
        points = Float32List(numberOfPoints * 3);
        pointIndex = nextPointer;

        for (i = 0; i < numberOfPoints; i++) {
          // Endian.big matches JavaScript's dataView.getFloat32(..., false)
          points[3 * i] = dataView.getFloat32(pointIndex, Endian.big);
          points[3 * i + 1] = dataView.getFloat32(pointIndex + 4, Endian.big);
          points[3 * i + 2] = dataView.getFloat32(pointIndex + 8, Endian.big);
          pointIndex += 12;
        }
        nextPointer = nextPointer + count + 1;
      } else if (line.startsWith('TRIANGLE_STRIPS')) {
        int numberOfStrips = int.parse(line.split(' ')[1], radix: 10);
        int size = int.parse(line.split(' ')[2], radix: 10);
        
        count = size * 4;
        indices = Uint32List(3 * size - 9 * numberOfStrips);
        int indicesIndex = 0;
        pointIndex = nextPointer;

        for (i = 0; i < numberOfStrips; i++) {
          int indexCount = dataView.getInt32(pointIndex, Endian.big);
          List<int> strip = [];
          pointIndex += 4;

          for (s = 0; s < indexCount; s++) {
            strip.add(dataView.getInt32(pointIndex, Endian.big));
            pointIndex += 4;
          }

          for (int j = 0; j < indexCount - 2; j++) {
            if (j % 2 != 0) { // Equivalent to JavaScript truthy check `j % 2`
              indices[indicesIndex++] = strip[j];
              indices[indicesIndex++] = strip[j + 2];
              indices[indicesIndex++] = strip[j + 1];
            } else {
              indices[indicesIndex++] = strip[j];
              indices[indicesIndex++] = strip[j + 1];
              indices[indicesIndex++] = strip[j + 2];
            }
          }
        }
        nextPointer = nextPointer + count + 1;
      } else if (line.startsWith('POLYGONS')) {
        int numberOfStrips = int.parse(line.split(' ')[1], radix: 10);
        int size = int.parse(line.split(' ')[2], radix: 10);
        
        count = size * 4;
        indices = Uint32List(3 * size - 9 * numberOfStrips);
        int indicesIndex = 0;
        pointIndex = nextPointer;

        for (i = 0; i < numberOfStrips; i++) {
          int indexCount = dataView.getInt32(pointIndex, Endian.big);
          List<int> strip = [];
          pointIndex += 4;

          for (s = 0; s < indexCount; s++) {
            strip.add(dataView.getInt32(pointIndex, Endian.big));
            pointIndex += 4;
          }

          for (int j = 1; j < indexCount - 1; j++) {
            indices[indicesIndex++] = strip[0];
            indices[indicesIndex++] = strip[j];
            indices[indicesIndex++] = strip[j + 1];
          }
        }
        nextPointer = nextPointer + count + 1;
      } else if (line.startsWith('POINT_DATA')) {
        numberOfPoints = int.parse(line.split(' ')[1], radix: 10);
        
        state = findString(buffer, nextPointer);
        nextPointer = state.next;
        
        count = numberOfPoints * 4 * 3;
        normals = Float32List(numberOfPoints * 3);
        pointIndex = nextPointer;

        for (i = 0; i < numberOfPoints; i++) {
          normals[3 * i] = dataView.getFloat32(pointIndex, Endian.big);
          normals[3 * i + 1] = dataView.getFloat32(pointIndex + 4, Endian.big);
          normals[3 * i + 2] = dataView.getFloat32(pointIndex + 8, Endian.big);
          pointIndex += 12;
        }
        nextPointer = nextPointer + count;
      }

      index = nextPointer;
      if (index >= buffer.lengthInBytes) {
        break;
      }
    }

    BufferGeometry geometry = BufferGeometry();
    geometry.setIndex(Uint32BufferAttribute(indices, 1));
    geometry.setAttributeFromString('position', Float32BufferAttribute(points, 3));

    if (normals.length == points.length) {
      geometry.setAttributeFromString('normal', Float32BufferAttribute(normals, 3));
    }

    return geometry;
  }

  Float32List float32Concat(Float32List first, Float32List second ) {
    int firstLength = first.length;
    final result = new Float32List( firstLength + second.length );

    result.set( first );
    result.set( second, firstLength );
    return result;
  }

  Int32List int32Concat(Int32List first, Int32List second ) {
    int firstLength = first.length;
    final result = new Int32List( firstLength + second.length );

    result.set( first );
    result.set( second, firstLength );

    return result;
  }

  BufferGeometry parseXML(String stringFile) {
    // 1. Replaced JS DOMParser with native Dart xml package
    final document = xml.XmlDocument.parse(stringFile);
    final rootElement = document.rootElement;

    // Global tracking states matching JS structure
    Map<String, String> globalAttributes = {};
    for (final attr in rootElement.attributes) {
      globalAttributes[attr.name.local] = attr.value.trim();
    }

    // 2. Helper function to recursively parse XML to clean Dart objects
    XmlJsonNode xmlToJson(xml.XmlElement element) {
      final node = XmlJsonNode();
      for (final attr in element.attributes) {
        node.attributes[attr.name.local] = attr.value.trim();
      }

      List<xml.XmlNode> childNodes = element.children;
      for (final child in childNodes) {
        if (child is xml.XmlText) {
          String t = child.value.trim();
          if (t.isNotEmpty) {
            node.text = (node.text ?? '') + t;
          }
        } else if (child is xml.XmlElement) {
          String name = child.name.local;
          final parsedChild = xmlToJson(child);

          if (!node.children.containsKey(name)) {
            node.children[name] = parsedChild;
          } else {
            if (node.children[name] is! List) {
              final old = node.children[name];
              node.children[name] = [old];
            }
            (node.children[name] as List).add(parsedChild);
          }
        }
      }
      return node;
    }

    final json = xmlToJson(rootElement);

    Uint8List base64ToByteArray(String b64) {
      // 1. Setup the reverse lookup tables exactly matching the JS logic
      final List<int> revLookup = List<int>.filled(256, 0);
      const String code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      
      for (int i = 0; i < code.length; i++) {
        revLookup[code.codeUnitAt(i)] = i;
      }
      revLookup['-'.codeUnitAt(0)] = 62;
      revLookup['_'.codeUnitAt(0)] = 63;

      // 2. Validate string length constraints
      int len = b64.length;
      if (len % 4 > 0) {
        throw FormatException('Invalid string. Length must be a multiple of 4');
      }

      // 3. Extract padding counts matching the JS truthy evaluations
      int placeHolders = 0;
      if (b64[len - 2] == '=') {
        placeHolders = 2;
      } else if (b64[len - 1] == '=') {
        placeHolders = 1;
      }

      // 4. Pre-allocate the exact output buffer byte array
      int outputLength = ((len * 3) ~/ 4) - placeHolders;
      Uint8List arr = Uint8List(outputLength);
      
      int l = placeHolders > 0 ? len - 4 : len;
      int L = 0;
      int i = 0;

      // 5. Main decoding byte mutation block
      for (i = 0; i < l; i += 4) {
        int tmp = (revLookup[b64.codeUnitAt(i)] << 18) |
                  (revLookup[b64.codeUnitAt(i + 1)] << 12) |
                  (revLookup[b64.codeUnitAt(i + 2)] << 6) |
                  revLookup[b64.codeUnitAt(i + 3)];
                  
        arr[L++] = (tmp & 0xFF0000) >> 16;
        arr[L++] = (tmp & 0xFF00) >> 8;
        arr[L++] = tmp & 0xFF;
      }

      // 6. Handle residual trailing edge cases
      if (placeHolders == 2) {
        int tmp = (revLookup[b64.codeUnitAt(i)] << 2) | 
                  (revLookup[b64.codeUnitAt(i + 1)] >> 4);
        arr[L++] = tmp & 0xFF;
      } else if (placeHolders == 1) {
        int tmp = (revLookup[b64.codeUnitAt(i)] << 10) |
                  (revLookup[b64.codeUnitAt(i + 1)] << 4) |
                  (revLookup[b64.codeUnitAt(i + 2)] >> 2);
        arr[L++] = (tmp >> 8) & 0xFF;
        arr[L++] = tmp & 0xFF;
      }

      return arr;
    }

    // 3. Extracted DataArray Parser
    dynamic parseDataArray(XmlJsonNode ele, bool compressed) {
      int numBytes = 0;
      if (globalAttributes['header_type'] == 'UInt64') {
        numBytes = 8;
      } else if (globalAttributes['header_type'] == 'UInt32') {
        numBytes = 4;
      }

      String? rawData = ele.text;
      if (rawData == null) return null;

      final format = ele.attributes['format'];
      final type = ele.attributes['type'];

      if (format == 'binary' && compressed) {
        List<int> byteData = base64ToByteArray(rawData.replaceAll(RegExp(r'\s+'), ''));
        
        int blocks = byteData[0];
        for (int i = 1; i < numBytes - 1; i++) {
          blocks = blocks | (byteData[i] << (i * numBytes));
        }

        int headerSize = (blocks + 3) * numBytes;
        int padding = ((headerSize % 3) > 0) ? 3 - (headerSize % 3) : 0;
        headerSize = headerSize + padding;

        List<int> dataOffsets = [];
        int currentOffset = headerSize;
        dataOffsets.add(currentOffset);

        int cSizeStart = 3 * numBytes;
        for (int i = 0; i < blocks; i++) {
          int currentBlockSize = byteData[i * numBytes + cSizeStart];
          for (int j = 1; j < numBytes - 1; j++) {
            currentBlockSize = currentBlockSize | (byteData[i * numBytes + cSizeStart + j] << (j * 8));
          }
          currentOffset = currentOffset + currentBlockSize;
          dataOffsets.add(currentOffset);
        }

        List<dynamic> txtList = [];
        for (int i = 0; i < dataOffsets.length - 1; i++) {
          // Handles JS unzlibSync implementation natively
          final sliced = byteData.sublist(dataOffsets[i], dataOffsets[i + 1]);
          final decompressed = ZLibDecoder().decodeBytes(sliced);
          final buffer = Uint8List.fromList(decompressed).buffer;

          if (type == 'Float32') {
            txtList.addAll(buffer.asFloat32List());
          } else if (type == 'Int64' || type == 'Int32') {
            txtList.addAll(buffer.asInt32List());
          }
        }

        ele.text = null; // matching JS delete operation

        if (type == 'Float32') {
          return Float32List.fromList(txtList.cast<double>());
        } else {
          if (type == 'Int64' && format == 'binary') {
            // JS filter condition matching logic conversion
            List<int> filtered = [];
            for (int idx = 0; idx < txtList.length; idx++) {
              if (idx % 2 != 1) filtered.add(txtList[idx]);
            }
            return Int32List.fromList(filtered);
          }
          return Int32List.fromList(txtList.cast<int>());
        }
      } 
      else {
        if (format == 'binary' && !compressed) {
          Uint8List contentBytes = base64ToByteArray(rawData);
          int numBytes = (globalAttributes['header_type'] == 'UInt64') ? 8 : 4;
          final slicedBuffer = contentBytes.sublist(numBytes).buffer;
          
          if (type == 'Float32') {
            return slicedBuffer.asFloat32List();
          } 
          else if (type == 'Int64') {
            final txt = slicedBuffer.asInt32List();
            List<int> filtered = [];
            for (int idx = 0; idx < txt.length; idx++) {
              if (idx % 2 != 1) filtered.add(txt[idx]);
            }
            return Int32List.fromList(filtered);
          } else {
            return slicedBuffer.asInt32List();
          }
        } else {
          // Standard uncompressed clear-text ASCII fallback path...
          List<String> items = rawData.trim().split(RegExp(r'\s+')).where((el) => el.isNotEmpty).toList();
          if (type == 'Float32') {
            return Float32List.fromList(items.map(double.parse).toList());
          } else {
            return Int32List.fromList(items.map(int.parse).toList());
          }
        }
      }
    }

    // 4. Mesh Section Parser Block
    final polyDataNode = json.children['PolyData'];
    if (polyDataNode != null) {
      final piece = polyDataNode.children['Piece'] as XmlJsonNode;
      bool compressed = globalAttributes.containsKey('compressor');
      
      Float32List points = Float32List(0);
      Float32List normals = Float32List(0);
      Uint32List indices = Uint32List(0);

      List<String> sections = ['PointData', 'Points', 'Strips', 'Polys'];

      for (final sectionName in sections) {
        final section = piece.children[sectionName];
        if (section == null) continue;

        List<XmlJsonNode> arr = [];
        if (section.children['DataArray'] is List) {
          arr = List<XmlJsonNode>.from(section.children['DataArray']);
        } else if (section.children['DataArray'] is XmlJsonNode) {
          arr = [section.children['DataArray']];
        }

        for (final dataArray in arr) {
          if (dataArray.text != null && dataArray.text!.isNotEmpty) {
            // Store evaluated binary lists directly inside dynamic runtime objects
            dataArray.children['text_data'] = parseDataArray(dataArray, compressed);
          }
        }

        switch (sectionName) {
          case 'PointData':
            int numberOfPoints = int.parse(piece.attributes['NumberOfPoints'] ?? '0');
            String? normalsName = section.attributes['Normals'];
            if (numberOfPoints > 0) {
              for (final dataArray in arr) {
                if (normalsName == dataArray.attributes['Name']) {
                  int components = int.parse(dataArray.attributes['NumberOfComponents'] ?? '3');
                  normals = Float32List(numberOfPoints * components);
                  normals.setAll(0, dataArray.children['text_data']);
                }
              }
            }
            break;

          case 'Points':
            int numberOfPoints = int.parse(piece.attributes['NumberOfPoints'] ?? '0');
            if (numberOfPoints > 0 && arr.isNotEmpty) {
              final dataArray = arr[0];
              int components = int.parse(dataArray.attributes['NumberOfComponents'] ?? '3');
              points = Float32List(numberOfPoints * components);
              points.setAll(0, dataArray.children['text_data']);
            }
            break;

          case 'Strips':
            int numberOfStrips = int.parse(piece.attributes['NumberOfStrips'] ?? '0');
            if (numberOfStrips > 0 && arr.length >= 2) {
              final connData = arr[0].children['text_data'] as Int32List;
              final offsetData = arr[1].children['text_data'] as Int32List;

              int size = numberOfStrips + connData.length;
              indices = Uint32List(3 * size - 9 * numberOfStrips);
              int indicesIndex = 0;

              for (int i = 0; i < numberOfStrips; i++) {
                List<int> strip = [];
                int len1 = offsetData[i];
                int len0 = i > 0 ? offsetData[i - 1] : 0;

                for (int s = 0; s < len1 - len0; s++) {
                  strip.add(connData[s]);
                }

                for (int j = 0; j < len1 - len0 - 2; j++) {
                  if (j % 2 != 0) {
                    indices[indicesIndex++] = strip[j];
                    indices[indicesIndex++] = strip[j + 2];
                    indices[indicesIndex++] = strip[j + 1];
                  } else {
                    indices[indicesIndex++] = strip[j];
                    indices[indicesIndex++] = strip[j + 1];
                    indices[indicesIndex++] = strip[j + 2];
                  }
                }
              }
            }
            break;

          case 'Polys':
            int numberOfPolys = int.parse(piece.attributes['NumberOfPolys'] ?? '0');
            if (numberOfPolys > 0 && arr.length >= 2) {
              final connData = arr[0].children['text_data'] as Int32List;
              final offsetData = arr[1].children['text_data'] as Int32List;

              int size = numberOfPolys + connData.length;
              indices = Uint32List(3 * size - 9 * numberOfPolys);
              
              int indicesIndex = 0;
              int connectivityIndex = 0;
              int len0 = 0;

              for (int i = 0; i < numberOfPolys; i++) {
                List<int> poly = [];
                int len1 = offsetData[i];
                int s = 0;

                while (s < len1 - len0) {
                  poly.add(connData[connectivityIndex++]);
                  s++;
                }

                int j = 1;
                while (j < len1 - len0 - 1) {
                  indices[indicesIndex++] = poly[0];
                  indices[indicesIndex++] = poly[j];
                  indices[indicesIndex++] = poly[j + 1];
                  j++;
                }
                len0 = offsetData[i];
              }
            }
            break;
        }
      }

      final geometry = BufferGeometry();
      geometry.setIndex(Uint32BufferAttribute(indices, 1));
      geometry.setAttributeFromString('position', Float32BufferAttribute(points, 3));
      if (normals.length == points.length) {
        geometry.setAttributeFromString('normal', Float32BufferAttribute(normals, 3));
      }
      return geometry;
    } 
    else {
      throw Exception('Unsupported DATASET type');
    }
  }
}
