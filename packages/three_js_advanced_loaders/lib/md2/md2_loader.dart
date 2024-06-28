import 'dart:io';
import 'dart:typed_data';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

const _normalData = [
	[ - 0.525731, 0.000000, 0.850651 ], [ - 0.442863, 0.238856, 0.864188 ],
	[ - 0.295242, 0.000000, 0.955423 ], [ - 0.309017, 0.500000, 0.809017 ],
	[ - 0.162460, 0.262866, 0.951056 ], [ 0.000000, 0.000000, 1.000000 ],
	[ 0.000000, 0.850651, 0.525731 ], [ - 0.147621, 0.716567, 0.681718 ],
	[ 0.147621, 0.716567, 0.681718 ], [ 0.000000, 0.525731, 0.850651 ],
	[ 0.309017, 0.500000, 0.809017 ], [ 0.525731, 0.000000, 0.850651 ],
	[ 0.295242, 0.000000, 0.955423 ], [ 0.442863, 0.238856, 0.864188 ],
	[ 0.162460, 0.262866, 0.951056 ], [ - 0.681718, 0.147621, 0.716567 ],
	[ - 0.809017, 0.309017, 0.500000 ], [ - 0.587785, 0.425325, 0.688191 ],
	[ - 0.850651, 0.525731, 0.000000 ], [ - 0.864188, 0.442863, 0.238856 ],
	[ - 0.716567, 0.681718, 0.147621 ], [ - 0.688191, 0.587785, 0.425325 ],
	[ - 0.500000, 0.809017, 0.309017 ], [ - 0.238856, 0.864188, 0.442863 ],
	[ - 0.425325, 0.688191, 0.587785 ], [ - 0.716567, 0.681718, - 0.147621 ],
	[ - 0.500000, 0.809017, - 0.309017 ], [ - 0.525731, 0.850651, 0.000000 ],
	[ 0.000000, 0.850651, - 0.525731 ], [ - 0.238856, 0.864188, - 0.442863 ],
	[ 0.000000, 0.955423, - 0.295242 ], [ - 0.262866, 0.951056, - 0.162460 ],
	[ 0.000000, 1.000000, 0.000000 ], [ 0.000000, 0.955423, 0.295242 ],
	[ - 0.262866, 0.951056, 0.162460 ], [ 0.238856, 0.864188, 0.442863 ],
	[ 0.262866, 0.951056, 0.162460 ], [ 0.500000, 0.809017, 0.309017 ],
	[ 0.238856, 0.864188, - 0.442863 ], [ 0.262866, 0.951056, - 0.162460 ],
	[ 0.500000, 0.809017, - 0.309017 ], [ 0.850651, 0.525731, 0.000000 ],
	[ 0.716567, 0.681718, 0.147621 ], [ 0.716567, 0.681718, - 0.147621 ],
	[ 0.525731, 0.850651, 0.000000 ], [ 0.425325, 0.688191, 0.587785 ],
	[ 0.864188, 0.442863, 0.238856 ], [ 0.688191, 0.587785, 0.425325 ],
	[ 0.809017, 0.309017, 0.500000 ], [ 0.681718, 0.147621, 0.716567 ],
	[ 0.587785, 0.425325, 0.688191 ], [ 0.955423, 0.295242, 0.000000 ],
	[ 1.000000, 0.000000, 0.000000 ], [ 0.951056, 0.162460, 0.262866 ],
	[ 0.850651, - 0.525731, 0.000000 ], [ 0.955423, - 0.295242, 0.000000 ],
	[ 0.864188, - 0.442863, 0.238856 ], [ 0.951056, - 0.162460, 0.262866 ],
	[ 0.809017, - 0.309017, 0.500000 ], [ 0.681718, - 0.147621, 0.716567 ],
	[ 0.850651, 0.000000, 0.525731 ], [ 0.864188, 0.442863, - 0.238856 ],
	[ 0.809017, 0.309017, - 0.500000 ], [ 0.951056, 0.162460, - 0.262866 ],
	[ 0.525731, 0.000000, - 0.850651 ], [ 0.681718, 0.147621, - 0.716567 ],
	[ 0.681718, - 0.147621, - 0.716567 ], [ 0.850651, 0.000000, - 0.525731 ],
	[ 0.809017, - 0.309017, - 0.500000 ], [ 0.864188, - 0.442863, - 0.238856 ],
	[ 0.951056, - 0.162460, - 0.262866 ], [ 0.147621, 0.716567, - 0.681718 ],
	[ 0.309017, 0.500000, - 0.809017 ], [ 0.425325, 0.688191, - 0.587785 ],
	[ 0.442863, 0.238856, - 0.864188 ], [ 0.587785, 0.425325, - 0.688191 ],
	[ 0.688191, 0.587785, - 0.425325 ], [ - 0.147621, 0.716567, - 0.681718 ],
	[ - 0.309017, 0.500000, - 0.809017 ], [ 0.000000, 0.525731, - 0.850651 ],
	[ - 0.525731, 0.000000, - 0.850651 ], [ - 0.442863, 0.238856, - 0.864188 ],
	[ - 0.295242, 0.000000, - 0.955423 ], [ - 0.162460, 0.262866, - 0.951056 ],
	[ 0.000000, 0.000000, - 1.000000 ], [ 0.295242, 0.000000, - 0.955423 ],
	[ 0.162460, 0.262866, - 0.951056 ], [ - 0.442863, - 0.238856, - 0.864188 ],
	[ - 0.309017, - 0.500000, - 0.809017 ], [ - 0.162460, - 0.262866, - 0.951056 ],
	[ 0.000000, - 0.850651, - 0.525731 ], [ - 0.147621, - 0.716567, - 0.681718 ],
	[ 0.147621, - 0.716567, - 0.681718 ], [ 0.000000, - 0.525731, - 0.850651 ],
	[ 0.309017, - 0.500000, - 0.809017 ], [ 0.442863, - 0.238856, - 0.864188 ],
	[ 0.162460, - 0.262866, - 0.951056 ], [ 0.238856, - 0.864188, - 0.442863 ],
	[ 0.500000, - 0.809017, - 0.309017 ], [ 0.425325, - 0.688191, - 0.587785 ],
	[ 0.716567, - 0.681718, - 0.147621 ], [ 0.688191, - 0.587785, - 0.425325 ],
	[ 0.587785, - 0.425325, - 0.688191 ], [ 0.000000, - 0.955423, - 0.295242 ],
	[ 0.000000, - 1.000000, 0.000000 ], [ 0.262866, - 0.951056, - 0.162460 ],
	[ 0.000000, - 0.850651, 0.525731 ], [ 0.000000, - 0.955423, 0.295242 ],
	[ 0.238856, - 0.864188, 0.442863 ], [ 0.262866, - 0.951056, 0.162460 ],
	[ 0.500000, - 0.809017, 0.309017 ], [ 0.716567, - 0.681718, 0.147621 ],
	[ 0.525731, - 0.850651, 0.000000 ], [ - 0.238856, - 0.864188, - 0.442863 ],
	[ - 0.500000, - 0.809017, - 0.309017 ], [ - 0.262866, - 0.951056, - 0.162460 ],
	[ - 0.850651, - 0.525731, 0.000000 ], [ - 0.716567, - 0.681718, - 0.147621 ],
	[ - 0.716567, - 0.681718, 0.147621 ], [ - 0.525731, - 0.850651, 0.000000 ],
	[ - 0.500000, - 0.809017, 0.309017 ], [ - 0.238856, - 0.864188, 0.442863 ],
	[ - 0.262866, - 0.951056, 0.162460 ], [ - 0.864188, - 0.442863, 0.238856 ],
	[ - 0.809017, - 0.309017, 0.500000 ], [ - 0.688191, - 0.587785, 0.425325 ],
	[ - 0.681718, - 0.147621, 0.716567 ], [ - 0.442863, - 0.238856, 0.864188 ],
	[ - 0.587785, - 0.425325, 0.688191 ], [ - 0.309017, - 0.500000, 0.809017 ],
	[ - 0.147621, - 0.716567, 0.681718 ], [ - 0.425325, - 0.688191, 0.587785 ],
	[ - 0.162460, - 0.262866, 0.951056 ], [ 0.442863, - 0.238856, 0.864188 ],
	[ 0.162460, - 0.262866, 0.951056 ], [ 0.309017, - 0.500000, 0.809017 ],
	[ 0.147621, - 0.716567, 0.681718 ], [ 0.000000, - 0.525731, 0.850651 ],
	[ 0.425325, - 0.688191, 0.587785 ], [ 0.587785, - 0.425325, 0.688191 ],
	[ 0.688191, - 0.587785, 0.425325 ], [ - 0.955423, 0.295242, 0.000000 ],
	[ - 0.951056, 0.162460, 0.262866 ], [ - 1.000000, 0.000000, 0.000000 ],
	[ - 0.850651, 0.000000, 0.525731 ], [ - 0.955423, - 0.295242, 0.000000 ],
	[ - 0.951056, - 0.162460, 0.262866 ], [ - 0.864188, 0.442863, - 0.238856 ],
	[ - 0.951056, 0.162460, - 0.262866 ], [ - 0.809017, 0.309017, - 0.500000 ],
	[ - 0.864188, - 0.442863, - 0.238856 ], [ - 0.951056, - 0.162460, - 0.262866 ],
	[ - 0.809017, - 0.309017, - 0.500000 ], [ - 0.681718, 0.147621, - 0.716567 ],
	[ - 0.681718, - 0.147621, - 0.716567 ], [ - 0.850651, 0.000000, - 0.525731 ],
	[ - 0.688191, 0.587785, - 0.425325 ], [ - 0.587785, 0.425325, - 0.688191 ],
	[ - 0.425325, 0.688191, - 0.587785 ], [ - 0.425325, - 0.688191, - 0.587785 ],
	[ - 0.587785, - 0.425325, - 0.688191 ], [ - 0.688191, - 0.587785, - 0.425325 ]
];

class MD2LoaderData{
  MD2LoaderData(this.geometry,this.animations);
  BufferGeometry geometry;
  List<AnimationClip> animations;
}

class MD2Loader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [FontLoader].
  MD2Loader([LoadingManager? manager]):super(manager){
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
  Future<MD2LoaderData?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MD2LoaderData?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<MD2LoaderData?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MD2LoaderData?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<MD2LoaderData?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MD2LoaderData?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  /// If the type of format is unknown load it here.
  @override
  Future<MD2LoaderData?> unknown(dynamic url) async{
    if(url is File){
      return fromFile(url);
    }
    else if(url is Blob){
      return fromBlob(url);
    }
    else if(url is Uri){
      return fromNetwork(url);
    }
    else if(url is Uint8List){
      return fromBytes(url);
    }
    else if(url is String){
      if(url.contains('http://') || url.contains('https://')){  
        return fromNetwork(Uri.parse(url));
      }
      else if(url.contains('assets') || path.contains('assets')){
        return fromAsset(url);
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

	Future<MD2LoaderData?> _parse(Uint8List buffer ) async{
		final ByteData data = buffer.buffer.asByteData();

		// http://tfc.duke.free.fr/coding/md2-specs-en.html

		final header = {};
		const headerNames = [
			'ident', 'version',
			'skinwidth', 'skinheight',
			'framesize',
			'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
			'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
		];

		for (int i = 0; i < headerNames.length; i ++ ) {
			header[ headerNames[ i ] ] = data.getInt32( i * 4, Endian.little );
		}

		if ( header['ident'] != 844121161 || header['version'] != 8 ) {
			console.error( 'Not a valid MD2 file' );
			return null;
		}

		if ( header['offset_end'] != buffer.lengthInBytes ) {
			console.error( 'Corrupted MD2 file' );
			return null;
		}
		final geometry = BufferGeometry();

		final List<double> uvsTemp = [];
		int offset = header['offset_st'];

		for (int i = 0, l = header['num_st']; i < l; i ++ ) {
			final u = data.getInt16( offset + 0, Endian.little );
			final v = data.getInt16( offset + 2, Endian.little );
			uvsTemp.addAll([ u / header['skinwidth'], 1 - ( v / header['skinheight'] ) ]);
			offset += 4;
		}

		// triangles

		offset = header['offset_tris'];

		final List<int> vertexIndices = [];
		final uvIndices = [];

		for (int i = 0, l = header['num_tris']; i < l; i ++ ) {
			vertexIndices.addAll([
				data.getUint16( offset + 0, Endian.little ),
				data.getUint16( offset + 2, Endian.little ),
				data.getUint16( offset + 4, Endian.little )
			]);

			uvIndices.addAll([
				data.getUint16( offset + 6, Endian.little ),
				data.getUint16( offset + 8, Endian.little ),
				data.getUint16( offset + 10, Endian.little )
			]);

			offset += 12;
		}

		// frames

		final translation = Vector3.zero();
		final scale = Vector3.zero();
		final List<MorphTarget> frames = [];

		offset = header['offset_frames'];

		for (int i = 0, l = header['num_frames']; i < l; i ++ ) {

			scale.setValues(
				data.getFloat32( offset + 0, Endian.little ),
				data.getFloat32( offset + 4, Endian.little ),
				data.getFloat32( offset + 8, Endian.little )
			);

			translation.setValues(
				data.getFloat32( offset + 12, Endian.little ),
				data.getFloat32( offset + 16, Endian.little ),
				data.getFloat32( offset + 20, Endian.little )
			);

			offset += 24;
			final List<int> string = [];

			for (int j = 0; j < 16; j ++ ) {
				final character = data.getUint8( offset + j );
				if ( character == 0 ) break;
				string.add(character);
			}

			final Map<String,dynamic> frame = {
				'name': String.fromCharCodes(string ),
				'vertices': <Vector3>[],
				'normals': <Vector3>[]
			};

			offset += 16;

			for (int j = 0; j < header['num_vertices']; j ++ ) {
				double x = data.getUint8( offset ++ ) * 1.0;
				double y = data.getUint8( offset ++ ) * 1.0;
				double z = data.getUint8( offset ++ ) * 1.0;
				final n = _normalData[ data.getUint8( offset ++ ) ];

				x = x * scale.x + translation.x;
				y = y * scale.y + translation.y;
				z = z * scale.z + translation.z;

				frame['vertices']?.add(Vector3(x, z, y)); // convert to Y-up
				frame['normals']?.add(Vector3(n[ 0 ], n[ 2 ], n[ 1 ])); // convert to Y-up
			}

			frames.add(MorphTarget.fromJson(frame));
		}

		// static

		final List<double> positions = [];
		final List<double> normals = [];
		final List<double> uvs = [];

		final verticesTemp = frames[0].vertices;
		final normalsTemp = frames[0].normals;

		for (int i = 0, l = vertexIndices.length; i < l; i ++ ) {
			final vertexIndex = vertexIndices[i];

			final vec = verticesTemp[ vertexIndex ];
			positions.addAll(vec.storage);

			final n = normalsTemp[ vertexIndex ];
			normals.addAll(n.storage);

			final uvIndex = uvIndices[ i ];
			int stride = uvIndex * 2;

			final u = uvsTemp[ stride ];
			final v = uvsTemp[ stride + 1 ];

			uvs.addAll([ u, v ]);
		}

		geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( positions, 3 ) );
		geometry.setAttributeFromString( 'normal', Float32BufferAttribute.fromList( normals, 3 ) );
		geometry.setAttributeFromString( 'uv', Float32BufferAttribute.fromList( uvs, 2 ) );

		// animation

		final List<Float32BufferAttribute> morphPositions = [];
		final List<Float32BufferAttribute> morphNormals = [];

		for (int i = 0, l = frames.length; i < l; i ++ ) {
			final frame = frames[ i ];
			final attributeName = frame.name;

			if ( frame.vertices.isNotEmpty ) {
				final List<double> positions = [];

				for (int j = 0, jl = vertexIndices.length; j < jl; j ++ ) {
					final vertexIndex = vertexIndices[ j ];

					final v = frame.vertices[ vertexIndex ];
					positions.addAll(v.storage);
				}

				final positionAttribute = Float32BufferAttribute.fromList( positions, 3 );
				positionAttribute.name = attributeName;

				morphPositions.add( positionAttribute );
			}

			if ( frame.normals.isNotEmpty ) {
				final List<double> normals = [];

				for (int j = 0, jl = vertexIndices.length; j < jl; j ++ ) {
					final vertexIndex = vertexIndices[ j ];
					final n = frame.normals[ vertexIndex ];
					normals.addAll( n.storage);
				}

				final normalAttribute = Float32BufferAttribute.fromList( normals, 3 );
				normalAttribute.name = attributeName;

				morphNormals.add( normalAttribute );
			}
		}

		geometry.morphAttributes['position'] = morphPositions;
		geometry.morphAttributes['normal'] = morphNormals;
		geometry.morphTargetsRelative = false;
  
		return MD2LoaderData(geometry, AnimationClip.createClipsFromMorphTargetSequences( frames, 10 ));
	}
}