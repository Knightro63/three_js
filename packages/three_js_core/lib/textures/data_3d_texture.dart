import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

/// Creates a three-dimensional texture from raw data, with parameters to divide it into width, height, and depth.
class Data3DTexture extends Texture {
  bool isDataTexture3D = true;

  /// [data] -
  /// [ArrayBufferView](https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView) of the texture.
  /// 
  /// [width] -- width of the texture.
  /// 
  /// [height] -- height of the texture.
  /// 
  /// [depth] -- depth of the texture.
  /// 
  Data3DTexture([TypedData? data, int width = 1, int height = 1, int depth = 1]):super() {
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
