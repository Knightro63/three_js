import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class Storage3DTexture extends Texture {
  bool is3DTexture = true;
  bool isArrayTexture = false;

	Storage3DTexture([double width = 1, double height = 1, int depth = 1 ]) {
		image = ImageElement(
      width: width,
      height: height,
      depth: depth,
    );
		magFilter = LinearFilter;
		minFilter = LinearFilter;
		wrapR = ClampToEdgeWrapping;
	}
}