import 'dart:io';
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class VOXLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
	VOXLoader([super.manager]){
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
  Future<List<Chunk>?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<Chunk>?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<List<Chunk>?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<Chunk>?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<List<Chunk>?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<Chunk>?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	List<Chunk>? _parse(Uint8List buffer) {
		final data = buffer.buffer.asByteData();//DataView( buffer );

		final id = data.getUint32( 0, Endian.little );
		final version = data.getUint32( 4, Endian.little );

		if ( id != 542658390 || version != 150 ) {
			console.error( 'Not a valid VOX file' );
			return null;
		}

		const dPallet = [
			0x00000000, 0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff, 0xffffccff,
			0xffccccff, 0xff99ccff, 0xff66ccff, 0xff33ccff, 0xff00ccff, 0xffff99ff, 0xffcc99ff, 0xff9999ff,
			0xff6699ff, 0xff3399ff, 0xff0099ff, 0xffff66ff, 0xffcc66ff, 0xff9966ff, 0xff6666ff, 0xff3366ff,
			0xff0066ff, 0xffff33ff, 0xffcc33ff, 0xff9933ff, 0xff6633ff, 0xff3333ff, 0xff0033ff, 0xffff00ff,
			0xffcc00ff, 0xff9900ff, 0xff6600ff, 0xff3300ff, 0xff0000ff, 0xffffffcc, 0xffccffcc, 0xff99ffcc,
			0xff66ffcc, 0xff33ffcc, 0xff00ffcc, 0xffffcccc, 0xffcccccc, 0xff99cccc, 0xff66cccc, 0xff33cccc,
			0xff00cccc, 0xffff99cc, 0xffcc99cc, 0xff9999cc, 0xff6699cc, 0xff3399cc, 0xff0099cc, 0xffff66cc,
			0xffcc66cc, 0xff9966cc, 0xff6666cc, 0xff3366cc, 0xff0066cc, 0xffff33cc, 0xffcc33cc, 0xff9933cc,
			0xff6633cc, 0xff3333cc, 0xff0033cc, 0xffff00cc, 0xffcc00cc, 0xff9900cc, 0xff6600cc, 0xff3300cc,
			0xff0000cc, 0xffffff99, 0xffccff99, 0xff99ff99, 0xff66ff99, 0xff33ff99, 0xff00ff99, 0xffffcc99,
			0xffcccc99, 0xff99cc99, 0xff66cc99, 0xff33cc99, 0xff00cc99, 0xffff9999, 0xffcc9999, 0xff999999,
			0xff669999, 0xff339999, 0xff009999, 0xffff6699, 0xffcc6699, 0xff996699, 0xff666699, 0xff336699,
			0xff006699, 0xffff3399, 0xffcc3399, 0xff993399, 0xff663399, 0xff333399, 0xff003399, 0xffff0099,
			0xffcc0099, 0xff990099, 0xff660099, 0xff330099, 0xff000099, 0xffffff66, 0xffccff66, 0xff99ff66,
			0xff66ff66, 0xff33ff66, 0xff00ff66, 0xffffcc66, 0xffcccc66, 0xff99cc66, 0xff66cc66, 0xff33cc66,
			0xff00cc66, 0xffff9966, 0xffcc9966, 0xff999966, 0xff669966, 0xff339966, 0xff009966, 0xffff6666,
			0xffcc6666, 0xff996666, 0xff666666, 0xff336666, 0xff006666, 0xffff3366, 0xffcc3366, 0xff993366,
			0xff663366, 0xff333366, 0xff003366, 0xffff0066, 0xffcc0066, 0xff990066, 0xff660066, 0xff330066,
			0xff000066, 0xffffff33, 0xffccff33, 0xff99ff33, 0xff66ff33, 0xff33ff33, 0xff00ff33, 0xffffcc33,
			0xffcccc33, 0xff99cc33, 0xff66cc33, 0xff33cc33, 0xff00cc33, 0xffff9933, 0xffcc9933, 0xff999933,
			0xff669933, 0xff339933, 0xff009933, 0xffff6633, 0xffcc6633, 0xff996633, 0xff666633, 0xff336633,
			0xff006633, 0xffff3333, 0xffcc3333, 0xff993333, 0xff663333, 0xff333333, 0xff003333, 0xffff0033,
			0xffcc0033, 0xff990033, 0xff660033, 0xff330033, 0xff000033, 0xffffff00, 0xffccff00, 0xff99ff00,
			0xff66ff00, 0xff33ff00, 0xff00ff00, 0xffffcc00, 0xffcccc00, 0xff99cc00, 0xff66cc00, 0xff33cc00,
			0xff00cc00, 0xffff9900, 0xffcc9900, 0xff999900, 0xff669900, 0xff339900, 0xff009900, 0xffff6600,
			0xffcc6600, 0xff996600, 0xff666600, 0xff336600, 0xff006600, 0xffff3300, 0xffcc3300, 0xff993300,
			0xff663300, 0xff333300, 0xff003300, 0xffff0000, 0xffcc0000, 0xff990000, 0xff660000, 0xff330000,
			0xff0000ee, 0xff0000dd, 0xff0000bb, 0xff0000aa, 0xff000088, 0xff000077, 0xff000055, 0xff000044,
			0xff000022, 0xff000011, 0xff00ee00, 0xff00dd00, 0xff00bb00, 0xff00aa00, 0xff008800, 0xff007700,
			0xff005500, 0xff004400, 0xff002200, 0xff001100, 0xffee0000, 0xffdd0000, 0xffbb0000, 0xffaa0000,
			0xff880000, 0xff770000, 0xff550000, 0xff440000, 0xff220000, 0xff110000, 0xffeeeeee, 0xffdddddd,
			0xffbbbbbb, 0xffaaaaaa, 0xff888888, 0xff777777, 0xff555555, 0xff444444, 0xff222222, 0xff111111
		];

		int i = 8;

		Chunk chunk = Chunk();
		List<Chunk> chunks = [];

		while ( i < data.lengthInBytes ) {
			String id = '';

			for (int j = 0; j < 4; j ++ ) {
				id += String.fromCharCode( data.getUint8( i ++ ) );
			}

			final chunkSize = data.getUint32( i, Endian.little ); i += 4;
			i += 4; // childChunks

			if ( id == 'SIZE' ) {
				final x = data.getUint32( i, Endian.little ); i += 4;
				final y = data.getUint32( i, Endian.little ); i += 4;
				final z = data.getUint32( i, Endian.little ); i += 4;

				chunk = Chunk(
					palette: dPallet,
					size: Vector3(x.toDouble(),y.toDouble(),z.toDouble()),
        );

				chunks.add( chunk );

				i += chunkSize - ( 3 * 4 );
			} 
      else if ( id == 'XYZI' ) {
				final numVoxels = data.getUint32( i, Endian.little ); 
        i += 4;
				chunk.data = buffer.sublist(i, numVoxels * 4 );

				i += numVoxels * 4;
			} 
      else if ( id == 'RGBA' ) {
				final palette = [ 0 ];

				for (int j = 0; j < 256; j ++ ) {
					palette.add(data.getUint32( i, Endian.little )); 
          i += 4;
				}

				chunk.palette = palette;
			} 
      else {
				// console.log( id, chunkSize, childChunks );
				i += chunkSize;
			}
		}

		return chunks;
	}
}

class VOXMesh extends Mesh {
  VOXMesh.create([BufferGeometry? geometry, Material? material]):super( geometry, material );

	factory VOXMesh(Chunk chunk){
		final data = chunk.data;
		final size = chunk.size;
		final palette = chunk.palette;

		final List<double> vertices = [];
		final List<double> colors = [];

		const nx = [ 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1 ];
		const px = [ 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0 ];
		const py = [ 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1 ];
		const ny = [ 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0 ];
		const nz = [ 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0 ];
		const pz = [ 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1 ];

		final color = Color();

		void add( tile, x, y, z, r, g, b ) {
			x -= size.x / 2;
			y -= size.z / 2;
			z += size.y / 2;

			for (int i = 0; i < 18; i += 3 ) {
				color.setRGB( r, g, b, ColorSpace.srgb );

				vertices.addAll([ tile[ i + 0 ] + x, tile[ i + 1 ] + y, tile[ i + 2 ] + z ]);
				colors.addAll([ color.red, color.green, color.blue ]);
			}
		}

		// Store data in a volume for sampling

		final offsety = size.x.toInt();
		final offsetz = (size.x * size.y).toInt();

		final array = Uint8List( (size.x * size.y * size.z).toInt() );

		for (int j = 0; j < data!.length; j += 4 ) {
			final x = data[ j + 0 ];
			final y = data[ j + 1 ];
			final z = data[ j + 2 ];
			final index = (x + ( y * offsety ) + ( z * offsetz )).toInt();

			array[ index ] = 255;
		}

		// Construct geometry

		bool hasColors = false;

		for (int j = 0; j < data.length; j += 4 ) {
			final x = data[ j + 0 ];
			final y = data[ j + 1 ];
			final z = data[ j + 2 ];
			final c = data[ j + 3 ];

			final hex = palette![ c ];
			final r = ( hex >> 0 & 0xff ) / 0xff;
			final g = ( hex >> 8 & 0xff ) / 0xff;
			final b = ( hex >> 16 & 0xff ) / 0xff;

			if ( r > 0 || g > 0 || b > 0 ) hasColors = true;
			final index = (x + ( y * offsety ) + ( z * offsetz )).toInt();

			if ( array[ index + 1 ] == 0 || x == size.x - 1 ) add( px, x, z, - y, r, g, b );
			if ((index - 1 > 0 && array[ index - 1 ] == 0) || x == 0 ) add( nx, x, z, - y, r, g, b );
			if ( array[ index + offsety ] == 0 || y == size.y - 1 ) add( ny, x, z, - y, r, g, b );
			if ((index - offsety > 0 && array[ index - offsety ] == 0) || y == 0 ) add( py, x, z, - y, r, g, b );
			if ( array[ index + offsetz ] == 0 || z == size.z - 1 ) add( pz, x, z, - y, r, g, b );
			if((index - offsetz > 0 && array[ index - offsetz ] == 0) || z == 0) add( nz, x, z, - y, r, g, b );
		}

		final geometry = BufferGeometry();
		geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( vertices, 3 ) );
		geometry.computeVertexNormals();

		final material = MeshStandardMaterial();

		if ( hasColors ) {

			geometry.setAttributeFromString( 'color', Float32BufferAttribute.fromList( colors, 3 ) );
			material.vertexColors = true;

		}

		return VOXMesh.create( geometry, material );
	}

}

class VOXData3DTexture extends Data3DTexture {
  VOXData3DTexture.create([NativeArray? data, int width = 1, int height = 1, int depth = 1]):super( data, width,height,depth){
		format = RedFormat;
		minFilter = NearestFilter;
		magFilter = LinearFilter;
		unpackAlignment = 1;
		needsUpdate = true;
  }

	factory VOXData3DTexture(Chunk chunk) {

		final data = chunk.data;
		final size = chunk.size;

		final offsety = size.x;
		final offsetz = size.x * size.y;

		final array = Uint8Array( (size.x * size.y * size.z).toInt() );

		for (int j = 0; j < data!.length; j += 4 ) {
			final x = data[ j + 0 ];
			final y = data[ j + 1 ];
			final z = data[ j + 2 ];
			final index = x + ( y * offsety ) + ( z * offsetz );

			array[ index.toInt() ] = 255;
		}

    return VOXData3DTexture.create(array,size.x.toInt(),size.y.toInt(),size.z.toInt());
	}
}

class Chunk{
  late Vector3 size;
  List<int>? data;
  List<int>? palette;

  Chunk({
    this.palette,
    Vector3? size,
    this.data
  }){
    this.size = size ?? Vector3.zero();
  }
}