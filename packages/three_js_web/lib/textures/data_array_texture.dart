import './texture.dart';
import 'dart:js_interop';

@JS('DataArrayTexture')
class DataArrayTexture extends Texture {
  bool isDataTexture2DArray = true;
  external DataArrayTexture([data, int width = 1, int height = 1, int depth = 1]);
}
