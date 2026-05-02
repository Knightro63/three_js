part of three_renderers;

class Angle3DRenderTarget extends RenderTarget {
  Angle3DRenderTarget([int width = 1, int height = 1, int depth = 1, RenderTargetOptions? options]) : super(width, height, options) {
    this.depth = depth;
    texture = Data3DTexture(null, width, height, depth);
    texture.isRenderTargetTexture = true;
  }
}
