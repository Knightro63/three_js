import './texture.dart';
import 'dart:js_interop';

@JS('Data3DTexture')
class Data3DTexture extends Texture {
  bool isDataTexture3D = true;

  external Data3DTexture([dynamic data, int width = 1, int height = 1, int depth = 1]);
}
