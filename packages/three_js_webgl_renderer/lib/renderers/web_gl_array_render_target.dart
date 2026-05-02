part of three_renderers;

class WebGLArrayRenderTarget extends RenderTarget {
  WebGLArrayRenderTarget([int width = 1, int height = 1, int depth = 1, RenderTargetOptions? options]) : super(width, height, options) {
    this.depth = depth;
    texture = DataArrayTexture(null, width, height, depth);
    texture.isRenderTargetTexture = true;
  }
}