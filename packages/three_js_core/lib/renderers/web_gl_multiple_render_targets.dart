part of three_renderers;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {
  WebGLMultipleRenderTargets(
    int width,
    int height,
    int count, [
    WebGLRenderTargetOptions? options,
  ]) : super(width, height, options) {
    isWebGLMultipleRenderTargets = true;
    final texture = this.texture;
    this.texture = [];
    for (int i = 0; i < count; i++) {
      this.texture.add(texture.clone());
    }
  }

  @override
  WebGLMultipleRenderTargets setSize(int width, int height, [int depth = 1]) {
    if (this.width != width || this.height != height || this.depth != depth) {
      this.width = width;
      this.height = height;
      this.depth = depth;

      for (int i = 0, il = texture.length; i < il; i++) {
        texture[i].image.width = width;
        texture[i].image.height = height;
        texture[i].image.depth = depth;
      }

      dispose();
    }

    viewport.setValues(0, 0, width.toDouble(), height.toDouble());
    scissor.setValues(0, 0, width.toDouble(), height.toDouble());

    return this;
  }

  @override
  WebGLMultipleRenderTargets copy(WebGLRenderTarget source) {
    dispose();

    width = source.width;
    height = source.height;
    depth = source.depth;

    viewport.setValues(0, 0, width.toDouble(), height.toDouble());
    scissor.setValues(0, 0, width.toDouble(), height.toDouble());

    depthBuffer = source.depthBuffer;
    stencilBuffer = source.stencilBuffer;
    if (source.depthTexture != null) {
      depthTexture = source.depthTexture!.clone();
    }

    texture.length = 0;

    for (int i = 0, il = source.texture.length; i < il; i++) {
      texture[i] = source.texture[i].clone();
    }

    return this;
  }
}
