part of three_renderers;

class WebGLMultisampleRenderTarget extends WebGLRenderTarget {
  @override
  int samples = 4;

  WebGLMultisampleRenderTarget(super.width, super.height, [super.options]){
    isWebGLMultisampleRenderTarget = true;
    ignoreDepthForMultisampleCopy = options.ignoreDepth;
    useRenderToTexture = options.useRenderToTexture;
    useRenderbuffer = useRenderToTexture == false;
  }

  @override
  WebGLMultisampleRenderTarget clone() {
    return WebGLMultisampleRenderTarget(width, height, options).copy(this);
  }

  @override
  WebGLMultisampleRenderTarget copy(source) {
    super.copy(source);

    samples = source.samples;
    useMultisampleRenderToTexture = source.useMultisampleRenderToTexture;
    useMultisampleRenderbuffer = source.useMultisampleRenderbuffer;

    return this;
  }
}
