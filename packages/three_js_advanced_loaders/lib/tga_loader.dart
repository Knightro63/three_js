import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'package:three_js_advanced_loaders/textures/data_texture_loader.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class TGALoader extends DataTextureLoader {
  late final FileLoader _loader;

	TGALoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setPath(path);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<DataTexture?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset, package: package);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  @override
  Future<DataTexture?> unknown(dynamic url) async{
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
      RegExp dataUriRegex = RegExp(r"^data:(.*?)(;base64)?,(.*)$");
      if(dataUriRegex.hasMatch(url)){
        RegExpMatch? dataUriRegexResult = dataUriRegex.firstMatch(url);
        String? data = dataUriRegexResult!.group(3)!;

        return fromBytes(convert.base64.decode(data));
      }
      else if(url.contains('http://') || url.contains('https://')){  
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

  @override
  DataTexture? parse(Map<String,dynamic>? texData){
    if(texData?['buffer'] == null) return null;
    return _parse(texData!['buffer']);
  }

	DataTexture _parse(Uint8List buffer) {
    int offset = 0;

		const TGA_TYPE_NO_DATA = 0,
			TGA_TYPE_INDEXED = 1,
			TGA_TYPE_RGB = 2,
			TGA_TYPE_GREY = 3,
			TGA_TYPE_RLE_INDEXED = 9,
			TGA_TYPE_RLE_RGB = 10,
			TGA_TYPE_RLE_GREY = 11,

			TGA_ORIGIN_MASK = 0x30,
			TGA_ORIGIN_SHIFT = 0x04,
			TGA_ORIGIN_BL = 0x00,
			TGA_ORIGIN_BR = 0x01,
			TGA_ORIGIN_UL = 0x02,
			TGA_ORIGIN_UR = 0x03;

		bool useRle = false,
			usePal = false,
			useGrey = false;

		final content = Uint8List.fromList( buffer );
		final header = {
      'id_length': content[ offset ++ ],
      'colormap_type': content[ offset ++ ],
      'image_type': content[ offset ++ ],
      'colormap_index': content[ offset ++ ] | content[ offset ++ ] << 8,
      'colormap_length': content[ offset ++ ] | content[ offset ++ ] << 8,
      'colormap_size': content[ offset ++ ],
      'origin': [
        content[ offset ++ ] | content[ offset ++ ] << 8,
        content[ offset ++ ] | content[ offset ++ ] << 8
      ],
      'width': content[ offset ++ ] | content[ offset ++ ] << 8,
      'height': content[ offset ++ ] | content[ offset ++ ] << 8,
      'pixel_size': content[ offset ++ ],
      'flags': content[ offset ++ ]
    };

		// reference from vthibault, https://github.com/vthibault/roBrowser/blob/master/src/Loaders/Targa.js

		void tgaCheckHeader(Map<String,dynamic> header ) {
			switch ( header['image_type'] ) {
				case TGA_TYPE_INDEXED:
				case TGA_TYPE_RLE_INDEXED:
					if ( header['colormap_length'] > 256 || header['colormap_size'] != 24 || header['colormap_type'] != 1 ) {
						throw( 'THREE.TGALoader: Invalid type colormap data for indexed type.' );
					}
					break;
				case TGA_TYPE_RGB:
				case TGA_TYPE_GREY:
				case TGA_TYPE_RLE_RGB:
				case TGA_TYPE_RLE_GREY:
					if ( header['colormap_type'] == null) {
						throw ( 'THREE.TGALoader: Invalid type colormap data for colormap type.' );
					}
					break;
				case TGA_TYPE_NO_DATA:
					throw ( 'THREE.TGALoader: No data.' );
				default:
					throw ( 'THREE.TGALoader: Invalid type ${header['image_type']}') ;
			}

			// check image width and height

			if ( header['width'] <= 0 || header['height'] <= 0 ) {
				throw( 'THREE.TGALoader: Invalid image size.' );
			}

			// check image pixel size

			if ( header['pixel_size'] != 8 && header['pixel_size'] != 16 &&
				header['pixel_size'] != 24 && header['pixel_size'] != 32 ) {
				throw( 'THREE.TGALoader: Invalid pixel size ${header['pixel_size']}');
			}
		}

		// parse tga image buffer

		Map<String,dynamic> tgaParse(bool useRle,bool usePal,Map<String,dynamic> header, int offset, Uint8List data) {
			Uint8List pixelData;
			Uint8List? palettes;

			final int pixelSize = header['pixel_size'] >> 3;
			final int pixelTotal = header['width'] * header['height'] * pixelSize;

			 // read palettes

			if ( usePal ) {
				palettes = data.sublist( offset, offset += (header['colormap_length'] as int) * ( (header['colormap_size'] as int) >> 3 ) );
			}

			 // read RLE

			 if ( useRle ) {
				 pixelData = Uint8List( pixelTotal );

				int c, count, i;
				int shift = 0;
				final pixels = Uint8List( pixelSize );

				while ( shift < pixelTotal ) {
					c = data[ offset ++ ];
					count = ( c & 0x7f ) + 1;

					// RLE pixels

					if ( c & 0x80 > 0) {
						for ( i = 0; i < pixelSize; ++ i ) {
							pixels[ i ] = data[ offset ++ ];
						}

						for ( i = 0; i < count; ++ i ) {
							pixelData.set( pixels, shift + i * pixelSize );
						}

						shift += pixelSize * count;
					} 
          else {
						count *= pixelSize;

						for ( i = 0; i < count; ++ i ) {
							pixelData[ shift + i ] = data[ offset ++ ];
						}

						shift += count;
					}
				}
			 } 
       else {
				pixelData = data.sublist(offset, offset += ( usePal ? (header['width'] as int) * (header['height'] as int) : pixelTotal ));
			 }

			 return {
				'pixel_data': pixelData,
				'palettes': palettes
			 };

		}

		Uint8List tgaGetImageData8bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image, Uint8List palettes ) {
			final colormap = palettes;
			int color, i = 0;
			final width = header['width'] as int;

			//for ( y = yStart; y != yEnd; y += yStep ) {
      for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x == xEnd; x += xStep, i ++ ) {
					color = image[ i ];
					imageData[ ( x + width * y ) * 4 + 3 ] = 255;
					imageData[ ( x + width * y ) * 4 + 2 ] = colormap[ ( color * 3 ) + 0 ];
					imageData[ ( x + width * y ) * 4 + 1 ] = colormap[ ( color * 3 ) + 1 ];
					imageData[ ( x + width * y ) * 4 + 0 ] = colormap[ ( color * 3 ) + 2 ];
				}
			}

			return imageData;
		}

		Uint8List tgaGetImageData16bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image ) {
			int color, i = 0;
			final width = header['width'] as int;

			//for ( y = yStart; y != yEnd; y += yStep ) {
      for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x != xEnd; x += xStep, i += 2 ) {
					color = image[ i + 0 ] + ( image[ i + 1 ] << 8 );
					imageData[ ( x + width * y ) * 4 + 0 ] = ( color & 0x7C00 ) >> 7;
					imageData[ ( x + width * y ) * 4 + 1 ] = ( color & 0x03E0 ) >> 2;
					imageData[ ( x + width * y ) * 4 + 2 ] = ( color & 0x001F ) << 3;
					imageData[ ( x + width * y ) * 4 + 3 ] = ( color & 0x8000 )  == 0? 0 : 255;
				}
			}

			return imageData;
		}

		Uint8List tgaGetImageData24bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image ) {
			int i = 0;
			final width = header['width'] as int;
			//for (int y = yStart; y != yEnd; y += yStep ) {
			for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x != xEnd; x += xStep, i += 3 ) {
					imageData[ ( x + width * y ) * 4 + 3 ] = 255;
					imageData[ ( x + width * y ) * 4 + 2 ] = image[ i + 0 ];
					imageData[ ( x + width * y ) * 4 + 1 ] = image[ i + 1 ];
					imageData[ ( x + width * y ) * 4 + 0 ] = image[ i + 2 ];
				}
			}

			return imageData;
		}

		Uint8List tgaGetImageData32bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image ) {
			int i = 0;
			final width = header['width'] as int;

			// for ( y = yStart; y != yEnd; y += yStep ) {
      for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x != xEnd; x += xStep, i += 4 ) {
					imageData[ ( x + width * y ) * 4 + 2 ] = image[ i + 0 ];
					imageData[ ( x + width * y ) * 4 + 1 ] = image[ i + 1 ];
					imageData[ ( x + width * y ) * 4 + 0 ] = image[ i + 2 ];
					imageData[ ( x + width * y ) * 4 + 3 ] = image[ i + 3 ];
				}
			}

			return imageData;
		}

		Uint8List tgaGetImageDataGrey8bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image ) {
			int color, i = 0;
			final width = header['width'] as int;

			//for ( y = yStart; y != yEnd; y += yStep ) {
      for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x != xEnd; x += xStep, i ++ ) {
					color = image[ i ];
					imageData[ ( x + width * y ) * 4 + 0 ] = color;
					imageData[ ( x + width * y ) * 4 + 1 ] = color;
					imageData[ ( x + width * y ) * 4 + 2 ] = color;
					imageData[ ( x + width * y ) * 4 + 3 ] = 255;
				}
			}

			return imageData;
		}

		Uint8List tgaGetImageDataGrey16bits(Uint8List imageData, int yStart, int yStep, int yEnd, int xStart,int xStep, int xEnd, Uint8List image ) {
			int i = 0;
			final width = header['width'] as int;

			//for ( y = yStart; y != yEnd; y += yStep ) {
      for (int y = yEnd+1; y < yStart+1; y += yStep.abs() ) {
				for (int x = xStart; x != xEnd; x += xStep, i += 2 ) {
					imageData[ ( x + width * y ) * 4 + 0 ] = image[ i + 0 ];
					imageData[ ( x + width * y ) * 4 + 1 ] = image[ i + 0 ];
					imageData[ ( x + width * y ) * 4 + 2 ] = image[ i + 0 ];
					imageData[ ( x + width * y ) * 4 + 3 ] = image[ i + 1 ];
				}
			}

			return imageData;
		}

		Uint8List getTgaRGBA(Uint8List data, int width, int height, Uint8List image, Uint8List? palette ) {
			int xStart,
				yStart,
				xStep,
				yStep,
				xEnd,
				yEnd;

			switch (((header['flags'] as int) & TGA_ORIGIN_MASK) >> TGA_ORIGIN_SHIFT) {
				case TGA_ORIGIN_UL:
					xStart = 0;
					xStep = 1;
					xEnd = width;
					yStart = 0;
					yStep = 1;
					yEnd = height;
					break;
				case TGA_ORIGIN_BL:
					xStart = 0;
					xStep = 1;
					xEnd = width;
					yStart = height - 1;
					yStep = - 1;
					yEnd = - 1;
					break;
				case TGA_ORIGIN_UR:
					xStart = width - 1;
					xStep = - 1;
					xEnd = - 1;
					yStart = 0;
					yStep = 1;
					yEnd = height;
					break;
				case TGA_ORIGIN_BR:
					xStart = width - 1;
					xStep = - 1;
					xEnd = - 1;
					yStart = height - 1;
					yStep = - 1;
					yEnd = - 1;
					break;
        default:
					xStart = 0;
					xStep = 1;
					xEnd = width;
					yStart = 0;
					yStep = 1;
					yEnd = height;
					break;
			}

			if ( useGrey ) {
				switch ( header['pixel_size'] ) {
					case 8:
						tgaGetImageDataGrey8bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image );
						break;
					case 16:
						tgaGetImageDataGrey16bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image );
						break;
					default:
						throw( 'THREE.TGALoader: Format not supported.' );
				}
			} 
      else {
				switch ( header['pixel_size'] ) {
					case 8:
						tgaGetImageData8bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image, palette! );
						break;
					case 16:
						tgaGetImageData16bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image );
						break;
					case 24:
						tgaGetImageData24bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image );
						break;
					case 32:
						tgaGetImageData32bits( data, yStart, yStep, yEnd, xStart, xStep, xEnd, image );
						break;
					default:
						throw( 'THREE.TGALoader: Format not supported.' );
				}
			}

			return data;
		}

		if ( buffer.length < 19 ) throw( 'THREE.TGALoader: Not enough data to contain header.' );

		tgaCheckHeader( header );

		if ( (header['id_length'] as int) + offset > buffer.length ) {
			throw( 'THREE.TGALoader: No data.' );
		}

		offset += (header['id_length'] as int);
		switch ( header['image_type'] ) {
			case TGA_TYPE_RLE_INDEXED:
				useRle = true;
				usePal = true;
				break;
			case TGA_TYPE_INDEXED:
				usePal = true;
				break;
			case TGA_TYPE_RLE_RGB:
				useRle = true;
				break;
			case TGA_TYPE_RGB:
				break;
			case TGA_TYPE_RLE_GREY:
				useRle = true;
				useGrey = true;
				break;
			case TGA_TYPE_GREY:
				useGrey = true;
				break;
		}

		final Uint8List imageData = Uint8List( (header['width'] as int) * (header['height'] as int) * 4 );
		final result = tgaParse( useRle, usePal, header, offset, content );
		getTgaRGBA( imageData, header['width'] as int, header['height'] as int, result['pixel_data'], result['palettes'] );

    final dt = DataTexture(
      Uint8Array.fromList(imageData),
      header['width'] as int,
      header['height'] as int,
    );

    dt.flipY = true;
    dt.generateMipmaps = true;
    dt.minFilter = LinearMipmapLinearFilter;
    dt.needsUpdate = true;

    return dt;
	}
}
