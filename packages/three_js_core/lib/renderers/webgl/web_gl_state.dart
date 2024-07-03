part of three_webgl;

class WebGLState {
  bool isWebGL2 = true;
  RenderingContext gl;
  WebGLExtensions extensions;
  WebGLCapabilities capabilities;

  late ColorBuffer colorBuffer;
  late DepthBuffer depthBuffer;
  late StencilBuffer stencilBuffer;

  late int maxTextures;

  final emptyTextures = <int, dynamic>{};
  late Map<int, int> equationToGL;
  late Map<int, int> factorToGL;

  Map<String, dynamic> get buffers => {"color": colorBuffer, "depth": depthBuffer, "stencil": stencilBuffer};
  Map<int, bool> enabledCapabilities = <int, bool>{};

  dynamic xrFramebuffer;
  Map currentBoundFramebuffers = {};
  WeakMap currentDrawbuffers = WeakMap();
  List defaultDrawbuffers = [];

  dynamic currentProgram;

  bool currentBlendingEnabled = false;

  int? currentBlending;
  int? currentBlendEquation;
  int? currentBlendSrc;
  int? currentBlendDst;
  int? currentBlendEquationAlpha;
  int? currentBlendSrcAlpha;
  int? currentBlendDstAlpha;
  bool? currentPremultipledAlpha;

  bool? currentFlipSided = false;
  int? currentCullFace;

  double? currentLineWidth;

  double? currentPolygonOffsetFactor;
  double? currentPolygonOffsetUnits;

  bool lineWidthAvailable = true;

  int? currentTextureSlot;
  Map<int, BoundTexture> currentBoundTextures = <int, BoundTexture>{};

  late Vector4 currentScissor;
  late Vector4 currentViewport;

  dynamic scissorParam;
  dynamic viewportParam;

  WebGLState(this.gl, this.extensions, this.capabilities) {
    isWebGL2 = capabilities.isWebGL2;

    colorBuffer = ColorBuffer(gl);
    depthBuffer = DepthBuffer(gl);
    stencilBuffer = StencilBuffer(gl);

    colorBuffer.enable = enable;
    colorBuffer.disable = disable;

    depthBuffer.enable = enable;
    depthBuffer.disable = disable;

    stencilBuffer.enable = enable;
    stencilBuffer.disable = disable;

    maxTextures = gl.getParameter(WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
    emptyTextures[WebGL.TEXTURE_2D] = createTexture(WebGL.TEXTURE_2D, WebGL.TEXTURE_2D, 1);
    emptyTextures[WebGL.TEXTURE_CUBE_MAP] = createTexture(WebGL.TEXTURE_CUBE_MAP, WebGL.TEXTURE_CUBE_MAP_POSITIVE_X, 6);

    // init

    colorBuffer.setClear(0, 0, 0, 1, false);
    depthBuffer.setClear(1);
    stencilBuffer.setClear(0);

    enable(WebGL.DEPTH_TEST);
    depthBuffer.setFunc(LessEqualDepth);

    setFlipSided(false);
    setCullFace(CullFaceBack);
    enable(WebGL.CULL_FACE);

    setBlending(NoBlending, null, null, null, null, null, null, false);

    equationToGL = {
      AddEquation: WebGL.FUNC_ADD,
      SubtractEquation: WebGL.FUNC_SUBTRACT,
      ReverseSubtractEquation: WebGL.FUNC_REVERSE_SUBTRACT
    };

    equationToGL[MinEquation] = WebGL.MIN;
    equationToGL[MaxEquation] = WebGL.MAX;

    factorToGL = {
      ZeroFactor: WebGL.ZERO,
      OneFactor: WebGL.ONE,
      SrcColorFactor: WebGL.SRC_COLOR,
      SrcAlphaFactor: WebGL.SRC_ALPHA,
      SrcAlphaSaturateFactor: WebGL.SRC_ALPHA_SATURATE,
      DstColorFactor: WebGL.DST_COLOR,
      DstAlphaFactor: WebGL.DST_ALPHA,
      OneMinusSrcColorFactor: WebGL.ONE_MINUS_SRC_COLOR,
      OneMinusSrcAlphaFactor: WebGL.ONE_MINUS_SRC_ALPHA,
      OneMinusDstColorFactor: WebGL.ONE_MINUS_DST_COLOR,
      OneMinusDstAlphaFactor: WebGL.ONE_MINUS_DST_ALPHA
    };

    scissorParam = gl.getParameter(WebGL.SCISSOR_BOX);
    viewportParam = gl.getParameter(WebGL.VIEWPORT);

    // currentScissor = Vector4.identity().copyFromArray( scissorParam );
    // currentViewport = Vector4.identity().copyFromArray( viewportParam );

    currentScissor = Vector4.identity();
    currentViewport = Vector4.identity();
  }

  WebGLTexture createTexture(int type, int target, int count) {
    final data = Uint8Array(4);
    // 4 is required to match default unpack alignment of 4.
    //
    final texture = gl.createTexture();

    gl.bindTexture(type, texture);
    gl.texParameteri(type, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
    gl.texParameteri(type, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);

    for (int i = 0; i < count; i++) {
      gl.texImage2D(target + i, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, data);
    }

    data.dispose();

    return texture;
  }

  void enable(id) {
    if (enabledCapabilities[id] != true) {
      gl.enable(id);
      enabledCapabilities[id] = true;
    }
  }

  void disable(id) {
    if (enabledCapabilities[id] != false) {
      gl.disable(id);
      enabledCapabilities[id] = false;
    }
  }

  void bindXRFramebuffer(Framebuffer? framebuffer) {
    if (framebuffer != xrFramebuffer) {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);

      xrFramebuffer = framebuffer;
    }
  }

  bool bindFramebuffer(target, Framebuffer? framebuffer) {
    if (framebuffer == null && xrFramebuffer != null) {
      framebuffer = xrFramebuffer;
    } // use active XR framebuffer if available

    if (currentBoundFramebuffers[target] != framebuffer) {
      gl.bindFramebuffer(target, framebuffer);

      currentBoundFramebuffers[target] = framebuffer;

      if (isWebGL2) {
        // gl.DRAW_FRAMEBUFFER is equivalent to gl.FRAMEBUFFER

        if (target == WebGL.DRAW_FRAMEBUFFER) {
          currentBoundFramebuffers[WebGL.FRAMEBUFFER] = framebuffer;
        }

        if (target == WebGL.FRAMEBUFFER) {
          currentBoundFramebuffers[WebGL.DRAW_FRAMEBUFFER] = framebuffer;
        }
      }

      return true;
    }

    return false;
  }

  void drawBuffers(renderTarget, Framebuffer? framebuffer) {
    dynamic drawBuffers = defaultDrawbuffers;

    bool needsUpdate = false;

    if (renderTarget != null) {
      drawBuffers = currentDrawbuffers.get(framebuffer);

      if (drawBuffers == null) {
        drawBuffers = [];
        currentDrawbuffers.set(framebuffer, drawBuffers);
      }

      if (renderTarget is WebGLMultipleRenderTargets) {
        final textures = (renderTarget.texture as GroupTexture).children;

        if (drawBuffers.length != textures.length || drawBuffers[0] != WebGL.COLOR_ATTACHMENT0) {
          for (int i = 0, il = textures.length; i < il; i++) {
            drawBuffers[i] = WebGL.COLOR_ATTACHMENT0 + i;
          }

          drawBuffers.length = textures.length;

          needsUpdate = true;
        }
      } 
      else {
        if (drawBuffers.length == 0 || drawBuffers[0] != WebGL.COLOR_ATTACHMENT0) {
          if (drawBuffers.length == 0) {
            drawBuffers.add(WebGL.COLOR_ATTACHMENT0);
          } 
          else {
            drawBuffers[0] = WebGL.COLOR_ATTACHMENT0;
          }

          drawBuffers.length = 1;

          needsUpdate = true;
        }
      }
    } else {
      if (drawBuffers.length == 0 || drawBuffers[0] != WebGL.BACK) {
        if (drawBuffers.length == 0) {
          drawBuffers.add(WebGL.BACK);
        } else {
          drawBuffers[0] = WebGL.BACK;
        }

        drawBuffers.length = 1;

        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      if (capabilities.isWebGL2) {
        Uint32Array buf = Uint32Array.fromList(List<int>.from(drawBuffers));
        gl.drawBuffers(buf);
        buf.dispose();
      } 
      else {
        extensions.get('WEBGL_draw_buffers').drawBuffersWEBGL(List<int>.from(drawBuffers));
      }
    }
  }

  bool useProgram(Program? program) {
    if (currentProgram != program) {
      gl.useProgram(program);
      currentProgram = program;
      return true;
    }

    return false;
  }

  void setBlending(int blending,
      [int? blendEquation,
      int? blendSrc,
      int? blendDst,
      int? blendEquationAlpha,
      int? blendSrcAlpha,
      int? blendDstAlpha,
      bool? premultipliedAlpha]) {
    if (blending == NoBlending) {
      if (currentBlendingEnabled) {
        disable(WebGL.BLEND);
        currentBlendingEnabled = false;
      }

      return;
    }

    if (!currentBlendingEnabled) {
      enable(WebGL.BLEND);
      currentBlendingEnabled = true;
    }

    if (blending != CustomBlending) {
      if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
        if (currentBlendEquation != AddEquation || currentBlendEquationAlpha != AddEquation) {
          gl.blendEquation(WebGL.FUNC_ADD);

          currentBlendEquation = AddEquation;
          currentBlendEquationAlpha = AddEquation;
        }

        if (premultipliedAlpha != null && premultipliedAlpha) {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(WebGL.ONE, WebGL.ONE_MINUS_SRC_ALPHA, WebGL.ONE, WebGL.ONE_MINUS_SRC_ALPHA);
              break;

            case AdditiveBlending:
              gl.blendFunc(WebGL.ONE, WebGL.ONE);
              break;

            case SubtractiveBlending:
              gl.blendFuncSeparate(WebGL.ZERO, WebGL.ONE_MINUS_SRC_COLOR, WebGL.ZERO, WebGL.ONE);
              break;

            case MultiplyBlending:
              gl.blendFuncSeparate(WebGL.ZERO, WebGL.SRC_COLOR, WebGL.ZERO, WebGL.SRC_ALPHA);
              break;

            default:
              console.error('WebGLState: Invalid blending: $blending');
              break;
          }
        } 
        else {
          switch (blending) {
            case NormalBlending:
              gl.blendFuncSeparate(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA, WebGL.ONE, WebGL.ONE_MINUS_SRC_ALPHA);
              break;

            case AdditiveBlending:
              gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE);
              break;

            case SubtractiveBlending:
              gl.blendFuncSeparate(WebGL.ZERO, WebGL.ONE_MINUS_SRC_COLOR, WebGL.ZERO, WebGL.ONE);
              break;

            case MultiplyBlending:
              gl.blendFunc(WebGL.ZERO, WebGL.SRC_COLOR);
              break;

            default:
              console.error('WebGLState: Invalid blending: $blending');
              break;
          }
        }

        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;

        currentBlending = blending;
        currentPremultipledAlpha = premultipliedAlpha;
      }

      return;
    }

    blendEquationAlpha = blendEquationAlpha ?? blendEquation;
    blendSrcAlpha = blendSrcAlpha ?? blendSrc;
    blendDstAlpha = blendDstAlpha ?? blendDst;

    if (blendEquation != currentBlendEquation || blendEquationAlpha != currentBlendEquationAlpha) {
      gl.blendEquationSeparate(equationToGL[blendEquation]!, equationToGL[blendEquationAlpha]!);

      currentBlendEquation = blendEquation;
      currentBlendEquationAlpha = blendEquationAlpha;
    }

    if (blendSrc != currentBlendSrc ||
        blendDst != currentBlendDst ||
        blendSrcAlpha != currentBlendSrcAlpha ||
        blendDstAlpha != currentBlendDstAlpha) {
      gl.blendFuncSeparate(factorToGL[blendSrc]!, factorToGL[blendDst]!, factorToGL[blendSrcAlpha]!, factorToGL[blendDstAlpha]!);

      currentBlendSrc = blendSrc;
      currentBlendDst = blendDst;
      currentBlendSrcAlpha = blendSrcAlpha;
      currentBlendDstAlpha = blendDstAlpha;
    }

    currentBlending = blending;
    currentPremultipledAlpha = null;
  }

  void setMaterial(Material material, bool frontFaceCW) {
    material.side == DoubleSide ? disable(WebGL.CULL_FACE) : enable(WebGL.CULL_FACE);

    bool flipSided = (material.side == BackSide);
    if (frontFaceCW) flipSided = !flipSided;

    setFlipSided(flipSided);

    (material.blending == NormalBlending && material.transparent == false)
        ? setBlending(NoBlending, null, null, null, null, null, null, false)
        : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst,
            material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.premultipliedAlpha);

    depthBuffer.setFunc(material.depthFunc);
    depthBuffer.setTest(material.depthTest);
    depthBuffer.setMask(material.depthWrite);
    colorBuffer.setMask(material.colorWrite);

    final stencilWrite = material.stencilWrite;
    stencilBuffer.setTest(stencilWrite);
    if (stencilWrite) {
      stencilBuffer.setMask(material.stencilWriteMask);
      stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
      stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
    }

    setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

    material.alphaToCoverage? enable(WebGL.SAMPLE_ALPHA_TO_COVERAGE) : disable(WebGL.SAMPLE_ALPHA_TO_COVERAGE);
  }

  //

  void setFlipSided(bool flipSided) {
    if (currentFlipSided != flipSided) {
      if (flipSided) {
        gl.frontFace(WebGL.CW);
      } 
      else {
        gl.frontFace(WebGL.CCW);
      }

      currentFlipSided = flipSided;
    }
  }

  void setCullFace(int cullFace) {
    if (cullFace != CullFaceNone) {
      enable(WebGL.CULL_FACE);

      if (cullFace != currentCullFace) {
        if (cullFace == CullFaceBack) {
          gl.cullFace(WebGL.BACK);
        } else if (cullFace == CullFaceFront) {
          gl.cullFace(WebGL.FRONT);
        } else {
          gl.cullFace(WebGL.FRONT_AND_BACK);
        }
      }
    } else {
      disable(WebGL.CULL_FACE);
    }

    currentCullFace = cullFace;
  }

  void setLineWidth(width) {
    if (width != currentLineWidth) {
      if (lineWidthAvailable) gl.lineWidth(width);

      currentLineWidth = width;
    }
  }

  void setPolygonOffset(bool polygonOffset, [double? factor, double? units]) {
    if (polygonOffset) {
      enable(WebGL.POLYGON_OFFSET_FILL);

      if (currentPolygonOffsetFactor != factor || currentPolygonOffsetUnits != units) {
        gl.polygonOffset(factor!, units!);

        currentPolygonOffsetFactor = factor;
        currentPolygonOffsetUnits = units;
      }
    } else {
      disable(WebGL.POLYGON_OFFSET_FILL);
    }
  }

  void setScissorTest(bool scissorTest) {
    if (scissorTest) {
      enable(WebGL.SCISSOR_TEST);
    } else {
      disable(WebGL.SCISSOR_TEST);
    }
  }

  // texture

  void activeTexture(int? webglSlot) {
    webglSlot ??= WebGL.TEXTURE0 + maxTextures - 1;

    if (currentTextureSlot != webglSlot) {
      gl.activeTexture(webglSlot);

      currentTextureSlot = webglSlot;
    }
  }

  void bindTexture(webglType, webglTexture) {
    if (currentTextureSlot == null) {
      activeTexture(null);
    }

    BoundTexture? boundTexture = currentBoundTextures[currentTextureSlot];

    if (boundTexture == null) {
      boundTexture = BoundTexture();
      currentBoundTextures[currentTextureSlot!] = boundTexture;
    }

    //if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      gl.bindTexture(webglType, webglTexture ?? emptyTextures[webglType]);

      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    //}
  }

  void unbindTexture([WebGLTexture? texture]) {
    final boundTexture = currentBoundTextures[currentTextureSlot];

    if (boundTexture != null && boundTexture.type != null) {
      gl.bindTexture(boundTexture.type!, texture);
      boundTexture.type = null;
      boundTexture.texture = null;
    }
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, NativeArray? pixels) {
    gl.compressedTexImage2D(target, level, internalformat, width, height, border, pixels);
  }

  void texSubImage2D(int target, int level, int x, int y, num width, num height, int glFormat, int glType, NativeArray data) {
    gl.texSubImage2D(target, level, x, y, width.toInt(), height.toInt(), glFormat, glType, data);
  }

  void texSubImage2DIf(int target, int level, int x, int y, int glFormat, int glType, ImageElement image) {
    if (kIsWeb && image.data is! NativeArray) {
      texSubImage2DNoSize(WebGL.TEXTURE_2D, level, x, y, glFormat, glType, image.data);
    } 
    else {
      texSubImage2D(WebGL.TEXTURE_2D, level, x, y, image.width, image.height, glFormat, glType, image.data);
    }
  }

  void texSubImage2DNoSize(int target, int level, int x, int y, int glFormat, int glType, data) {
    if (kIsWeb) {
      gl.texSubImage2D_NOSIZE(target, level, x, y, glFormat, glType, data);
    } 
    else {
      gl.texSubImage2D(target, level, 0, 0, x, y, glFormat, glType, data);
    }
  }

  void texSubImage3D(int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int format, int type, NativeArray? pixels) {
    gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
  }

  void compressedTexSubImage2D(
    int target,
    int level,
    int xoffset,
    int yoffset,
    int width,
    int height,
    int format,
    NativeArray? pixels,
  ) {
    gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, pixels);
  }

  void texStorage2D(int type, int levels, int glInternalFormat, int width, int height) {
    gl.texStorage2D(type, levels, glInternalFormat, width, height);
  }

  void texStorage3D(target, levels, internalformat, width, height, depth) {
    gl.texStorage3D(target, levels, internalformat, width.toInt(), height.toInt(), depth);
  }

  void texImage2DIf(int target, int level, int internalformat, int format, int type, image) {
    if (kIsWeb) {
      texImage2DNoSize(target, level, internalformat, format, type, image.data);
    } 
    else {
      texImage2D(target, level, internalformat, image.width, image.height, 0, format, type, image.data);
    }
  }

  void texImage2D(int target, int level, int internalformat, int width, int height, border, int format, int type, data) {
    gl.texImage2D(target, level, internalformat, width, height, border, format, type, data);
  }

  void texImage2DNoSize(int target, int level, int internalformat, int format, int type, data) {
    gl.texImage2D_NOSIZE(target, level, internalformat, format, type, data);
  }

  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format,int type, offset) {
    gl.texImage3D(target, level, internalformat, width, height, depth, border, format, type, offset);
  }

  void scissor(Vector4 scissor) {
    if (!currentScissor.equals(scissor)) {
      gl.scissor(scissor.x.toInt(), scissor.y.toInt(), scissor.z.toInt(), scissor.w.toInt());
      currentScissor.setFrom(scissor);
    }
  }

  void viewport(Vector4 viewport) {
    if (!currentViewport.equals(viewport)) {
      gl.viewport(viewport.x.toInt(), viewport.y.toInt(), viewport.z.toInt(), viewport.w.toInt());
      currentViewport.setFrom(viewport);
    }
  }

  void reset() {
    gl.disable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.POLYGON_OFFSET_FILL);
    gl.disable(WebGL.SCISSOR_TEST);
    gl.disable(WebGL.STENCIL_TEST);
    gl.disable(WebGL.SAMPLE_ALPHA_TO_COVERAGE);

    gl.blendEquation(WebGL.FUNC_ADD);
    gl.blendFunc(WebGL.ONE, WebGL.ZERO);
    gl.blendFuncSeparate(WebGL.ONE, WebGL.ZERO, WebGL.ONE, WebGL.ZERO);

    gl.colorMask(true, true, true, true);
    gl.clearColor(0, 0, 0, 0);

    gl.depthMask(true);
    gl.depthFunc(WebGL.LESS);
    gl.clearDepth(1);

    gl.stencilMask(0xffffffff);
    gl.stencilFunc(WebGL.ALWAYS, 0, 0xffffffff);
    gl.stencilOp(WebGL.KEEP, WebGL.KEEP, WebGL.KEEP);
    gl.clearStencil(0);

    gl.cullFace(WebGL.BACK);
    gl.frontFace(WebGL.CCW);
    gl.polygonOffset(0, 0);
    gl.activeTexture(WebGL.TEXTURE0);

    if (isWebGL2 == true) {
      gl.bindFramebuffer(WebGL.DRAW_FRAMEBUFFER, null); // Equivalent to gl.FRAMEBUFFER
      gl.bindFramebuffer(WebGL.READ_FRAMEBUFFER, null);
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
    } else {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
    }

    gl.useProgram(null);
    gl.lineWidth(1);
    gl.scissor(0, 0, 0, 0);
    gl.viewport(0, 0, 0, 0);
    // gl.scissor(0, 0, gl.width, gl.height);
    // gl.viewport(0, 0, gl.width, gl.height);

    // reset internals

    enabledCapabilities = {};

    currentTextureSlot = null;
    currentBoundTextures = {};

    xrFramebuffer = null;
    currentBoundFramebuffers = {};
    currentDrawbuffers = WeakMap();
    defaultDrawbuffers = [];

    currentProgram = null;

    currentBlendingEnabled = false;
    currentBlending = null;
    currentBlendEquation = null;
    currentBlendSrc = null;
    currentBlendDst = null;
    currentBlendEquationAlpha = null;
    currentBlendSrcAlpha = null;
    currentBlendDstAlpha = null;
    currentPremultipledAlpha = false;

    currentFlipSided = null;
    currentCullFace = null;

    currentLineWidth = null;

    currentPolygonOffsetFactor = null;
    currentPolygonOffsetUnits = null;

		//currentScissor.setValues( 0, 0, gl.width.toDouble(), gl.height.toDouble() );
		//currentViewport.setValues( 0, 0, gl.width.toDouble(), gl.height.toDouble() );

    colorBuffer.reset();
    depthBuffer.reset();
    stencilBuffer.reset();
  }
}

class ColorBuffer {
  RenderingContext gl;

  bool locked = false;

  late Function enable;
  late Function disable;

  Vector4 color = Vector4.identity();
  bool? currentColorMask;
  Vector4 currentColorClear = Vector4(0, 0, 0, 0);

  ColorBuffer(this.gl);

  setMask(bool colorMask) {
    if (currentColorMask != colorMask && !locked) {
      gl.colorMask(colorMask, colorMask, colorMask, colorMask);
      currentColorMask = colorMask;
    }
  }

  setLocked(lock) {
    locked = lock;
  }

  setClear(double r, double g, double b, double a, bool premultipliedAlpha) {
    if (premultipliedAlpha == true) {
      r *= a;
      g *= a;
      b *= a;
    }

    color.setValues(r, g, b, a);

    if (currentColorClear.equals(color) == false) {
      gl.clearColor(r, g, b, a);
      currentColorClear.setFrom(color);
    }
  }

  void reset() {
    locked = false;

    currentColorMask = null;
    currentColorClear.setValues(-1, 0, 0, 0); // set to invalid state
  }
}

class DepthBuffer {
  RenderingContext gl;

  bool locked = false;

  late Function enable;
  late Function disable;

  bool? currentDepthMask;

  int? currentDepthFunc;
  double? currentDepthClear;

  DepthBuffer(this.gl);

  void setTest(depthTest) {
    if (depthTest) {
      enable(WebGL.DEPTH_TEST);
    } else {
      disable(WebGL.DEPTH_TEST);
    }
  }

  void setMask(bool depthMask) {
    if (currentDepthMask != depthMask && !locked) {
      gl.depthMask(depthMask);
      currentDepthMask = depthMask;
    }
  }

  void setFunc(int? depthFunc) {
    if (currentDepthFunc != depthFunc) {
      if (depthFunc != null) {
        switch (depthFunc) {
          case NeverDepth:
            gl.depthFunc(WebGL.NEVER);
            break;

          case AlwaysDepth:
            gl.depthFunc(WebGL.ALWAYS);
            break;

          case LessDepth:
            gl.depthFunc(WebGL.LESS);
            break;

          case LessEqualDepth:
            gl.depthFunc(WebGL.LEQUAL);
            break;

          case EqualDepth:
            gl.depthFunc(WebGL.EQUAL);
            break;

          case GreaterEqualDepth:
            gl.depthFunc(WebGL.GEQUAL);
            break;

          case GreaterDepth:
            gl.depthFunc(WebGL.GREATER);
            break;

          case NotEqualDepth:
            gl.depthFunc(WebGL.NOTEQUAL);
            break;

          default:
            gl.depthFunc(WebGL.LEQUAL);
        }
      } else {
        gl.depthFunc(WebGL.LEQUAL);
      }

      currentDepthFunc = depthFunc;
    }
  }

  void setLocked(lock) {
    locked = lock;
  }

  void setClear(double depth) {
    if (currentDepthClear != depth) {
      gl.clearDepth(depth);
      currentDepthClear = depth;
    }
  }

  void reset() {
    locked = false;

    currentDepthMask = null;
    currentDepthFunc = null;
    currentDepthClear = null;
  }
}

class StencilBuffer {
  RenderingContext gl;

  bool locked = false;

  late Function enable;
  late Function disable;

  int? currentStencilMask;
  int? currentStencilFunc;
  int? currentStencilRef;
  int? currentStencilFuncMask;
  int? currentStencilFail;
  int? currentStencilZFail;
  int? currentStencilZPass;
  int? currentStencilClear;

  StencilBuffer(this.gl);

  void setTest(bool stencilTest) {
    if (!locked) {
      if (stencilTest) {
        enable(WebGL.STENCIL_TEST);
      } else {
        disable(WebGL.STENCIL_TEST);
      }
    }
  }

  void setMask(int stencilMask) {
    if (currentStencilMask != stencilMask && !locked) {
      gl.stencilMask(stencilMask);
      currentStencilMask = stencilMask;
    }
  }

  void setFunc(int stencilFunc, int stencilRef, int stencilMask) {
    if (currentStencilFunc != stencilFunc || currentStencilRef != stencilRef || currentStencilFuncMask != stencilMask) {
      gl.stencilFunc(stencilFunc, stencilRef, stencilMask);

      currentStencilFunc = stencilFunc;
      currentStencilRef = stencilRef;
      currentStencilFuncMask = stencilMask;
    }
  }

  void setOp(int stencilFail, int stencilZFail, int stencilZPass) {
    if (currentStencilFail != stencilFail ||
        currentStencilZFail != stencilZFail ||
        currentStencilZPass != stencilZPass) {
      gl.stencilOp(stencilFail, stencilZFail, stencilZPass);

      currentStencilFail = stencilFail;
      currentStencilZFail = stencilZFail;
      currentStencilZPass = stencilZPass;
    }
  }

  void setLocked(bool lock) {
    locked = lock;
  }

  void setClear(int stencil) {
    if (currentStencilClear != stencil) {
      gl.clearStencil(stencil);
      currentStencilClear = stencil;
    }
  }

  void reset() {
    locked = false;

    currentStencilMask = null;
    currentStencilFunc = null;
    currentStencilRef = null;
    currentStencilFuncMask = null;
    currentStencilFail = null;
    currentStencilZFail = null;
    currentStencilZPass = null;
    currentStencilClear = null;
  }
}

class BoundTexture {
  int? type;
  dynamic texture;

  BoundTexture([this.type, this.texture]);
}
