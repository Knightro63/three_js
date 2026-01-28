part of three_renderers;

class AngleArrayRenderTarget extends RenderTarget {
  AngleArrayRenderTarget([int width = 1, int height = 1, int depth = 1, RenderTargetOptions? options]) : super(width, height, options) {
    this.depth = depth;
    texture = DataArrayTexture(null, width, height, depth);
    texture.isRenderTargetTexture = true;
  }
}