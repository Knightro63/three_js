import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

///
/// Description: A THREE loader for STL ASCII files, as created by Solidworks and other CAD programs.
///
/// Supports both binary and ASCII encoded files, with automatic detection of type.
///
/// The loader returns a non-indexed buffer geometry.
///
/// Limitations:
///  Binary decoding supports "Magics" color [format](http://en.wikipedia.org/wiki/STL_(file_format)#Color_in_binary_STL).
///  There is perhaps some question as to how valid it is to always assume little-endian-ness.
///  ASCII decoding assumes file is UTF-8.
///
/// Usage:
/// ```
///  final loader = STLLoader();
///  final geometry = await loader.fromAsset( 'assets/models/stl/slotted_disk.stl');
///  scene.add(Mesh(geometry));
///  ```
///
/// For binary STLs geometry might contain colors for vertices. To use it:
///  // use the same code to load STL as above
/// ```
///  if (geometry.hasColors) {
///    material = MeshPhongMaterial({ MaterialProperty.opacity: geometry.alpha, MaterialProperty.vertexColors: true });
///  } else { .... }
///  final mesh = Mesh( geometry, material );
///```
///
/// For ASCII STLs containing multiple solids, each solid is assigned to a different group.
/// Groups can be used to assign a different color by defining an array of materials with the same length of
/// geometry.groups and passing it to the Mesh constructor:
///```
/// final mesh = Mesh( geometry, material );
///```
/// For example:
///```
///  final materials = [];
///  final nGeometryGroups = geometry.groups.length;
///
///  final colorMap = ...; // Some logic to index colors.
///
///  for (int i = 0; i < nGeometryGroups; i++) {
///
///		final material = MeshPhongMaterial({
///			MaterialProperty.color: colorMap[i],
///			MaterialProperty.wireframe: false
///		});
///
///  }
///
///  materials.add(material);
///  final mesh = Mesh(geometry, materials);
///```
class STLLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
	STLLoader([super.manager]){
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
  Future<Mesh?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Mesh> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Mesh?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Mesh> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Mesh?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Mesh> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	Mesh _parse(Uint8List data) {

		bool matchDataViewAt(List<int> query, ByteData reader, int offset ) {
			// Check if each byte in query matches the corresponding byte from the current offset

			for (int i = 0, il = query.length; i < il; i ++ ) {
				if ( query[ i ] != reader.getUint8( offset + i ) ) return false;
			}

			return true;
		}
		bool isBinary(Uint8List data) {
			final reader = data.buffer.asByteData();
			const faceSize = ( 32 / 8 * 3 ) + ( ( 32 / 8 * 3 ) * 3 ) + ( 16 / 8 );
			final nFaces = reader.getUint32( 80, Endian.little );
			final expect = 80 + ( 32 / 8 ) + ( nFaces * faceSize );

			if ( expect == reader.lengthInBytes ) {
				return true;
			}

			// An ASCII STL data must begin with 'solid ' as the first six bytes.
			// However, ASCII STLs lacking the SPACE after the 'd' are known to be
			// plentiful.  So, check the first 5 bytes for 'solid'.

			// Several encodings, such as UTF-8, precede the text with up to 5 bytes:
			// https://en.wikipedia.org/wiki/Byte_order_mark#Byte_order_marks_by_encoding
			// Search for "solid" to start anywhere after those prefixes.

			// US-ASCII ordinal values for 's', 'o', 'l', 'i', 'd'

			const solid = [ 115, 111, 108, 105, 100 ];

			for (int off = 0; off < 5; off ++ ) {
				// If "solid" text is matched to the current offset, declare it to be an ASCII STL.
				if ( matchDataViewAt( solid, reader, off ) ) return false;
			}

			// Couldn't find "solid" text at the beginning; it is binary STL.
			return true;
		}

		Mesh parseBinary(Uint8List data ) {
			final reader = data.buffer.asByteData();
			final faces = reader.getUint32( 80, Endian.little );

			late double r, g, b;
      bool hasColors = false;
      late Float32Array colors;
			late double defaultR, defaultG, defaultB;
      double alpha = 1.0;

			// process STL header
			// check for default color in header ("COLOR=rgba" sequence).

			for (int index = 0; index < 80 - 10; index ++ ) {
				if ( ( reader.getUint32( index ) == 0x434F4C4F /*COLO*/ ) &&
					( reader.getUint8( index + 4 ) == 0x52 /*'R'*/ ) &&
					( reader.getUint8( index + 5 ) == 0x3D /*'='*/ ) ) {

					hasColors = true;
					colors = Float32Array( faces * 3 * 3 );

					defaultR = reader.getUint8( index + 6 ) / 255;
					defaultG = reader.getUint8( index + 7 ) / 255;
					defaultB = reader.getUint8( index + 8 ) / 255;
					alpha = reader.getUint8( index + 9 ) / 255;
				}
			}

			const dataOffset = 84;
			const faceLength = 12 * 4 + 2;

			final geometry = BufferGeometry();
			final vertices = Float32Array( faces * 3 * 3 );
			final normals = Float32Array( faces * 3 * 3 );
			final color = Color();

			for (int face = 0; face < faces; face ++ ) {
				final start = dataOffset + face * faceLength;
				final normalX = reader.getFloat32( start, Endian.little );
				final normalY = reader.getFloat32( start + 4, Endian.little );
				final normalZ = reader.getFloat32( start + 8, Endian.little );

				if ( hasColors ) {
					final packedColor = reader.getUint16( start + 48, Endian.little );

					if ( ( packedColor & 0x8000 ) == 0 ) {
						r = ( packedColor & 0x1F ) / 31;
						g = ( ( packedColor >> 5 ) & 0x1F ) / 31;
						b = ( ( packedColor >> 10 ) & 0x1F ) / 31;
					} else {
						r = defaultR;
						g = defaultG;
						b = defaultB;
					}
				}

				for (int i = 1; i <= 3; i ++ ) {
					final vertexstart = start + i * 12;
					final componentIdx = ( face * 3 * 3 ) + ( ( i - 1 ) * 3 );

					vertices[ componentIdx ] = reader.getFloat32( vertexstart, Endian.little  );
					vertices[ componentIdx + 1 ] = reader.getFloat32( vertexstart + 4, Endian.little  );
					vertices[ componentIdx + 2 ] = reader.getFloat32( vertexstart + 8, Endian.little  );

					normals[ componentIdx ] = normalX;
					normals[ componentIdx + 1 ] = normalY;
					normals[ componentIdx + 2 ] = normalZ;

					if ( hasColors ) {
						color..setValues( r, g, b )..convertSRGBToLinear();

						colors[ componentIdx ] = color.red;
						colors[ componentIdx + 1 ] = color.green;
						colors[ componentIdx + 2 ] = color.blue;
					}
				}
			}

			geometry.setAttributeFromString( 'position', Float32BufferAttribute( vertices, 3 ) );
			geometry.setAttributeFromString( 'normal', Float32BufferAttribute( normals, 3 ) );

			if ( hasColors ) {
				geometry.setAttributeFromString( 'color', Float32BufferAttribute( colors, 3 ) );
				//geometry.hasColors = true;
				//geometry.alpha = alpha;
			}

      return Mesh(geometry,MeshPhongMaterial.fromMap({"color": color.getHex(),"flatShading": false,"side": DoubleSide, 'opacity': alpha}));
		}

		Mesh parseASCII(String data) {
			final geometry = BufferGeometry();
			final patternSolid = RegExp(r'solid([\s\S]*?)endsolid', multiLine: true);
			final patternFace = RegExp(r'facet([\s\S]*?)endfacet', multiLine: true);
			final patternName = RegExp(r'solid\s(.+)');
			int faceCounter = 0;

			const patternFloat = r'[\s]+([+-]?(?:\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?)';
			final patternVertex = RegExp('vertex$patternFloat$patternFloat$patternFloat',multiLine: true);
			final patternNormal = RegExp('normal$patternFloat$patternFloat$patternFloat',multiLine: true);
      
      final RegExp patternColor = RegExp(r'endsolid\s+\w+=RGB\((\d+),(\d+),(\d+)\)');

			final List<double> vertices = [];
			final List<double> normals = [];
			final List<String> groupNames = [];

      List<Color> colors = patternColor
          .allMatches(data)
          .map(
            (e) => Color(
              double.parse(e.group(1)!) / 255,
              double.parse(e.group(2)!) / 255,
              double.parse(e.group(3)!) / 255,
            ),
          )
          .toList();

			final normal = Vector3();

			int groupCount = 0;
			int startVertex = 0;
			int endVertex = 0;

			for(RegExpMatch? match1 in patternSolid.allMatches(data)){
				startVertex = endVertex;
				final solid = match1!.group(0);

        final name = (match1 = patternName.firstMatch(solid!)) != null? match1!.group(1): '';
				groupNames.add(name!);

				for (RegExpMatch match2 in patternFace.allMatches(solid)) {
					int vertexCountPerFace = 0;
					int normalCountPerFace = 0;

					final text = match2.group(0)!;

					for (Match match in patternNormal.allMatches(text)) {
						normal.x = double.parse( match.group(1)!);
						normal.y = double.parse(match.group(2)!);
						normal.z = double.parse(match.group(3)!);
						normalCountPerFace ++;
					}

					for (Match match in patternVertex.allMatches(text)) {
						vertices.addAll([ 
              double.parse(match.group(1)!), 
              double.parse(match.group(2)!), 
              double.parse(match.group(3)!) 
            ]);
						normals.addAll([ normal.x, normal.y, normal.z ]);
						vertexCountPerFace ++;
						endVertex ++;
					}

					// every face have to own ONE valid normal
					if ( normalCountPerFace != 1 ) {
						console.error('STLLoader: Something isn\'t right with the normal of face number $faceCounter');
					}

					// each face have to own THREE valid vertices
					if ( vertexCountPerFace != 3 ) {
						console.error( 'STLLoader: Something isn\'t right with the vertices of face number $faceCounter');
					}

					faceCounter ++;
				}

				final start = startVertex;
				final count = endVertex - startVertex;

				geometry.userData['groupNames'] = groupNames;

				geometry.addGroup( start, count, groupCount );
				groupCount++;
			}

			geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( vertices, 3 ) );
			geometry.setAttributeFromString( 'normal', Float32BufferAttribute.fromList( normals, 3 ) );

      Material? material;
      GroupMaterial? groupMaterial;

      if (colors.length != groupCount) {
        // apply default material to each group
        List<Material> materials = List.generate(groupCount,(index) => MeshBasicMaterial.fromMap({"color": 0xffffff, "flatShading": true, "side": DoubleSide}));

        if(materials.length == 1){
          material = materials[0];
        }
        else{
          groupMaterial = GroupMaterial(materials);
        }
      } 
      else {
        // use extracted colors
        List<Material> materials = colors.map((e) => MeshBasicMaterial.fromMap({"color": e.getHex(), "flatShading": true, "side": DoubleSide})).toList();
      
        if(materials.length == 1){
          material = materials[0];
        }
        else{
          groupMaterial = GroupMaterial(materials);
        }
      }

      return Mesh(geometry, material ?? groupMaterial);
		}

		String ensureString(Uint8List buffer ) {
			return String.fromCharCodes(buffer);
		}

		return isBinary( data ) ? parseBinary( data ) : parseASCII( ensureString( data ) );
	}
}