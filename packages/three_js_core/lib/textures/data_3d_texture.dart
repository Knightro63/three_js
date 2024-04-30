import 'package:flutter_gl/native-array/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

class Data3DTexture extends Texture {
  bool isDataTexture3D = true;

  Data3DTexture([NativeArray? data, int width = 1, int height = 1, int depth = 1]):super() {
    image = ImageElement(data: data, width: width, height: height, depth: depth);

    magFilter = LinearFilter;
    minFilter = LinearFilter;

    wrapR = ClampToEdgeWrapping;

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;
  }

  // We're going to add .setXXX() methods for setting properties later.
  // Users can still set in DataTexture3D directly.
  //
  //	const texture = new THREE.DataTexture3D( data, width, height, depth );
  // 	texture.anisotropy = 16;
  //
  // See #14839

}
