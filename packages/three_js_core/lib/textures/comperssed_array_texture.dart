import 'compressed_texture.dart';
import 'package:three_js_math/three_js_math.dart';

class CompressedArrayTexture extends CompressedTexture {
	CompressedArrayTexture([
    mipmaps, 
    int width = 1, 
    int height = 1,
    int depth = 1,
    int? format, 
    int? type, 
  ]):super( mipmaps, width, height, format, type ){
		image.depth = depth;
		wrapR = ClampToEdgeWrapping;
	}
}