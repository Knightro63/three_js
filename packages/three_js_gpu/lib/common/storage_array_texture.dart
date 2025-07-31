import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/three_js_math.dart";

class StorageArrayTexture extends Texture {
  bool isArrayTexture = true;
  bool isStorageTexture = true;

	StorageArrayTexture([double width = 1, double height = 1, int depth = 1 ]):super(){
		image = ImageElement(
      width: width,
      height: height,
      depth: depth,
    );

		magFilter = LinearFilter;
		minFilter = LinearFilter;
	}
}