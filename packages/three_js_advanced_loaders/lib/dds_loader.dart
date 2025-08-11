import 'package:three_js_advanced_loaders/textures/compressed_texture_loader.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class DDSInfo{
  List mipmaps = []; 
  int width = 0; 
  int height = 0; 
  dynamic format = null; 
  int mipmapCount = 1;
  bool isCubemap = false;
}

// class MipMap{
//   NativeArray data;
//   int width;
//   int height;

//   MipMap({
//     required this.data,
//     this.width = 0,
//     this.height = 0
//   });
// }

class DDSLoader extends CompressedTextureLoader {
	
  DDSLoader({
    LoadingManager? manager, 
    bool flipY = false,
  }):super( manager ){
    this.flipY = flipY;
  }

  // @override
  // void dispose(){
  //   super.dispose();
  //   _loader.dispose();
  // }

  // void _init(){
  //   _loader.setResponseType('arraybuffer');
  //   _loader.setRequestHeader(requestHeader);
  //   _loader.setPath(path);
  //   _loader.setWithCredentials(withCredentials);
  // }

  // @override
  // Future<CompressedTexture?> fromNetwork(Uri uri) async{
  //   _init();
  //   ThreeFile? tf = await _loader.fromNetwork(uri);
  //   return tf == null?null:_parse(tf.data.buffer,loadMipmaps);
  // }
  
  // @override
  // Future<CompressedTexture?> fromFile(File file) async{
  //   _init();
  //   ThreeFile tf = await _loader.fromFile(file);
  //   return _parse(tf.data.buffer,loadMipmaps);
  // }
  
  // @override
  // Future<CompressedTexture?> fromPath(String filePath) async{
  //   _init();
  //   ThreeFile? tf = await _loader.fromPath(filePath);
  //   return _parse(tf!.data.buffer,loadMipmaps);
  // }
  
  // @override
  // Future<CompressedTexture?> fromBlob(Blob blob) async{
  //   _init();
  //   ThreeFile tf = await _loader.fromBlob(blob);
  //   return _parse(tf.data.buffer,loadMipmaps);
  // }
  
  // @override
  // Future<CompressedTexture?> fromAsset(String asset, {String? package}) async{
  //   _init();
  //   ThreeFile? tf = await _loader.fromAsset(asset, package: package);
  //   return tf == null?null:_parse(tf.data.buffer,loadMipmaps);
  // }
  
  // @override
  // Future<CompressedTexture?> fromBytes(Uint8List bytes) async{
  //   _init();
  //   ThreeFile tf = await _loader.fromBytes(bytes);
  //   return _parse(tf.data.buffer,loadMipmaps);
  // }

	/**
	 * Parses the given S3TC texture data.
	 *
	 * @param {ArrayBuffer} buffer - The raw texture data.
	 * @param {boolean} loadMipmaps - Whether to load mipmaps or not.
	 * @return {CompressedTextureLoader~TexData} An object representing the parsed texture data.
	 */
	 DDSInfo parse(ByteBuffer buffer, bool loadMipmaps ) {
    print('parse dds');
		final DDSInfo dds = DDSInfo();

		// Adapted from @toji's DDS utils
		// https://github.com/toji/webgl-texture-utils/blob/master/texture-util/dds.js

		// All values and structures referenced from:
		// http://msdn.microsoft.com/en-us/library/bb943991.aspx/

		final DDS_MAGIC = 0x20534444;

		// final DDSD_CAPS = 0x1;
		// final DDSD_HEIGHT = 0x2;
		// final DDSD_WIDTH = 0x4;
		// final DDSD_PITCH = 0x8;
		// final DDSD_PIXELFORMAT = 0x1000;
		final DDSD_MIPMAPCOUNT = 0x20000;
		// final DDSD_LINEARSIZE = 0x80000;
		// final DDSD_DEPTH = 0x800000;

		// final DDSCAPS_COMPLEX = 0x8;
		// final DDSCAPS_MIPMAP = 0x400000;
		// final DDSCAPS_TEXTURE = 0x1000;

		final DDSCAPS2_CUBEMAP = 0x200;
		final DDSCAPS2_CUBEMAP_POSITIVEX = 0x400;
		final DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800;
		final DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000;
		final DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000;
		final DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000;
		final DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000;
		// final DDSCAPS2_VOLUME = 0x200000;

		// final DDPF_ALPHAPIXELS = 0x1;
		// final DDPF_ALPHA = 0x2;
		// final DDPF_FOURCC = 0x4;
		// final DDPF_RGB = 0x40;
		// final DDPF_YUV = 0x200;
		// final DDPF_LUMINANCE = 0x20000;

		final DXGI_FORMAT_BC6H_UF16 = 95;
		final DXGI_FORMAT_BC6H_SF16 = 96;

		int fourCCToInt32(String value ) {
			return value.codeUnitAt( 0 ) +
				( value.codeUnitAt( 1 ) << 8 ) +
				( value.codeUnitAt( 2 ) << 16 ) +
				( value.codeUnitAt( 3 ) << 24 );
		}

		String int32ToFourCC(int value ) {
			return String.fromCharCodes([
				value & 0xff,
				( value >> 8 ) & 0xff,
				( value >> 16 ) & 0xff,
				( value >> 24 ) & 0xff
			]);
		}

		Uint8Array loadARGBMip(ByteBuffer buffer, int dataOffset, int width, int height ) {
			final dataLength = width * height * 4;
			final srcBuffer = new Uint8Array.fromList( buffer.asUint8List(dataOffset, dataLength));
			final byteArray = new Uint8Array( dataLength );
			int dst = 0;
			int src = 0;

			for ( int y = 0; y < height; y ++ ) {
				for ( int x = 0; x < width; x ++ ) {
					final b = srcBuffer[ src ]; src ++;
					final g = srcBuffer[ src ]; src ++;
					final r = srcBuffer[ src ]; src ++;
					final a = srcBuffer[ src ]; src ++;
					byteArray[ dst ] = r; dst ++;	//r
					byteArray[ dst ] = g; dst ++;	//g
					byteArray[ dst ] = b; dst ++;	//b
					byteArray[ dst ] = a; dst ++;	//a
				}
			}

      srcBuffer.dispose();
			return byteArray;
		}

		Uint8Array loadRGBMip(ByteBuffer buffer, int dataOffset, int width, int height ) {
			final dataLength = width * height * 3;
			final srcBuffer = new Uint8Array.fromList(buffer.asUint8List(dataOffset, dataLength));
			final byteArray = new Uint8Array( width * height * 4 );
			int dst = 0;
			int src = 0;

			for ( int y = 0; y < height; y ++ ) {
				for ( int x = 0; x < width; x ++ ) {
					final b = srcBuffer[ src ]; src ++;
					final g = srcBuffer[ src ]; src ++;
					final r = srcBuffer[ src ]; src ++;
					byteArray[ dst ] = r; dst ++;	//r
					byteArray[ dst ] = g; dst ++;	//g
					byteArray[ dst ] = b; dst ++;	//b
					byteArray[ dst ] = 255; dst ++; //a
				}
			}

			return byteArray;
		}

		final FOURCC_DXT1 = fourCCToInt32( 'DXT1' );
		final FOURCC_DXT3 = fourCCToInt32( 'DXT3' );
		final FOURCC_DXT5 = fourCCToInt32( 'DXT5' );
		final FOURCC_ETC1 = fourCCToInt32( 'ETC1' );
		final FOURCC_DX10 = fourCCToInt32( 'DX10' );

		final headerLengthInt = 31; // The header length in 32 bit ints
		final extendedHeaderLengthInt = 5; // The extended header length in 32 bit ints

		// Offsets into the header array

		final off_magic = 0;

		final off_size = 1;
		final off_flags = 2;
		final off_height = 3;
		final off_width = 4;

		final off_mipmapCount = 7;

		// final off_pfFlags = 20;
		final off_pfFourCC = 21;
		final off_RGBBitCount = 22;
		final off_RBitMask = 23;
		final off_GBitMask = 24;
		final off_BBitMask = 25;
		final off_ABitMask = 26;

		// final off_caps = 27;
		final off_caps2 = 28;
		// final off_caps3 = 29;
		// final off_caps4 = 30;

		// If fourCC = DX10, the extended header starts after 32
		final off_dxgiFormat = 0;

		// Parse header

		final header = new Int32Array.fromList(buffer.asInt32List(0, headerLengthInt));

		if ( header[ off_magic ] != DDS_MAGIC ) {
			console.error( 'THREE.DDSLoader.parse: Invalid magic number in DDS header.' );
			return dds;
		}

		int blockBytes;

		final fourCC = header[ off_pfFourCC ];

		bool isRGBAUncompressed = false;
		bool isRGBUncompressed = false;

		int dataOffset = header[ off_size ] + 4;

		  if( FOURCC_DXT1 == fourCC){
				blockBytes = 8;
				dds.format = RGB_S3TC_DXT1_Format;
      }
			else if( FOURCC_DXT3 == fourCC){
				blockBytes = 16;
				dds.format = RGBA_S3TC_DXT3_Format;
			}
			else if( FOURCC_DXT5 == fourCC){
				blockBytes = 16;
				dds.format = RGBA_S3TC_DXT5_Format;
			}
			else if( FOURCC_ETC1 == fourCC){
				blockBytes = 8;
				dds.format = RGB_ETC1_Format;
			}
			else if(FOURCC_DX10 == fourCC){
				dataOffset += extendedHeaderLengthInt * 4;
				final extendedHeader = new Int32Array.fromList( buffer.asInt32List(( headerLengthInt + 1 ) * 4, extendedHeaderLengthInt));
				final dxgiFormat = extendedHeader[ off_dxgiFormat ];

        if( DXGI_FORMAT_BC6H_SF16 == dxgiFormat){
          blockBytes = 16;
          dds.format = RGB_BPTC_SIGNED_Format;
        }
        else if(DXGI_FORMAT_BC6H_UF16 == dxgiFormat){
          blockBytes = 16;
          dds.format = RGB_BPTC_UNSIGNED_Format;
        }
        else {
          console.error( 'THREE.DDSLoader.parse: Unsupported DXGI_FORMAT code $dxgiFormat');
          return dds;
        }
			}
			else{
				if ( header[ off_RGBBitCount ] == 32
					&& header[ off_RBitMask ] & 0xff0000 != 0
					&& header[ off_GBitMask ] & 0xff00 != 0
					&& header[ off_BBitMask ] & 0xff != 0
					&& header[ off_ABitMask ] & 0xff000000 != 0) {

					isRGBAUncompressed = true;
					blockBytes = 64;
					dds.format = RGBAFormat;
				} else if ( header[ off_RGBBitCount ] == 24
					&& header[ off_RBitMask ] & 0xff0000 != 0
					&& header[ off_GBitMask ] & 0xff00 != 0
					&& header[ off_BBitMask ] & 0xff != 0) {

				    	isRGBUncompressed = true;
                    			blockBytes = 64;
                    			dds.format = RGBAFormat;

				} 
        else {
					console.error( 'THREE.DDSLoader.parse: Unsupported FourCC code ${int32ToFourCC( fourCC )}');
					return dds;
				}
      }

		dds.mipmapCount = 1;

		if ( header[ off_flags ] & DDSD_MIPMAPCOUNT != 0 && loadMipmaps != false ) {
			dds.mipmapCount = math.max( 1, header[ off_mipmapCount ] );
		}

		final caps2 = header[ off_caps2 ];
		dds.isCubemap = caps2 & DDSCAPS2_CUBEMAP != 0? true : false;
		if ( dds.isCubemap && (
			! ( caps2 & DDSCAPS2_CUBEMAP_POSITIVEX != 0) ||
			! ( caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX != 0) ||
			! ( caps2 & DDSCAPS2_CUBEMAP_POSITIVEY != 0) ||
			! ( caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY != 0) ||
			! ( caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ != 0) ||
			! ( caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ != 0)
		) ) {

			console.error( 'THREE.DDSLoader.parse: Incomplete cubemap faces' );
			return dds;

		}

		dds.width = header[ off_width ];
		dds.height = header[ off_height ];

		// Extract mipmaps buffers

		final faces = dds.isCubemap ? 6 : 1;

		for (int face = 0; face < faces; face ++ ) {
			int width = dds.width;
			int height = dds.height;

			for (int i = 0; i < dds.mipmapCount; i ++ ) {
				NativeArray byteArray;
        int dataLength;

				if ( isRGBAUncompressed ) {
					byteArray = loadARGBMip( buffer, dataOffset, width, height );
					dataLength = byteArray.length;
				} 
        else if ( isRGBUncompressed ) {
					byteArray = loadRGBMip( buffer, dataOffset, width, height );
					dataLength = width * height * 3;
				} 
        else {
					dataLength = (math.max( 4, width ) / 4 * math.max( 4, height ) / 4 * blockBytes).toInt();
					byteArray = new Uint8Array.fromList( buffer.asUint8List(dataOffset, dataLength));
				}

				final mipmap = { 'data': byteArray, 'width': width, 'height': height };
				dds.mipmaps.add( mipmap );

				dataOffset += dataLength;

				width = math.max( width >> 1, 1 );
				height = math.max( height >> 1, 1 );
			}
		}

		return dds;
	}
}
