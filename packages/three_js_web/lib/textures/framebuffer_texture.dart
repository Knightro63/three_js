import 'package:three_js_core/textures/index.dart';
import 'dart:js_interop';

@JS('OpenGLTexture')
class FramebufferTexture extends Texture {
  external FramebufferTexture(int width, int height, [int format]);
}
