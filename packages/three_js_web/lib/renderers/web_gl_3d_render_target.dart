part of three_renderers;

class WebGL3DRenderTarget extends WebGLRenderTarget {
  WebGL3DRenderTarget([int width = 1, int height = 1, int depth = 1, WebGLRenderTargetOptions? options]) : super(width, height, options) {
    this.depth = depth;
    texture = Data3DTexture(null, width, height, depth);
    texture.isRenderTargetTexture = true;
  }
}
