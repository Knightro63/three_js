import 'package:three_js_core/three_js_core.dart';

abstract class CubeRenderTarget extends RenderTarget {
  CubeRenderTarget([int size = 1, RenderTargetOptions? options]) : super(size, size, options);
  CubeRenderTarget fromEquirectangularTexture(Renderer renderer, Texture texture);
  void clear(Renderer renderer, [bool color = true, bool depth = true, bool stencil = true]);
}