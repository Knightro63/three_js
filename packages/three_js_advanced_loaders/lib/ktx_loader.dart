import "dart:typed_data";
import "package:three_js_advanced_loaders/textures/compressed_texture_loader.dart";
import "package:three_js_core/three_js_core.dart";
import 'dart:math' as math;

/**
 * for description see https://www.khronos.org/opengles/sdk/tools/KTX/
 * for file layout see https://www.khronos.org/opengles/sdk/tools/KTX/file_format_spec/
 *
 * ported from https://github.com/BabylonJS/Babylon.js/blob/master/src/Misc/khronosTextureContainer.ts
 */


class KTXLoader extends CompressedTextureLoader {

	KTXLoader([super.manager]);

  @override
	Map<String,dynamic> parse(ByteBuffer buffer, bool loadMipmaps ) {
		final ktx = KhronosTextureContainer( buffer, 1 );

		return {
			'mipmaps': ktx.mipmaps( loadMipmaps ),
			'width': ktx.pixelWidth,
			'height': ktx.pixelHeight,
			'format': ktx.glInternalFormat,
			'isCubemap': ktx.numberOfFaces == 6,
			'mipmapCount': ktx.numberOfMipmapLevels
		};
	}
}


const HEADER_LEN = 12 + ( 13 * 4 ); // identifier + header elements (not including key value meta-data pairs)
// load types
const COMPRESSED_2D = 0; // uses a gl.compressedTexImage2D()
//const COMPRESSED_3D = 1; // uses a gl.compressedTexImage3D()
//const TEX_2D = 2; // uses a gl.texImage2D()
//const TEX_3D = 3; // uses a gl.texImage3D()

class KhronosTextureContainer {
  ByteBuffer arrayBuffer;
  int glType = 0; // must be 0 for compressed textures
  int glTypeSize = 1; // must be 1 for compressed textures
  int glFormat = 0; // must be 0 for compressed textures
  int glInternalFormat = 0; // the value of arg passed to gl.compressedTexImage2D(,,x,,,,)
  int glBaseInternalFormat = 0; // specify GL_RGB, GL_RGBA, GL_ALPHA, etc (un-compressed only)
  int pixelWidth = 0; // level 0 value of arg passed to gl.compressedTexImage2D(,,,x,,,)
  int pixelHeight = 0; // level 0 value of arg passed to gl.compressedTexImage2D(,,,,x,,)
  int pixelDepth = 0; // level 0 value of arg passed to gl.compressedTexImage3D(,,,,,x,,)
  int numberOfArrayElements = 0; // used for texture arrays
  int numberOfFaces = 1; // used for cubemap textures, should either be 1 or 6
  int numberOfMipmapLevels = 0; // number of levels; disregard possibility of 0 for compressed textures
  int bytesOfKeyValueData = 0; // the amount of space after the header for meta-data
  int loadType = 0;

	/**
	 * @param {ArrayBuffer} arrayBuffer- contents of the KTX container file
	 * @param {number} facesExpected- should be either 1 or 6, based whether a cube texture or or
	 * @param {boolean} threeDExpected- provision for indicating that data should be a 3D texture, not implemented
	 * @param {boolean} textureArrayExpected- provision for indicating that data should be a texture array, not implemented
	 */
	KhronosTextureContainer(this.arrayBuffer, int facesExpected /*, threeDExpected, textureArrayExpected */ ) {

		// Test that it is a ktx formatted file, based on the first 12 bytes, character representation is:
		// '´', 'K', 'T', 'X', ' ', '1', '1', 'ª', '\r', '\n', '\x1A', '\n'
		// 0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
		final identifier = arrayBuffer.asUint8List().sublist(0,12);

		if ( identifier[0] != 0xAB ||
			identifier[ 1 ] != 0x4B ||
			identifier[ 2 ] != 0x54 ||
			identifier[ 3 ] != 0x58 ||
			identifier[ 4 ] != 0x20 ||
			identifier[ 5 ] != 0x31 ||
			identifier[ 6 ] != 0x31 ||
			identifier[ 7 ] != 0xBB ||
			identifier[ 8 ] != 0x0D ||
			identifier[ 9 ] != 0x0A ||
			identifier[ 10 ] != 0x1A ||
			identifier[ 11 ] != 0x0A ) {

			console.error( 'texture missing KTX identifier' );
			return;

		}

		// load the reset of the header in native 32 bit uint
		const dataSize = 4;
		final headerDataView = arrayBuffer.asByteData();//DataView(arrayBuffer, 12, 13 * dataSize );
		final endianness = headerDataView.getUint32( 0, Endian.little );
		final littleEndian = endianness == 0x04030201? Endian.little :Endian.big;

		glType = headerDataView.getUint32( 1 * dataSize, littleEndian ); // must be 0 for compressed textures
		glTypeSize = headerDataView.getUint32( 2 * dataSize, littleEndian ); // must be 1 for compressed textures
		glFormat = headerDataView.getUint32( 3 * dataSize, littleEndian ); // must be 0 for compressed textures
		glInternalFormat = headerDataView.getUint32( 4 * dataSize, littleEndian ); // the value of arg passed to gl.compressedTexImage2D(,,x,,,,)
		glBaseInternalFormat = headerDataView.getUint32( 5 * dataSize, littleEndian ); // specify GL_RGB, GL_RGBA, GL_ALPHA, etc (un-compressed only)
		pixelWidth = headerDataView.getUint32( 6 * dataSize, littleEndian ); // level 0 value of arg passed to gl.compressedTexImage2D(,,,x,,,)
		pixelHeight = headerDataView.getUint32( 7 * dataSize, littleEndian ); // level 0 value of arg passed to gl.compressedTexImage2D(,,,,x,,)
		pixelDepth = headerDataView.getUint32( 8 * dataSize, littleEndian ); // level 0 value of arg passed to gl.compressedTexImage3D(,,,,,x,,)
		numberOfArrayElements = headerDataView.getUint32( 9 * dataSize, littleEndian ); // used for texture arrays
		numberOfFaces = headerDataView.getUint32( 10 * dataSize, littleEndian ); // used for cubemap textures, should either be 1 or 6
		numberOfMipmapLevels = headerDataView.getUint32( 11 * dataSize, littleEndian ); // number of levels; disregard possibility of 0 for compressed textures
		bytesOfKeyValueData = headerDataView.getUint32( 12 * dataSize, littleEndian ); // the amount of space after the header for meta-data

		// Make sure we have a compressed type.  Not only reduces work, but probably better to let dev know they are not compressing.
		if (glType != 0) {
			console.warning( 'only compressed formats currently supported' );
			return;
		} else {
			// value of zero is an indication to generate mipmaps @ runtime.  Not usually allowed for compressed, so disregard.
			numberOfMipmapLevels = math.max( 1, numberOfMipmapLevels );
		}

		if (pixelHeight == 0 || pixelDepth != 0 ) {
			console.warning( 'only 2D textures currently supported' );
			return;
		}

		if (numberOfArrayElements != 0 ) {
			console.warning( 'texture arrays not currently supported' );
			return;
		}

		if (numberOfFaces != facesExpected ) {
			console.warning( 'number of faces expected $facesExpected, but found $numberOfFaces' );
			return;
		}

		// we now have a completely validated file, so could use existence of loadType as success
		// would need to make this more elaborate & adjust checks above to support more than one load type
		loadType = COMPRESSED_2D;
	}

  int getUint32(Uint8List dv, int offset , bool littleEndian) {
    final value = dv
        .buffer
        .asByteData()
        .getUint32(offset, littleEndian ? Endian.little : Endian.big);
    return value;
  }

	List mipmaps(bool loadMipmaps ) {
		const mipmaps = [];

		// initialize width & height for level 1
		int dataOffset = HEADER_LEN + bytesOfKeyValueData;
		int width = pixelWidth;
		int height = pixelHeight;
		final mipmapCount = loadMipmaps ? numberOfMipmapLevels : 1;

		for ( int level = 0; level < mipmapCount; level ++ ) {
			final imageSize = arrayBuffer.asInt32List(dataOffset, 1)[0];// Int32Array(arrayBuffer,  )[ 0 ]; // size per face, since not supporting array cubemaps
			dataOffset += 4; // size of the image + 4 for the imageSize field

			for ( int face = 0; face < numberOfFaces; face ++ ) {
				final byteArray = arrayBuffer.asUint8List().sublist(dataOffset, imageSize);//Uint8Array(arrayBuffer, dataOffset, imageSize );

				mipmaps.add( { 'data': byteArray, 'width': width, 'height': height } );
				dataOffset += imageSize;
				dataOffset += 3 - ( ( imageSize + 3 ) % 4 ); // add padding for odd sized image
			}

			width = math.max( 1.0, width * 0.5 ).toInt();
			height = math.max( 1.0, height * 0.5 ).toInt();
		}

		return mipmaps;
	}
}
