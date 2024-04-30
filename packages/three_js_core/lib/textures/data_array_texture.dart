import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

class DataArrayTexture extends Texture {
  bool isDataTexture2DArray = true;

  DataArrayTexture([data, int width = 1, int height = 1, int depth = 1]):super() {
    image =
        ImageElement(data: data, width: width, height: height, depth: depth);

    magFilter = NearestFilter;
    minFilter = NearestFilter;

    wrapR = ClampToEdgeWrapping;

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;
  }
}
