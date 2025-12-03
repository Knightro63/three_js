import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class PCDHeader{
  String? data;
  int? width;
  int? height;
  List<String> type = [];
  String? str;
  double? version;
  List<int> count = [];
  List<int> size = [];
  int rowSize = 0;
  int headerLen = 0;
  List<String> fields = [];
  dynamic viewpoint;
  dynamic points;

  Map? offset;

  @override
  String toString() {
    return {
      'data': data,
      'width': width,
      'height': height,
      'type': type,
      'str': str,
      'version': version,
      'count': count,
      'size': size,
      'rowSize': rowSize,
      'headerLen': headerLen,
      'fields':fields,
      'viewpoint': viewpoint,
      'points': points,
      'offset': offset
    }.toString();
  }
}

/**
 * A loader for the Point Cloud Data (PCD) format.
 *
 * PCDLoader supports ASCII and (compressed) binary files as well as the following PCD fields:
 * - x y z
 * - rgb
 * - normal_x normal_y normal_z
 * - intensity
 * - label
 *
 * ```js
 * final loader = new PCDLoader();
 *
 * final points = await loader.loadAsync( './models/pcd/binary/Zaghetto.pcd' );
 * points.geometry.center(); // optional
 * points.geometry.rotateX( Math.PI ); // optional
 * scene.add( points );
 * ```
 *
 * @augments Loader
 * @three_import import { PCDLoader } from 'three/addons/loaders/PCDLoader.js';
 */
class PCDLoader extends Loader {
  Endian endian = Endian.little;
  late final FileLoader _loader;

	/**
	 * Constructs a new PCD loader.
	 *
	 * @param {LoadingManager} [manager] - The loading manager.
	 */
	PCDLoader([LoadingManager? manager ]):super(manager){
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
  Future<Points?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Points?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Points?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Points?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Points?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Points?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  @override
  PCDLoader setPath(String path) {
    super.setPath(path);
    return this;
  }

	/**
	 * Get dataview value by field type and size.
	 *
	 * @param {DataView} dataview - The DataView to read from.
	 * @param {number} offset - The offset to start reading from.
	 * @param {'F' | 'U' | 'I'} type - Field type.
	 * @param {number} size - Field size.
	 * @returns {number} Field value.
	 */
	_getDataView(ByteData dataview, int offset, String type, int size ) {
		switch ( type ) {
			case 'F': {
				if ( size == 8 ) {
					return dataview.getFloat64( offset, endian );
				}
				return dataview.getFloat32( offset, endian );
			}

			case 'I': {
				if ( size == 1 ) {
					return dataview.getInt8( offset );
				}
				if ( size == 2 ) {
					return dataview.getInt16( offset, endian );
				}
				return dataview.getInt32( offset, endian );
			}

			case 'U': {
				if ( size == 1 ) {
					return dataview.getUint8( offset );
				}
				if ( size == 2 ) {
					return dataview.getUint16( offset, endian );
				}
				return dataview.getUint32( offset, endian );
			}
		}
	}


	/**
	 * Parses the given PCD data and returns a point cloud.
	 *
	 * @param {ArrayBuffer} data - The raw PCD data as an array buffer.
	 * @return {Points} The parsed point cloud.
	 */
	Points _parse(Uint8List data ) {
		// from https://gitlab.com/taketwo/three-pcd-loader/blob/master/decompress-lzf.js

		Uint8List decompressLZF(Uint8List inData, int outLength) {
			final int inLength = inData.lengthInBytes;
			final Uint8List outData = Uint8List(outLength);
			int inPtr = 0;
			int outPtr = 0;
			int ctrl;
			int len;
			int ref;

			while (inPtr < inLength) {
				ctrl = inData[inPtr++];

				if (ctrl < (1 << 5)) {
					// Literal run
					ctrl++;
					if (outPtr + ctrl > outLength) {
						throw StateError('Output buffer is not large enough');
					}
					if (inPtr + ctrl > inLength) {
						throw StateError('Invalid compressed data');
					}
					
					// Copy bytes one by one using a while loop
					int count = ctrl;
					while (count-- > 0) {
						outData[outPtr++] = inData[inPtr++];
					}
					
				} else {
					// Back reference
					len = ctrl >> 5;
					ref = outPtr - ((ctrl & 0x1f) << 8) - 1;

					if (inPtr >= inLength) {
						throw StateError('Invalid compressed data');
					}

					if (len == 7) {
						len += inData[inPtr++];
						if (inPtr >= inLength) {
							throw StateError('Invalid compressed data');
						}
					}

					ref -= inData[inPtr++];
					
					// The length in JS was adjusted inside the do-while condition (len-- + 2)
					final int copyLength = len + 2;

					if (outPtr + copyLength > outLength) {
						throw StateError('Output buffer is not large enough');
					}
					if (ref < 0) {
						throw StateError('Invalid compressed data (reference < 0)');
					}
					if (ref >= outPtr) {
						throw StateError('Invalid compressed data (reference >= outPtr)');
					}

					// Copy bytes from the existing output data (back reference)
					int count = copyLength;
					while (count-- > 0) {
						outData[outPtr++] = outData[ref++];
					}
				}
			}

			return outData;
		}
		PCDHeader parseHeader(Uint8List binaryData ) {
			PCDHeader PCDheader = PCDHeader();
			final buffer = binaryData;

			String sData = '';
			String line = '';
			int i = 0;
			bool end = false;

			final max = buffer.length;

			while ( i < max && end == false ) {
			final char = String.fromCharCode( buffer[ i ++ ] );

				if ( char == '\n' || char == '\r' ) {
					if ( line.trim().toLowerCase().startsWith( 'data' ) ) {
						end = true;
					}

					line = '';
				} 
				else {
					line += char;
				}

				sData += char;
			}

			final result1 = sData.indexOf(RegExp(r'[\r\n]DATA\s(\S*)\s',caseSensitive: false,));//data.search( /[\r\n]DATA\s(\S*)\s/i );
			final result = RegExp(r'[\r\n]DATA\s(\S*)\s',caseSensitive: false).firstMatch(sData.substring(result1 - 1));//
			final result2 = result?.group(1);///[\r\n]DATA\s(\S*)\s/i.exec( data.slice( result1 - 1 ) );
			PCDheader.data = result2!;
			PCDheader.headerLen = result!.group(0)!.length + result1;
			PCDheader.str = sData.substring(0, PCDheader.headerLen);

			// remove comments
			PCDheader.str = PCDheader.str?.replaceAll(RegExp(r'#.*', caseSensitive: false), '' );

			// parse
			final version = RegExp(r'^VERSION (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^VERSION (.*)/im.exec( PCDheader.str );
      final fields = RegExp(r'^FIELDS (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^FIELDS (.*)/im.exec( PCDheader.str );
			final size = RegExp(r'^SIZE (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^SIZE (.*)/im.exec( PCDheader.str );
			final type = RegExp(r'^TYPE (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^TYPE (.*)/im.exec( PCDheader.str );
			final count = RegExp(r'^COUNT (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^COUNT (.*)/im.exec( PCDheader.str );
			final width = RegExp(r'^WIDTH (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^WIDTH (.*)/im.exec( PCDheader.str );
			final height = RegExp(r'^HEIGHT (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^HEIGHT (.*)/im.exec( PCDheader.str );
			final viewpoint = RegExp(r'^VIEWPOINT (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^VIEWPOINT (.*)/im.exec( PCDheader.str );
			final points = RegExp(r'^POINTS (.*)',caseSensitive: false,multiLine: true).firstMatch( PCDheader.str!);//^POINTS (.*)/im.exec( PCDheader.str );

			// evaluate
			if (version != null )
				PCDheader.version = double.tryParse(version.group(1) ?? '' );

			PCDheader.fields = ( fields != null ) ? fields.group(1)!.split( ' ' ) : [];

			if (type != null )
				PCDheader.type = type.group(1)?.split( ' ' ) ?? [];

			if (width != null )
				PCDheader.width = int.tryParse(width.group(1) ?? '' );

			if (height != null )
				PCDheader.height = int.tryParse( height.group(1) ?? '' );

			if (viewpoint != null )
				PCDheader.viewpoint = viewpoint[ 1 ];

			if (points != null )
				PCDheader.points = int.tryParse( points.group(1) ?? '', radix: 10 );

			if ( points == null )
				PCDheader.points = PCDheader.width! * PCDheader.height!;

			if (size != null ) {
				PCDheader.size = size.group(1)?.split( ' ' ).map( ( x ) {
					return int.parse( x, radix: 10 );
				} ).toList() ?? [];
			}

			if (count != null) {
				PCDheader.count = count.group(1)?.split( ' ' ).map( ( x ) {
					return int.parse( x, radix: 10 );
				} ).toList() ?? [];
			} 
      		else {
				PCDheader.count = [];
				for (int i = 0, l = PCDheader.fields.length; i < l; i ++ ) {
					PCDheader.count.add( 1 );
				}
			}

			PCDheader.offset = {};

			int sizeSum = 0;

			for (int i = 0, l = PCDheader.fields.length; i < l; i ++ ) {
				if ( PCDheader.data == 'ascii' ) {
					PCDheader.offset![ PCDheader.fields[ i ] ] = i;
				} 
				else {
					PCDheader.offset![ PCDheader.fields[ i ] ] = sizeSum;
					sizeSum += PCDheader.size[ i ] * PCDheader.count[ i ];
				}
			}

			// for binary only
			PCDheader.rowSize = sizeSum;
			return PCDheader;
		}

		// parse header

		final PCDheader = parseHeader( data );

		// parse data

		final position = <double>[];
		final normal = <double>[];
		final color = <double>[];
		final intensity = <double>[];
		final label = <int>[];

		final c = new Color();

		// ascii

		if ( PCDheader.data == 'ascii' ) {
			final offset = PCDheader.offset!;
			final textData = utf8.decode(data);
			final pcdData = textData.substring( PCDheader.headerLen);
			final lines = pcdData.split( '\n' );

			for (int i = 0, l = lines.length; i < l; i ++ ) {
				if ( lines[ i ] == '' ) continue;
				final line = lines[ i ].split( ' ' );

				if ( offset['x'] != null ) {
					position.add( double.parse( line[ offset['x'] ] ) );
					position.add( double.parse( line[ offset['y'] ] ) );
					position.add( double.parse( line[ offset['z'] ] ) );
				}

				if ( offset['rgb'] != null ) {
					final rgb_field_index = PCDheader.fields.indexWhere((field) => field == 'rgb');
					final rgb_type = PCDheader.type[ rgb_field_index ];

					final float = double.parse( line[ offset['rgb'] ] );
					int rgb = float.toInt();

					if ( rgb_type == 'F' ) {
						// treat float values as int
						// https://github.com/daavoo/pyntcloud/pull/204/commits/7b4205e64d5ed09abe708b2e91b615690c24d518
						final farr = new Float32Array( 1 );
						farr[ 0 ] = float;
						rgb = new Int32Array.fromList( farr.toDartList().buffer.asInt32List() )[ 0 ];
					}

					final r = ( ( rgb >> 16 ) & 0x0000ff ) / 255;
					final g = ( ( rgb >> 8 ) & 0x0000ff ) / 255;
					final b = ( ( rgb >> 0 ) & 0x0000ff ) / 255;

					c.setRGB( r, g, b, ColorSpace.srgb );

					color.addAll([ c.red, c.green, c.blue ]);
				}

				if ( offset['normal_x'] != null ) {
					normal.add( double.parse( line[ offset['normal_x'] ] ) );
					normal.add( double.parse( line[ offset['normal_y'] ] ) );
					normal.add( double.parse( line[ offset['normal_z'] ] ) );
				}

				if ( offset['intensity'] != null ) {
					intensity.add( double.parse( line[ offset['intensity'] ] ) );
				}

				if ( offset['label'] != null ) {
					label.add( int.parse( line[ offset['label'] ] ) );
				}
			}
		}

		// binary-compressed

		// normally data in PCD files are organized as array of structures: XYZRGBXYZRGB
		// binary compressed PCD files organize their data as structure of arrays: XXYYZZRGBRGB
		// that requires a totally different parsing approach compared to non-compressed data

		if ( PCDheader.data == 'binary_compressed' ) {
			final sizes = data.sublist(PCDheader.headerLen, PCDheader.headerLen + 8).buffer.asUint32List();
			final compressedSize = sizes[0];
			final decompressedSize = sizes[1];

			final t = data.sublist(PCDheader.headerLen + 8, compressedSize);
			final decompressed = decompressLZF(t, decompressedSize);
			final dataview = ByteData.view(decompressed.buffer);

			final offset = PCDheader.offset ?? {};

			for ( int i = 0; i < PCDheader.points; i ++ ) {
				if ( offset['x'] != null ) {
					final xIndex = PCDheader.fields.indexOf( 'x' );
					final yIndex = PCDheader.fields.indexOf( 'y' );
					final zIndex = PCDheader.fields.indexOf( 'z' );
					position.add( this._getDataView( dataview, ( PCDheader.points * offset['x'] ) + PCDheader.size[ xIndex ] * i, PCDheader.type[ xIndex ], PCDheader.size[ xIndex ] ) );
					position.add( this._getDataView( dataview, ( PCDheader.points * offset['y'] ) + PCDheader.size[ yIndex ] * i, PCDheader.type[ yIndex ], PCDheader.size[ yIndex ] ) );
					position.add( this._getDataView( dataview, ( PCDheader.points * offset['z'] ) + PCDheader.size[ zIndex ] * i, PCDheader.type[ zIndex ], PCDheader.size[ zIndex ] ) );
				}

				if ( offset['rgb'] != null ) {
					final rgbIndex = PCDheader.fields.indexOf( 'rgb' );

					final r = dataview.getUint8( ( PCDheader.points * offset['rgb'] ) + PCDheader.size[ rgbIndex ] * i + 2 ) / 255.0;
					final g = dataview.getUint8( ( PCDheader.points * offset['rgb'] ) + PCDheader.size[ rgbIndex ] * i + 1 ) / 255.0;
					final b = dataview.getUint8( ( PCDheader.points * offset['rgb'] ) + PCDheader.size[ rgbIndex ] * i + 0 ) / 255.0;

					c.setRGB( r, g, b, ColorSpace.srgb );

					color.addAll([ c.red, c.green, c.blue ]);
				}

				if ( offset['normal_x'] != null ) {
					final xIndex = PCDheader.fields.indexOf( 'normal_x' );
					final yIndex = PCDheader.fields.indexOf( 'normal_y' );
					final zIndex = PCDheader.fields.indexOf( 'normal_z' );
					normal.add( this._getDataView( dataview, ( PCDheader.points * offset['normal_x'] ) + PCDheader.size[ xIndex ] * i, PCDheader.type[ xIndex ], PCDheader.size[ xIndex ] ) );
					normal.add( this._getDataView( dataview, ( PCDheader.points * offset['normal_y'] ) + PCDheader.size[ yIndex ] * i, PCDheader.type[ yIndex ], PCDheader.size[ yIndex ] ) );
					normal.add( this._getDataView( dataview, ( PCDheader.points * offset['normal_z'] ) + PCDheader.size[ zIndex ] * i, PCDheader.type[ zIndex ], PCDheader.size[ zIndex ] ) );
				}

				if ( offset['intensity'] != null ) {
					final intensityIndex = PCDheader.fields.indexOf( 'intensity' );
					intensity.add( this._getDataView( dataview, ( PCDheader.points * offset['intensity'] ) + PCDheader.size[ intensityIndex ] * i, PCDheader.type[ intensityIndex ], PCDheader.size[ intensityIndex ] ) );
				}

				if ( offset['label'] != null ) {
					final labelIndex = PCDheader.fields.indexOf( 'label' );
					label.add( dataview.getInt32( ( PCDheader.points * offset['label'] ) + PCDheader.size[ labelIndex ] * i, endian ) );
				}
			}
		}

		// binary

		if ( PCDheader.data == 'binary' ) {
			final dataview = ByteData.view( Uint8List.fromList(data).buffer, PCDheader.headerLen);
			final offset = PCDheader.offset!;

			for ( int i = 0, row = 0; i < PCDheader.points; i++, row += PCDheader.rowSize ) {
				if ( offset['x'] != null ) {
					final xIndex = PCDheader.fields.indexOf( 'x' );
					final yIndex = PCDheader.fields.indexOf( 'y' );
					final zIndex = PCDheader.fields.indexOf( 'z' );
					position.add( this._getDataView( dataview, row + offset['x'] as int, PCDheader.type[ xIndex ], PCDheader.size[ xIndex ] ) );
					position.add( this._getDataView( dataview, row + offset['y'] as int, PCDheader.type[ yIndex ], PCDheader.size[ yIndex ] ) );
					position.add( this._getDataView( dataview, row + offset['z'] as int, PCDheader.type[ zIndex ], PCDheader.size[ zIndex ] ) );
				}

				if ( offset['rgb'] != null ) {
					final r = dataview.getUint8( row + offset['rgb'] + 2  as int,) / 255.0;
					final g = dataview.getUint8( row + offset['rgb'] + 1  as int,) / 255.0;
					final b = dataview.getUint8( row + offset['rgb'] + 0  as int,) / 255.0;

					c.setRGB( r, g, b, ColorSpace.srgb );

					color.addAll([ c.red, c.green, c.blue ]);
				}

				if ( offset['normal_x'] != null ) {
					final xIndex = PCDheader.fields.indexOf( 'normal_x' );
					final yIndex = PCDheader.fields.indexOf( 'normal_y' );
					final zIndex = PCDheader.fields.indexOf( 'normal_z' );
					normal.add( this._getDataView( dataview, row + offset['normal_x'] as int, PCDheader.type[ xIndex ], PCDheader.size[ xIndex ] ) );
					normal.add( this._getDataView( dataview, row + offset['normal_y'] as int, PCDheader.type[ yIndex ], PCDheader.size[ yIndex ] ) );
					normal.add( this._getDataView( dataview, row + offset['normal_z'] as int, PCDheader.type[ zIndex ], PCDheader.size[ zIndex ] ) );
				}

				if ( offset['intensity'] != null ) {
					final intensityIndex = PCDheader.fields.indexOf( 'intensity' );
					intensity.add( this._getDataView( dataview, row + offset['intensity'] as int, PCDheader.type[ intensityIndex ], PCDheader.size[ intensityIndex ] ) );
				}

				if ( offset['label'] != null ) {
					label.add( dataview.getInt32( row + offset['label'] as int, endian ) );
				}
			}
		}

		// build geometry

		final geometry = new BufferGeometry();

		if ( position.length > 0 ) geometry.setAttributeFromString( 'position', new Float32BufferAttribute.fromList( position, 3 ) );
		if ( normal.length > 0 ) geometry.setAttributeFromString( 'normal', new Float32BufferAttribute.fromList( normal, 3 ) );
		if ( color.length > 0 ) geometry.setAttributeFromString( 'color', new Float32BufferAttribute.fromList( color, 3 ) );
		if ( intensity.length > 0 ) geometry.setAttributeFromString( 'intensity', new Float32BufferAttribute.fromList( intensity, 1 ) );
		if ( label.length > 0 ) geometry.setAttributeFromString( 'label', new Int32BufferAttribute.fromList( label, 1 ) );

		geometry.computeBoundingSphere();

		// build material
		final material = new PointsMaterial.fromMap( { 'size': 0.005 } );

		if ( color.length > 0 ) {
			material.vertexColors = true;
		}

		// build point cloud
		return new Points( geometry, material );
	}
}
