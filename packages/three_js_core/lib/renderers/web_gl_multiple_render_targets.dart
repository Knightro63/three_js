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
    this.texture = GroupTexture();
    for (int i = 0; i < count; i++) {
      (this.texture as GroupTexture).children.add(texture.clone());
    }
  }

  @override
  WebGLMultipleRenderTargets setSize(int width, int height, [int depth = 1]) {
    if (this.width != width || this.height != height || this.depth != depth) {
      this.width = width;
      this.height = height;
      this.depth = depth;
      if(texture is GroupTexture){
        final children = (texture as GroupTexture).children;
        for (int i = 0, il = children.length; i < il; i++) {
          children[i].image.width = width;
          children[i].image.height = height;
          children[i].image.depth = depth;
        }
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
    if(texture is GroupTexture){
      final children = (texture as GroupTexture).children;
      children.length = 0;

      final sc = (source.texture as GroupTexture).children;
      for (int i = 0, il = sc.length; i < il; i++) {
        children[i] = sc[i].clone();
      }
    }

    return this;
  }
}
