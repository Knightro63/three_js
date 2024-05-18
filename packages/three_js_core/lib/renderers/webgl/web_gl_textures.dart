part of three_webgl;

class WebGLTextures {
  dynamic gl;
  dynamic get _gl => gl;
  WebGLExtensions extensions;
  WebGLState state;
  WebGLProperties properties;
  WebGLCapabilities capabilities;
  WebGLUtils utils;
  WebGLInfo info;
  bool isWebGL2 = true;

  late int maxTextures;
  late int maxCubemapSize;
  late int maxTextureSize;
  late int maxSamples;

  bool supportsInvalidateFramenbuffer = false;

  final Map _videoTextures = {};

  final WeakMap _sources = WeakMap();
  // maps WebglTexture objects to instances of Source

  Map<int, int> wrappingToGL = {};
  Map<int, int> filterToGL = {};

  dynamic multisampledRenderToTextureExtension;

  WebGLTextures(this.gl, this.extensions, this.state, this.properties, this.capabilities, this.utils, this.info) {
    maxTextures = capabilities.maxTextures;
    maxCubemapSize = capabilities.maxCubemapSize;
    maxTextureSize = capabilities.maxTextureSize;
    maxSamples = capabilities.maxSamples;
    multisampledRenderToTextureExtension = extensions.has('WEBGL_multisampled_render_to_texture') != null
        ? extensions.get('WEBGL_multisampled_render_to_texture')
        : null;

    wrappingToGL[RepeatWrapping] = gl.REPEAT;
    wrappingToGL[ClampToEdgeWrapping] = gl.CLAMP_TO_EDGE;
    wrappingToGL[MirroredRepeatWrapping] = gl.MIRRORED_REPEAT;

    filterToGL[NearestFilter] = gl.NEAREST;
    filterToGL[NearestMipmapNearestFilter] = gl.NEAREST_MIPMAP_NEAREST;
    filterToGL[NearestMipmapLinearFilter] = gl.NEAREST_MIPMAP_LINEAR;
    filterToGL[LinearFilter] = gl.LINEAR;
    filterToGL[LinearMipmapNearestFilter] = gl.LINEAR_MIPMAP_NEAREST;
    filterToGL[LinearMipmapLinearFilter] = gl.LINEAR_MIPMAP_LINEAR;

    // TODO FIXME when on web && is OculusBrowser
    // supportsInvalidateFramenbuffer = kIsWeb && RegExp(r"OculusBrowser").hasMatch( navigator.userAgent );
  }

  resizeImage(image, needsPowerOfTwo, needsNewCanvas, maxSize) {
    // final scale = 1;

    // handle case if texture exceeds max size

    // if (image.width > maxSize || image.height > maxSize) {
    //   scale = maxSize / math.max<num>(image.width, image.height);
    // }

    // only perform resize if necessary

    // if ( scale < 1 || needsPowerOfTwo == true ) {

    // 	// only perform resize for certain image types

    // 	if ( ( typeof HTMLImageElement != 'null' && image instanceof HTMLImageElement ) ||
    // 		( typeof HTMLCanvasElement != 'null' && image instanceof HTMLCanvasElement ) ||
    // 		( typeof ImageBitmap != 'null' && image instanceof ImageBitmap ) ) {

    // 		final floor = needsPowerOfTwo ? MathUtils.floorPowerOfTwo : math.floor;

    // 		final width = floor( scale * image.width );
    // 		final height = floor( scale * image.height );

    // 		if ( _canvas == null ) _canvas = createCanvas( width, height );

    // 		// cube textures can't reuse the same canvas

    // 		final canvas = needsNewCanvas ? createCanvas( width, height ) : _canvas;

    // 		canvas.width = width;
    // 		canvas.height = height;

    // 		final context = canvas.getContext( '2d' );
    // 		context.drawImage( image, 0, 0, width, height );

    // 		print( 'three.WebGLRenderer: Texture has been resized from (' + image.width + 'x' + image.height + ') to (' + width + 'x' + height + ').' );

    // 		return canvas;

    // 	} else {

    // 		if ( 'data' in image ) {

    // 			print( 'three.WebGLRenderer: Image in DataTexture is too big (' + image.width + 'x' + image.height + ').' );

    // 		}

    // 		return image;

    // 	}

    // }

    return image;
  }

  bool isPowerOfTwo(image) {
    return MathUtils.isPowerOfTwo(image.width.toInt()) && MathUtils.isPowerOfTwo(image.height.toInt());
  }

  textureNeedsPowerOfTwo(Texture texture) {
    if (isWebGL2) return false;
  }

  textureNeedsGenerateMipmaps(Texture texture, supportsMips) {
    return texture.generateMipmaps &&
        supportsMips &&
        texture.minFilter != NearestFilter &&
        texture.minFilter != LinearFilter;
  }

  generateMipmap(target) {
    gl.generateMipmap(target);
  }

  getInternalFormat(internalFormatName, glFormat, glType, encoding, [bool isVideoTexture = false]) {
    if (isWebGL2 == false) return glFormat;

    if (internalFormatName != null) {
      // if ( gl[ internalFormatName ] != null ) return gl[ internalFormatName ];

      console.warning('WebGLRenderer: Attempt to use non-existing WebGL internal format $internalFormatName');
    }

    dynamic internalFormat = glFormat;

    if (glFormat == gl.RED) {
      if (glType == gl.FLOAT) internalFormat = gl.R32F;
      if (glType == gl.HALF_FLOAT) internalFormat = gl.R16F;
      if (glType == gl.UNSIGNED_BYTE) internalFormat = gl.R8;
    }

    if (glFormat == _gl.RG) {
      if (glType == _gl.FLOAT) internalFormat = _gl.RG32F;
      if (glType == _gl.HALF_FLOAT) internalFormat = _gl.RG16F;
      if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.RG8;
    }

    if (glFormat == _gl.RGB) {
      if (glType == _gl.FLOAT) internalFormat = _gl.RGB32F;
      if (glType == _gl.HALF_FLOAT) internalFormat = _gl.RGB16F;
      if (glType == _gl.UNSIGNED_BYTE) internalFormat = _gl.RGB8;
    }

    if (glFormat == gl.RGBA) {
      if (glType == gl.FLOAT) internalFormat = gl.RGBA32F;
      if (glType == gl.HALF_FLOAT) internalFormat = gl.RGBA16F;
      if (glType == gl.UNSIGNED_BYTE) {
        internalFormat = (encoding == sRGBEncoding && isVideoTexture == false) ? gl.SRGB8_ALPHA8 : gl.RGBA8;
      }
      if (glType == _gl.UNSIGNED_SHORT_4_4_4_4) internalFormat = _gl.RGBA4;
      if (glType == _gl.UNSIGNED_SHORT_5_5_5_1) internalFormat = _gl.RGB5_A1;
    }

    if (internalFormat == gl.R16F ||
        internalFormat == gl.R32F ||
        internalFormat == _gl.RG16F ||
        internalFormat == _gl.RG32F ||
        internalFormat == gl.RGBA16F ||
        internalFormat == gl.RGBA32F) {
      extensions.get('EXT_color_buffer_float');
    }

    return internalFormat;
  }

  int getMipLevels(Texture texture, image, supportsMips) {
    if (textureNeedsGenerateMipmaps(texture, supportsMips) == true ||
        (texture is FramebufferTexture && texture.minFilter != NearestFilter && texture.minFilter != LinearFilter)) {
      return MathUtils.log2(
        math.max(
          image.width,
          image.height
        )
      ).toInt() + 1;
    } else if (texture.mipmaps.isNotEmpty) {
      // user-defined mipmaps

      return texture.mipmaps.length;
    } else if (texture is CompressedTexture && texture.image is List) {
      // Dart: TODO texture.image is List ???
      return image.mipmaps.length;
    } else {
      // texture without mipmaps (only base level)

      return 1;
    }
  }

  // Fallback filters for non-power-of-2 textures

  filterFallback(int f) {
    if (f == NearestFilter || f == NearestMipmapNearestFilter || f == NearestMipmapLinearFilter) {
      return gl.NEAREST;
    }

    return gl.LINEAR;
  }

  //

  void onTextureDispose(Event event) {
    final texture = event.target;

    texture.removeEventListener('dispose', onTextureDispose);

    deallocateTexture(texture);

    if (texture.isVideoTexture) {
      _videoTextures.remove(texture);
    }

    if (texture.isOpenGLTexture) {
      _videoTextures.remove(texture);
    }
  }

  void onRenderTargetDispose(Event event) {
    final renderTarget = event.target;

    renderTarget.removeEventListener('dispose', onRenderTargetDispose);

    deallocateRenderTarget(renderTarget);

    info.memory["textures"] = info.memory["textures"]! - 1;
  }

  void deallocateTexture(Texture texture) {
    final textureProperties = properties.get(texture);

    if (textureProperties["__webglInit"] == null) return;

    // check if it's necessary to remove the WebGLTexture object

    final source = texture.source;
    final webglTextures = _sources.get(source);

    if (webglTextures != null) {
      Map webglTexture = webglTextures[textureProperties["__cacheKey"]];
      webglTexture["usedTimes"]--;

      // the WebGLTexture object is not used anymore, remove it

      if (webglTexture["usedTimes"] == 0) {
        deleteTexture(texture);
      }

      // remove the weak map entry if no WebGLTexture uses the source anymore

      if (webglTextures.keys.length == 0) {
        _sources.delete(source);
      }
    }

    properties.remove(texture);
  }

  void deleteTexture(Texture texture) {
    final textureProperties = properties.get(texture);
    _gl.deleteTexture(textureProperties["__webglTexture"]);

    final source = texture.source;
    Map webglTextures = _sources.get(source);
    webglTextures.remove(textureProperties["__cacheKey"]);

    info.memory["textures"] = info.memory["textures"]! - 1;
  }

  void deallocateRenderTarget(RenderTarget renderTarget) {
    final texture = renderTarget.texture;

    final renderTargetProperties = properties.get(renderTarget);
    final textureProperties = properties.get(texture);

    if (textureProperties["__webglTexture"] != null) {
      gl.deleteTexture(textureProperties["__webglTexture"]);
      info.memory["textures"] = info.memory["textures"]! - 1;
    }

    if (renderTarget.depthTexture != null) {
      renderTarget.depthTexture!.dispose();
    }

    if (renderTarget.isWebGLCubeRenderTarget) {
      for (int i = 0; i < 6; i++) {
        gl.deleteFramebuffer(renderTargetProperties["__webglFramebuffer"][i]);
        if (renderTargetProperties["__webglDepthbuffer"] != null) {
          gl.deleteRenderbuffer(renderTargetProperties["__webglDepthbuffer"][i]);
        }
      }
    } else {
      gl.deleteFramebuffer(renderTargetProperties["__webglFramebuffer"]);
      if (renderTargetProperties["__webglDepthbuffer"] != null) {
        gl.deleteRenderbuffer(renderTargetProperties["__webglDepthbuffer"]);
      }
      if (renderTargetProperties["__webglMultisampledFramebuffer"] != null) {
        gl.deleteFramebuffer(renderTargetProperties["__webglMultisampledFramebuffer"]);
      }
      if (renderTargetProperties["__webglColorRenderbuffer"] != null) {
        gl.deleteRenderbuffer(renderTargetProperties["__webglColorRenderbuffer"]);
      }
      if (renderTargetProperties["__webglDepthRenderbuffer"] != null) {
        gl.deleteRenderbuffer(renderTargetProperties["__webglDepthRenderbuffer"]);
      }
    }

    if (renderTarget.isWebGLMultipleRenderTargets) {
      for (int i = 0, il = texture.length; i < il; i++) {
        final attachmentProperties = properties.get(texture[i]);

        if (attachmentProperties["__webglTexture"] != null) {
          gl.deleteTexture(attachmentProperties["__webglTexture"]);

          info.memory["textures"] = info.memory["textures"]! - 1;
        }

        properties.remove(texture[i]);
      }
    }

    properties.remove(texture);
    properties.remove(renderTarget);
  }

  //

  int textureUnits = 0;

  void resetTextureUnits() => textureUnits = 0;

  int allocateTextureUnit() {
    int textureUnit = textureUnits;

    if (textureUnit >= maxTextures) {
      console.warning('WebGLTextures: Trying to use $textureUnit texture units while this GPU supports only $maxTextures');
    }

    textureUnits += 1;

    return textureUnit;
  }

  String getTextureCacheKey(Texture texture) {
    final array = [];

    array.add(texture.wrapS);
    array.add(texture.wrapT);
    array.add(texture.magFilter);
    array.add(texture.minFilter);
    array.add(texture.anisotropy);
    array.add(texture.internalFormat);
    array.add(texture.format);
    array.add(texture.type);
    array.add(texture.generateMipmaps);
    array.add(texture.premultiplyAlpha);
    array.add(texture.flipY);
    array.add(texture.unpackAlignment);
    array.add(texture.encoding);

    return array.join();
  }

  void setTexture2D(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture is VideoTexture) updateVideoTexture(texture);
    if (texture is OpenGLTexture) {
      uploadOpenGLTexture(textureProperties, texture, slot);
      return;
    }

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      final image = texture.image;
      if (texture is! OpenGLTexture && image == null) {
        console.warning('WebGLRenderer: Texture marked for update but image is null');
      } 
      else if (texture is! OpenGLTexture && image.complete == false) {
        console.warning('WebGLRenderer: Texture marked for update but image is incomplete');
      } 
      else {
        uploadTexture(textureProperties, texture, slot);
        return;
      }
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_2D, textureProperties["__webglTexture"]);
  }

  void setTexture2DArray(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadTexture(textureProperties, texture, slot);
      return;
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_2D_ARRAY, textureProperties["__webglTexture"]);
  }

  void setTexture3D(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadTexture(textureProperties, texture, slot);
      return;
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_3D, textureProperties["__webglTexture"]);
  }

  void setTextureCube(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadCubeTexture(textureProperties, texture, slot);
      return;
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_CUBE_MAP, textureProperties["__webglTexture"]);
  }

  void setTextureParameters(textureType, Texture texture, supportsMips) {
    if (supportsMips) {
      gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, wrappingToGL[texture.wrapS]!);
      gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, wrappingToGL[texture.wrapT]!);

      if (textureType == gl.TEXTURE_3D || textureType == gl.TEXTURE_2D_ARRAY) {
        gl.texParameteri(textureType, gl.TEXTURE_WRAP_R, wrappingToGL[texture.wrapR]!);
      }

      gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, filterToGL[texture.magFilter]!);
      gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, filterToGL[texture.minFilter]!);
    } else {
      gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

      if (textureType == gl.TEXTURE_3D || textureType == gl.TEXTURE_2D_ARRAY) {
        gl.texParameteri(textureType, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE);
      }

      if (texture.wrapS != ClampToEdgeWrapping || texture.wrapT != ClampToEdgeWrapping) {
        console.error('WebGLRenderer: Texture is not power of two. Texture.wrapS and Texture.wrapT should be set to ClampToEdgeWrapping.');
      }

      gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, filterFallback(texture.magFilter));
      gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, filterFallback(texture.minFilter));

      if (texture.minFilter != NearestFilter && texture.minFilter != LinearFilter) {
        console.error('WebGLRenderer: Texture is not power of two. Texture.minFilter should be set to NearestFilter or LinearFilter.');
      }
    }

    final extension = extensions.get('EXT_texture_filter_anisotropic');

    if (extension != null) {
      if (texture.type == FloatType && extensions.get('OES_texture_float_linear') == null) return;
      if (texture.type == HalfFloatType && (isWebGL2 || extensions.get('OES_texture_half_float_linear') == null)) {
        return;
      }

      if (texture.anisotropy > 1 || properties.get(texture)["__currentAnisotropy"] != null) {
        // print("extension: ${extension} ... extension.TEXTURE_MAX_ANISOTROPY_EXT: ${extension.TEXTURE_MAX_ANISOTROPY_EXT} ");

        if (kIsWeb) {
          gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT,
              math.min(texture.anisotropy, capabilities.getMaxAnisotropy()).toDouble());
        } 
        else {
          gl.texParameterf(textureType, gl.TEXTURE_MAX_ANISOTROPY_EXT,
              math.min(texture.anisotropy, capabilities.getMaxAnisotropy()).toDouble());
        }

        properties.get(texture)["__currentAnisotropy"] = texture.anisotropy;
      }
    }
  }

  bool initTexture(Map<String, dynamic> textureProperties, Texture texture) {
    bool forceUpload = false;

    if (textureProperties["__webglInit"] != true) {
      textureProperties["__webglInit"] = true;

      texture.addEventListener('dispose', onTextureDispose);

      // if (texture.isOpenGLTexture) {
      //   final _texture = texture as OpenGLTexture;
      //   textureProperties["__webglTexture"] = _texture.openGLTexture;
      // } else {
      //   textureProperties["__webglTexture"] = gl.createTexture();
      // }

      // info.memory["textures"] = info.memory["textures"]! + 1;
    }

    // create Source <-> WebGLTextures mapping if necessary

    final source = texture.source;
    Map? webglTextures = _sources.get(source);

    if (webglTextures == null) {
      webglTextures = {};
      _sources.set(source, webglTextures);
    }

    // check if there is already a WebGLTexture object for the given texture parameters

    final textureCacheKey = getTextureCacheKey(texture);

    if (textureCacheKey != textureProperties["__cacheKey"]) {
      // if not, create a new instance of WebGLTexture

      if (webglTextures[textureCacheKey] == null) {
        // create new entry

        webglTextures[textureCacheKey] = {"texture": _gl.createTexture(), "usedTimes": 0};

        info.memory["textures"] = info.memory["textures"]! + 1;

        // when a new instance of WebGLTexture was created, a texture upload is required
        // even if the image contents are identical

        forceUpload = true;
      }

      webglTextures[textureCacheKey]["usedTimes"]++;

      // every time the texture cache key changes, it's necessary to check if an instance of
      // WebGLTexture can be deleted in order to avoid a memory leak.

      final webglTexture = webglTextures[textureProperties["__cacheKey"]];

      if (webglTexture != null) {
        webglTextures[textureProperties["__cacheKey"]]["usedTimes"]--;

        if (webglTexture["usedTimes"] == 0) {
          deleteTexture(texture);
        }
      }

      // store references to cache key and WebGLTexture object

      textureProperties["__cacheKey"] = textureCacheKey;
      textureProperties["__webglTexture"] = webglTextures[textureCacheKey]["texture"];
    }

    return forceUpload;
  }

  // uploadTexture(textureProperties, Texture texture, int slot) {
  //   final textureType = gl.TEXTURE_2D;

  //   // print(" WebGLTextures.uploadTexture ");
  //   // print(texture.toJson(null));

  //   if (texture is DataArrayTexture) textureType = gl.TEXTURE_2D_ARRAY;
  //   if (texture is Data3DTexture) textureType = gl.TEXTURE_3D;

  //   initTexture(textureProperties, texture);

  //   state.activeTexture(gl.TEXTURE0 + slot);
  //   state.bindTexture(textureType, textureProperties["__webglTexture"]);

  //   gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);

  //   gl.pixelStorei(
  //       gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
  //   gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);

  //   if (kIsWeb) {
  //     gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);
  //   }

  //   final needsPowerOfTwo =
  //       textureNeedsPowerOfTwo(texture) && isPowerOfTwo(texture.image) == false;

  //   final image =
  //       resizeImage(texture.image, needsPowerOfTwo, false, maxTextureSize);
  //   image = verifyColorSpace(texture, image);

  //   final supportsMips = isPowerOfTwo(image) || isWebGL2;
  //   final glFormat = utils.convert(texture.format);
  //   final glType = utils.convert(texture.type);

  //   final glInternalFormat = getInternalFormat(texture.internalFormat, glFormat,
  //       glType, texture.encoding, texture.isVideoTexture);

  //   setTextureParameters(textureType, texture, supportsMips);

  //   final mipmap;
  //   final mipmaps = texture.mipmaps;

  //   final levels = getMipLevels(texture, image, supportsMips);
  //   final useTexStorage = (isWebGL2 && texture.isVideoTexture != true);
  //   final allocateMemory = (textureProperties["__version"] == null);

  //   if (texture.isDepthTexture) {
  //     // populate depth texture with dummy data

  //     glInternalFormat = gl.DEPTH_COMPONENT;

  //     if (isWebGL2) {
  //       if (texture.type == FloatType) {
  //         glInternalFormat = gl.DEPTH_COMPONENT32F;
  //       } else if (texture.type == UnsignedIntType) {
  //         glInternalFormat = gl.DEPTH_COMPONENT24;
  //       } else if (texture.type == UnsignedInt248Type) {
  //         glInternalFormat = gl.DEPTH24_STENCIL8;
  //       } else {
  //         glInternalFormat = gl
  //             .DEPTH_COMPONENT16; // WebGL2 requires sized internalformat for glTexImage2D

  //       }
  //     } else {
  //       if (texture.type == FloatType) {
  //         print('WebGLRenderer: Floating point depth texture requires WebGL2.');
  //       }
  //     }

  //     // validation checks for WebGL 1

  //     if (texture.format == DepthFormat &&
  //         glInternalFormat == gl.DEPTH_COMPONENT) {
  //       // The error INVALID_OPERATION is generated by texImage2D if format and internalformat are
  //       // DEPTH_COMPONENT and type is not UNSIGNED_SHORT or UNSIGNED_INT
  //       // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
  //       if (texture.type != UnsignedShortType &&
  //           texture.type != UnsignedIntType) {
  //         print(
  //             'three.WebGLRenderer: Use UnsignedShortType or UnsignedIntType for DepthFormat DepthTexture.');

  //         texture.type = UnsignedShortType;
  //         glType = utils.convert(texture.type);
  //       }
  //     }

  //     if (texture.format == DepthStencilFormat &&
  //         glInternalFormat == gl.DEPTH_COMPONENT) {
  //       // Depth stencil textures need the DEPTH_STENCIL internal format
  //       // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
  //       glInternalFormat = gl.DEPTH_STENCIL;

  //       // The error INVALID_OPERATION is generated by texImage2D if format and internalformat are
  //       // DEPTH_STENCIL and type is not UNSIGNED_INT_24_8_WEBGL.
  //       // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
  //       if (texture.type != UnsignedInt248Type) {
  //         print(
  //             'three.WebGLRenderer: Use UnsignedInt248Type for DepthStencilFormat DepthTexture.');

  //         texture.type = UnsignedInt248Type;
  //         glType = utils.convert(texture.type);
  //       }
  //     }

  //     // state.texImage2D(gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //     //     image.height, 0, glFormat, glType, null);

  //     if (useTexStorage && allocateMemory) {
  //       state.texStorage2D(
  //           gl.TEXTURE_2D, 1, glInternalFormat, image.width, image.height);
  //     } else {
  //       state.texImage2D(gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //           image.height, 0, glFormat, glType, null);
  //     }
  //   } else if (texture.isDataTexture) {
  //     // print("uploadTexture texture isDataTexture image.width: ${image.width}, image.height: ${image.height} supportsMips: ${supportsMips}  -mipmaps.length: ${mipmaps.length}---------------- ");
  //     // print(image.data.toDartList().length);
  //     // print(image.data.toDartList() );
  //     // use manually created mipmaps if available
  //     // if there are no manual mipmaps
  //     // set 0 level mipmap and then use GL to generate other mipmap levels

  //     if (mipmaps.length > 0 && supportsMips) {
  //       if (useTexStorage && allocateMemory) {
  //         state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat,
  //             mipmaps[0].width, mipmaps[0].height);
  //       }

  //       for (final i = 0, il = mipmaps.length; i < il; i++) {
  //         mipmap = mipmaps[i];
  //         // state.texImage2D(gl.TEXTURE_2D, i, glInternalFormat, mipmap.width,
  //         //     mipmap.height, 0, glFormat, glType, mipmap.data);

  //         if (useTexStorage) {
  //           state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width,
  //               mipmap.height, glFormat, glType, mipmap.data);
  //         } else {
  //           state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, mipmap.width,
  //               mipmap.height, 0, glFormat, glType, mipmap.data);
  //         }
  //       }

  //       texture.generateMipmaps = false;
  //     } else {
  //       // state.texImage2D(gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //       //     image.height, 0, glFormat, glType, image.data);

  //       if (useTexStorage) {
  //         if (allocateMemory) {
  //           state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat,
  //               image.width, image.height);
  //         }
  //         state.texSubImage2D(_gl.TEXTURE_2D, 0, 0, 0, image.width,
  //             image.height, glFormat, glType, image.data);
  //       } else {
  //         state.texImage2D(_gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //             image.height, 0, glFormat, glType, image.data);
  //       }
  //     }
  //   } else if (texture.isCompressedTexture) {
  //     if (useTexStorage && allocateMemory) {
  //       state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat,
  //           mipmaps[0].width, mipmaps[0].height);
  //     }

  //     for (final i = 0, il = mipmaps.length; i < il; i++) {
  //       mipmap = mipmaps[i];

  //       if (texture.format != RGBAFormat) {
  //         if (glFormat != null) {
  //           // state.compressedTexImage2D(gl.TEXTURE_2D, i, glInternalFormat,
  //           //     mipmap.width, mipmap.height, 0, null, mipmap.data);
  //           if (useTexStorage) {
  //             state.compressedTexSubImage2D(_gl.TEXTURE_2D, i, 0, 0,
  //                 mipmap.width, mipmap.height, glFormat, mipmap.data);
  //           } else {
  //             state.compressedTexImage2D(_gl.TEXTURE_2D, i, glInternalFormat,
  //                 mipmap.width, mipmap.height, 0, mipmap.data);
  //           }
  //         } else {
  //           print(
  //               'three.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()');
  //         }
  //       } else {
  //         // state.texImage2D(gl.TEXTURE_2D, i, glInternalFormat, mipmap.width,
  //         //     mipmap.height, 0, glFormat, glType, mipmap.data);

  //         if (useTexStorage) {
  //           state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width,
  //               mipmap.height, glFormat, glType, mipmap.data);
  //         } else {
  //           state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, mipmap.width,
  //               mipmap.height, 0, glFormat, glType, mipmap.data);
  //         }
  //       }
  //     }
  //   } else if (texture is DataArrayTexture) {
  //     // state.texImage3D(gl.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width,
  //     //     image.height, image.depth, 0, glFormat, glType, image.data);
  //     if (useTexStorage) {
  //       if (allocateMemory) {
  //         state.texStorage3D(_gl.TEXTURE_2D_ARRAY, levels, glInternalFormat,
  //             image.width, image.height, image.depth);
  //       }
  //       state.texSubImage3D(_gl.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width,
  //           image.height, image.depth, glFormat, glType, image.data);
  //     } else {
  //       state.texImage3D(_gl.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width,
  //           image.height, image.depth, 0, glFormat, glType, image.data);
  //     }
  //   } else if (texture is Data3DTexture) {
  //     // state.texImage3D(gl.TEXTURE_3D, 0, glInternalFormat, image.width,
  //     //     image.height, image.depth, 0, glFormat, glType, image.data);
  //     if (useTexStorage) {
  //       if (allocateMemory) {
  //         state.texStorage3D(_gl.TEXTURE_3D, levels, glInternalFormat,
  //             image.width, image.height, image.depth);
  //       }
  //       state.texSubImage3D(_gl.TEXTURE_3D, 0, 0, 0, 0, image.width,
  //           image.height, image.depth, glFormat, glType, image.data);
  //     } else {
  //       state.texImage3D(_gl.TEXTURE_3D, 0, glInternalFormat, image.width,
  //           image.height, image.depth, 0, glFormat, glType, image.data);
  //     }
  //   } else if (texture is FramebufferTexture) {
  //     if (useTexStorage && allocateMemory) {
  //       state.texStorage2D(
  //           gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);
  //     } else {
  //       state.texImage2D(gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //           image.height, 0, glFormat, glType, null);
  //     }
  //   } else {
  //     // regular Texture (image, video, canvas)

  //     // use manually created mipmaps if available
  //     // if there are no manual mipmaps
  //     // set 0 level mipmap and then use GL to generate other mipmap levels

  //     if (mipmaps.length > 0 && supportsMips) {
  //       if (useTexStorage && allocateMemory) {
  //         state.texStorage2D(gl.TEXTURE_2D, levels, glInternalFormat,
  //             mipmaps[0].width, mipmaps[0].height);
  //       }

  //       for (final i = 0, il = mipmaps.length; i < il; i++) {
  //         mipmap = mipmaps[i];

  //         if (useTexStorage) {
  //           state.texSubImage2D(gl.TEXTURE_2D, i, 0, 0, mipmap.width,
  //               mipmap.height, glFormat, glType, mipmap.data);
  //         } else {
  //           state.texImage2D(gl.TEXTURE_2D, i, glInternalFormat, image.width,
  //               image.height, 0, glFormat, glType, mipmap.data);
  //         }
  //       }

  //       texture.generateMipmaps = false;
  //     } else {
  //       if (useTexStorage) {
  //         if (allocateMemory) {
  //           state.texStorage2D(gl.TEXTURE_2D, levels, glInternalFormat,
  //               image.width, image.height);
  //         }

  //         if (kIsWeb) {
  //           state.texSubImage2D_IF(
  //               gl.TEXTURE_2D, 0, 0, 0, glFormat, glType, image.data);
  //         } else {
  //           state.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, image.width,
  //               image.height, glFormat, glType, image.data);
  //         }
  //       } else {
  //         // state.texImage2D( gl.TEXTURE_2D, 0, glInternalFormat, glFormat, glType, image );

  //         if (kIsWeb) {
  //           state.texImage2D_IF(gl.TEXTURE_2D, 0, glInternalFormat,
  //               glFormat, glType, image.data);
  //         } else {
  //           state.texImage2D(gl.TEXTURE_2D, 0, glInternalFormat, image.width,
  //               image.height, 0, glFormat, glType, image.data);
  //         }
  //       }
  //     }
  //   }

  //   if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
  //     generateMipmap(textureType);
  //   }

  //   textureProperties["__version"] = texture.version;

  //   if (texture.onUpdate != null) texture.onUpdate!(texture);
  // }

  void uploadTexture(Map<String, dynamic> textureProperties, Texture texture, slot) {
    dynamic textureType = _gl.TEXTURE_2D;

    if (texture is DataArrayTexture) textureType = _gl.TEXTURE_2D_ARRAY;
    if (texture is Data3DTexture) textureType = _gl.TEXTURE_3D;

    final forceUpload = initTexture(textureProperties, texture);
    final source = texture.source;

    state.activeTexture(_gl.TEXTURE0 + slot);
    state.bindTexture(textureType, textureProperties["__webglTexture"]);

    if (source.version != source.currentVersion || forceUpload == true) {
      _gl.pixelStorei(_gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
      _gl.pixelStorei(_gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
      _gl.pixelStorei(_gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
      if (kIsWeb) {
        _gl.pixelStorei(_gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, _gl.NONE);
      }

      final needsPowerOfTwo = textureNeedsPowerOfTwo(texture) && isPowerOfTwo(texture.image) == false;
      dynamic image = resizeImage(texture.image, needsPowerOfTwo, false, maxTextureSize);
      image = verifyColorSpace(texture, image);

      final supportsMips = isPowerOfTwo(image) || isWebGL2, glFormat = utils.convert(texture.format, texture.encoding);

      dynamic glType = utils.convert(texture.type),
          glInternalFormat =
              getInternalFormat(texture.internalFormat, glFormat, glType, texture.encoding, texture is VideoTexture);

      setTextureParameters(textureType, texture, supportsMips);

      dynamic mipmap;
      final mipmaps = texture.mipmaps;

      final useTexStorage = (isWebGL2 && texture is! VideoTexture);
      final allocateMemory = (textureProperties["__version"] == null) || (forceUpload == true);
      final levels = getMipLevels(texture, image, supportsMips);

      if (texture is DepthTexture) {
        // populate depth texture with dummy data

        glInternalFormat = _gl.DEPTH_COMPONENT;

        if (isWebGL2) {
          if (texture.type == FloatType) {
            glInternalFormat = _gl.DEPTH_COMPONENT32F;
          } else if (texture.type == UnsignedIntType) {
            glInternalFormat = _gl.DEPTH_COMPONENT24;
          } else if (texture.type == UnsignedInt248Type) {
            glInternalFormat = _gl.DEPTH24_STENCIL8;
          } else {
            glInternalFormat = _gl.DEPTH_COMPONENT16; // WebGL2 requires sized internalformat for glTexImage2D

          }
        } else {
          if (texture.type == FloatType) {
            console.error('WebGLRenderer: Floating point depth texture requires WebGL2.');
          }
        }

        // validation checks for WebGL 1

        if (texture.format == DepthFormat && glInternalFormat == _gl.DEPTH_COMPONENT) {
          // The error INVALID_OPERATION is generated by texImage2D if format and internalformat are
          // DEPTH_COMPONENT and type is not UNSIGNED_SHORT or UNSIGNED_INT
          // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
          if (texture.type != UnsignedShortType && texture.type != UnsignedIntType) {
            console.warning('three.WebGLRenderer: Use UnsignedShortType or UnsignedIntType for DepthFormat DepthTexture.');

            texture.type = UnsignedIntType;
            glType = utils.convert(texture.type);
          }
        }

        if (texture.format == DepthStencilFormat && glInternalFormat == _gl.DEPTH_COMPONENT) {
          // Depth stencil textures need the DEPTH_STENCIL internal format
          // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
          glInternalFormat = _gl.DEPTH_STENCIL;

          // The error INVALID_OPERATION is generated by texImage2D if format and internalformat are
          // DEPTH_STENCIL and type is not UNSIGNED_INT_24_8_WEBGL.
          // (https://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/)
          if (texture.type != UnsignedInt248Type) {
            console.warning('WebGLRenderer: Use UnsignedInt248Type for DepthStencilFormat DepthTexture.');

            texture.type = UnsignedInt248Type;
            glType = utils.convert(texture.type);
          }
        }

        //
        if (allocateMemory) {
          if (useTexStorage) {
            state.texStorage2D(_gl.TEXTURE_2D, 1, glInternalFormat, image.width, image.height);
          } else {
            state.texImage2D(_gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, null);
          }
        }
      } else if (texture is DataTexture) {
        // use manually created mipmaps if available
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels

        if (mipmaps.isNotEmpty && supportsMips) {
          if (useTexStorage && allocateMemory) {
            state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
          }

          for (int i = 0, il = mipmaps.length; i < il; i++) {
            mipmap = mipmaps[i];

            if (useTexStorage) {
              state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
            } else {
              state.texImage2D(
                  _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
            }
          }

          texture.generateMipmaps = false;
        } else {
          if (useTexStorage) {
            if (allocateMemory) {
              state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width.toInt(), image.height.toInt());
            }

            state.texSubImage2D(_gl.TEXTURE_2D, 0, 0, 0, image.width, image.height, glFormat, glType, image.data);
          } else {
            state.texImage2D(
                _gl.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, image.data);
          }
        }
      } else if (texture is CompressedTexture) {
        if (useTexStorage && allocateMemory) {
          state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
        }

        for (int i = 0, il = mipmaps.length; i < il; i++) {
          mipmap = mipmaps[i];

          if (texture.format != RGBAFormat) {
            if (glFormat != null) {
              if (useTexStorage) {
                state.compressedTexSubImage2D(
                    _gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data);
              } else {
                state.compressedTexImage2D(
                    _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data);
              }
            } else {
              console.warning('WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()');
            }
          } else {
            if (useTexStorage) {
              state.texSubImage2D(_gl.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
            } else {
              state.texImage2D(
                  _gl.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
            }
          }
        }
      } else if (texture is DataArrayTexture) {
        if (useTexStorage) {
          if (allocateMemory) {
            state.texStorage3D(_gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, image.width, image.height, image.depth);
          }

          state.texSubImage3D(
              _gl.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
        } else {
          state.texImage3D(_gl.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width, image.height, image.depth, 0,
              glFormat, glType, image.data);
        }
      } else if (texture is Data3DTexture) {
        if (useTexStorage) {
          if (allocateMemory) {
            state.texStorage3D(_gl.TEXTURE_3D, levels, glInternalFormat, image.width, image.height, image.depth);
          }

          state.texSubImage3D(
              _gl.TEXTURE_3D, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
        } else {
          state.texImage3D(_gl.TEXTURE_3D, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat,
              glType, image.data);
        }
      } else if (texture is FramebufferTexture) {
        if (allocateMemory) {
          if (useTexStorage) {
            state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);
          } else if (allocateMemory) {
            int width = image.width, height = image.height;

            for (int i = 0; i < levels; i++) {
              state.texImage2D(_gl.TEXTURE_2D, i, glInternalFormat, width, height, 0, glFormat, glType, null);

              width >>= 1;
              height >>= 1;
            }
          }
        }
      } else {
        // regular Texture (image, video, canvas)

        // use manually created mipmaps if available
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels

        if (mipmaps.isNotEmpty && supportsMips) {
          if (useTexStorage && allocateMemory) {
            state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
          }

          for (int i = 0, il = mipmaps.length; i < il; i++) {
            mipmap = mipmaps[i];

            if (useTexStorage) {
              state.texSubImage2DIf(_gl.TEXTURE_2D, i, 0, 0, glFormat, glType, mipmap);
            } else {
              state.texImage2DIf(_gl.TEXTURE_2D, i, glInternalFormat, glFormat, glType, mipmap);
            }
          }

          texture.generateMipmaps = false;
        } else {
          if (useTexStorage) {
            if (allocateMemory) {
              state.texStorage2D(_gl.TEXTURE_2D, levels, glInternalFormat, image.width.toInt(), image.height.toInt());
            }

            state.texSubImage2DIf(_gl.TEXTURE_2D, 0, 0, 0, glFormat, glType, image);
          } 
          else {
            state.texImage2DIf(_gl.TEXTURE_2D, 0, glInternalFormat, glFormat, glType, image);
          }
        }
      }

      if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
        generateMipmap(textureType);
      }

      source.currentVersion = source.version;

      if (texture.onUpdate != null) texture.onUpdate!(texture);
    }

    textureProperties["__version"] = texture.version;
  }

  // uploadCubeTexture(textureProperties, texture, int slot) {
  //   if (texture.image.length != 6) return;

  //   final forceUpload = initTexture( textureProperties, texture );
  // 	final source = texture.source;

  //   state.activeTexture(gl.TEXTURE0 + slot);
  //   state.bindTexture(gl.TEXTURE_CUBE_MAP, textureProperties.__webglTexture);

  //   if (kIsWeb) {
  //     gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);
  //   }

  //   final image = cubeImage[0],
  //       supportsMips = isPowerOfTwo(image) || isWebGL2,
  //       glFormat = utils.convert(texture.format),
  //       glType = utils.convert(texture.type),
  //       glInternalFormat = getInternalFormat(
  //           texture.internalFormat, glFormat, glType, texture.encoding);

  //   final useTexStorage = (isWebGL2 && texture.isVideoTexture != true);
  //   final allocateMemory = (textureProperties["__version"] == null);
  //   final levels = getMipLevels(texture, image, supportsMips);

  //   setTextureParameters(gl.TEXTURE_CUBE_MAP, texture, supportsMips);

  //   final mipmaps;

  //   if (isCompressed) {
  //     if (useTexStorage && allocateMemory) {
  //       state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat,
  //           image.width, image.height);
  //     }

  //     for (final i = 0; i < 6; i++) {
  //       mipmaps = cubeImage[i].mipmaps;

  //       for (final j = 0; j < mipmaps.length; j++) {
  //         final mipmap = mipmaps[j];

  //         if (texture.format != RGBAFormat) {
  //           if (glFormat != null) {
  //             // state.compressedTexImage2D(
  //             //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //             //     j,
  //             //     glInternalFormat,
  //             //     mipmap.width,
  //             //     mipmap.height,
  //             //     0,
  //             //     0,
  //             //     mipmap.data);
  //             if (useTexStorage) {
  //               state.compressedTexSubImage2D(
  //                   _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                   j,
  //                   0,
  //                   0,
  //                   mipmap.width,
  //                   mipmap.height,
  //                   glFormat,
  //                   mipmap.data);
  //             } else {
  //               state.compressedTexImage2D(
  //                   _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                   j,
  //                   glInternalFormat,
  //                   mipmap.width,
  //                   mipmap.height,
  //                   0,
  //                   mipmap.data);
  //             }
  //           } else {
  //             print(
  //                 'three.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()');
  //           }
  //         } else {
  //           // state.texImage2D(
  //           //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //           //     j,
  //           //     glInternalFormat,
  //           //     mipmap.width,
  //           //     mipmap.height,
  //           //     0,
  //           //     glFormat,
  //           //     glType,
  //           //     mipmap.data);
  //           if (useTexStorage) {
  //             state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0,
  //                 mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
  //           } else {
  //             state.texImage2D(
  //                 _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                 j,
  //                 glInternalFormat,
  //                 mipmap.width,
  //                 mipmap.height,
  //                 0,
  //                 glFormat,
  //                 glType,
  //                 mipmap.data);
  //           }
  //         }
  //       }
  //     }
  //   } else {
  //     mipmaps = texture.mipmaps;

  //     if (useTexStorage && allocateMemory) {
  //       // TODO: Uniformly handle mipmap definitions
  //       // Normal textures and compressed cube textures define base level + mips with their mipmap array
  //       // Uncompressed cube textures use their mipmap array only for mips (no base level)

  //       if (mipmaps.length > 0) levels++;

  //       state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat,
  //           cubeImage[0].width, cubeImage[0].height);
  //     }

  //     for (final i = 0; i < 6; i++) {
  //       if (isDataTexture) {
  //         // state.texImage2D(
  //         //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //         //     0,
  //         //     glInternalFormat,
  //         //     cubeImage[i].width,
  //         //     cubeImage[i].height,
  //         //     0,
  //         //     glFormat,
  //         //     glType,
  //         //     cubeImage[i].data);

  //         if (useTexStorage) {
  //           state.texSubImage2D(
  //               _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //               0,
  //               0,
  //               0,
  //               cubeImage[i].width,
  //               cubeImage[i].height,
  //               glFormat,
  //               glType,
  //               cubeImage[i].data);
  //         } else {
  //           state.texImage2D(
  //               _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //               0,
  //               glInternalFormat,
  //               cubeImage[i].width,
  //               cubeImage[i].height,
  //               0,
  //               glFormat,
  //               glType,
  //               cubeImage[i].data);
  //         }

  //         for (final j = 0; j < mipmaps.length; j++) {
  //           final mipmap = mipmaps[j];
  //           final mipmapImage = mipmap.image[i].image;

  //           // state.texImage2D(
  //           //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //           //     j + 1,
  //           //     glInternalFormat,
  //           //     mipmapImage.width,
  //           //     mipmapImage.height,
  //           //     0,
  //           //     glFormat,
  //           //     glType,
  //           //     mipmapImage.data);

  //           if (useTexStorage) {
  //             state.texSubImage2D(
  //                 _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                 j + 1,
  //                 0,
  //                 0,
  //                 mipmapImage.width,
  //                 mipmapImage.height,
  //                 glFormat,
  //                 glType,
  //                 mipmapImage.data);
  //           } else {
  //             state.texImage2D(
  //                 _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                 j + 1,
  //                 glInternalFormat,
  //                 mipmapImage.width,
  //                 mipmapImage.height,
  //                 0,
  //                 glFormat,
  //                 glType,
  //                 mipmapImage.data);
  //           }
  //         }
  //       } else {
  //         // state.texImage2D(
  //         //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //         //     0,
  //         //     glInternalFormat,
  //         //     null,
  //         //     null,
  //         //     null,
  //         //     glFormat,
  //         //     glType,
  //         //     cubeImage[i]);

  //         if (useTexStorage) {
  //           state.texSubImage2D(
  //               _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //               0,
  //               0,
  //               0,
  //               cubeImage[i].width,
  //               cubeImage[i].height,
  //               glFormat,
  //               glType,
  //               cubeImage[i]);
  //         } else {
  //           state.texImage2D(
  //               _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //               0,
  //               glInternalFormat,
  //               cubeImage[i].width,
  //               cubeImage[i].height,
  //               0,
  //               glFormat,
  //               glType,
  //               cubeImage[i]);
  //         }

  //         for (final j = 0; j < mipmaps.length; j++) {
  //           final mipmap = mipmaps[j];

  //           // state.texImage2D(
  //           //     gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //           //     j + 1,
  //           //     glInternalFormat,
  //           //     null,
  //           //     null,
  //           //     null,
  //           //     glFormat,
  //           //     glType,
  //           //     mipmap.image[i]);
  //           if (useTexStorage) {
  //             state.texSubImage2D(
  //                 _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                 j + 1,
  //                 0,
  //                 0,
  //                 mipmap.image[i].width,
  //                 mipmap.image[i].height,
  //                 glFormat,
  //                 glType,
  //                 mipmap.image[i]);
  //           } else {
  //             state.texImage2D(
  //                 _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
  //                 j + 1,
  //                 glInternalFormat,
  //                 mipmap.image[i].width,
  //                 mipmap.image[i].height,
  //                 0,
  //                 glFormat,
  //                 glType,
  //                 mipmap.image[i]);
  //           }
  //         }
  //       }
  //     }
  //   }

  //   if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
  //     // We assume images for cube map have the same size.
  //     generateMipmap(gl.TEXTURE_CUBE_MAP);
  //   }

  //   textureProperties.__version = texture.version;

  //   if (texture.onUpdate) texture.onUpdate(texture);
  // }

  void uploadCubeTexture(Map<String, dynamic> textureProperties, Texture texture, int slot) {
    if (texture.image.length != 6) return;

    final forceUpload = initTexture(textureProperties, texture);
    final source = texture.source;

    state.activeTexture(_gl.TEXTURE0 + slot);
    state.bindTexture(_gl.TEXTURE_CUBE_MAP, textureProperties['__webglTexture']);

    if (source.version != source.currentVersion || forceUpload == true) {
      _gl.pixelStorei(_gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
      _gl.pixelStorei(_gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
      _gl.pixelStorei(_gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
      if (kIsWeb) {
        _gl.pixelStorei(_gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, _gl.NONE);
      }

      final isCompressed = (texture.isCompressedTexture || texture.image[0] is CompressedTexture);
      final isDataTexture = (texture.image[0] != null && texture.image[0] is DataTexture);

      final cubeImage = [];

      for (int i = 0; i < 6; i++) {
        if (!isCompressed && !isDataTexture) {
          cubeImage.add(resizeImage(texture.image[i], false, true, maxCubemapSize));
        } else {
          cubeImage.add(isDataTexture ? texture.image[i].image : texture.image[i]);
        }

        cubeImage[i] = verifyColorSpace(texture, cubeImage[i]);
      }

      final image = cubeImage[0],
          supportsMips = isPowerOfTwo(image) || isWebGL2,
          glFormat = utils.convert(texture.format, texture.encoding),
          glType = utils.convert(texture.type),
          glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.encoding);

      final useTexStorage = (isWebGL2 && texture.isVideoTexture != true);
      final allocateMemory = (textureProperties['__version'] == null);
      int levels = getMipLevels(texture, image, supportsMips);

      setTextureParameters(_gl.TEXTURE_CUBE_MAP, texture, supportsMips);

      dynamic mipmaps;

      if (isCompressed) {
        if (useTexStorage && allocateMemory) {
          state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat, image.width, image.height);
        }

        for (int i = 0; i < 6; i++) {
          mipmaps = cubeImage[i].mipmaps;

          for (int j = 0; j < mipmaps.length; j++) {
            final mipmap = mipmaps[j];

            if (texture.format != RGBAFormat) {
              if (glFormat != null) {
                if (useTexStorage) {
                  state.compressedTexSubImage2D(
                      _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data);
                } else {
                  state.compressedTexImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width,
                      mipmap.height, 0, mipmap.data);
                }
              } else {
                console.warning('WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()');
              }
            } else {
              if (useTexStorage) {
                state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat,
                    glType, mipmap.data);
              } else {
                state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width, mipmap.height,
                    0, glFormat, glType, mipmap.data);
              }
            }
          }
        }
      } else {
        mipmaps = texture.mipmaps;

        if (useTexStorage && allocateMemory) {
          // TODO: Uniformly handle mipmap definitions
          // Normal textures and compressed cube textures define base level + mips with their mipmap array
          // Uncompressed cube textures use their mipmap array only for mips (no base level)

          if (mipmaps.length > 0) levels++;

          state.texStorage2D(_gl.TEXTURE_CUBE_MAP, levels, glInternalFormat, cubeImage[0].width, cubeImage[0].height);
        }

        for (int i = 0; i < 6; i++) {
          if (isDataTexture) {
            if (useTexStorage) {
              state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, cubeImage[i].width, cubeImage[i].height,
                  glFormat, glType, cubeImage[i].data);
            } else {
              state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, cubeImage[i].width,
                  cubeImage[i].height, 0, glFormat, glType, cubeImage[i].data);
            }

            for (int j = 0; j < mipmaps.length; j++) {
              final mipmap = mipmaps[j];
              final mipmapImage = mipmap.image[i].image;

              if (useTexStorage) {
                state.texSubImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, mipmapImage.width,
                    mipmapImage.height, glFormat, glType, mipmapImage.data);
              } else {
                state.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, mipmapImage.width,
                    mipmapImage.height, 0, glFormat, glType, mipmapImage.data);
              }
            }
          } else {
            if (useTexStorage) {
              state.texSubImage2DIf(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, glFormat, glType, cubeImage[i]);
            } else {
              state.texImage2DIf(
                  _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, glFormat, glType, cubeImage[i]);
            }

            for (int j = 0; j < mipmaps.length; j++) {
              final mipmap = mipmaps[j];

              if (useTexStorage) {
                state.texSubImage2DIf(
                    _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, glFormat, glType, mipmap.image[i]);
              } else {
                state.texImage2DIf(
                    _gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, glFormat, glType, mipmap.image[i]);
              }
            }
          }
        }
      }

      if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
        // We assume images for cube map have the same size.
        generateMipmap(_gl.TEXTURE_CUBE_MAP);
      }

      source.currentVersion = source.version;

      if (texture.onUpdate != null) texture.onUpdate!(texture);
    }

    textureProperties['__version'] = texture.version;
  }

  // Render targets

  // Setup storage for target texture and bind it to correct framebuffer
  void setupFrameBufferTexture(framebuffer, RenderTarget renderTarget, Texture texture, attachment, textureTarget) {
    final glFormat = utils.convert(texture.format);
    final glType = utils.convert(texture.type);
    final glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.encoding);

    if (textureTarget == gl.TEXTURE_3D || textureTarget == gl.TEXTURE_2D_ARRAY) {
      state.texImage3D(textureTarget, 0, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt(),
          renderTarget.depth.toInt(), 0, glFormat, glType, null);
    } else {
      state.texImage2D(textureTarget, 0, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt(), 0,
          glFormat, glType, null);
    }

    state.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    // gl.framebufferTexture2D(gl.FRAMEBUFFER, attachment, textureTarget,
    //     properties.get(texture)["__webglTexture"], 0);

    if (useMultisampledRenderToTexture(renderTarget)) {
      multisampledRenderToTextureExtension.framebufferTexture2DMultisampleEXT(_gl.FRAMEBUFFER, attachment,
          textureTarget, properties.get(texture)["__webglTexture"], 0, getRenderTargetSamples(renderTarget));
    } else {
      _gl.framebufferTexture2D(
          _gl.FRAMEBUFFER, attachment, textureTarget, properties.get(texture)["__webglTexture"], 0);
    }

    state.bindFramebuffer(gl.FRAMEBUFFER, null);
  }

  // Setup storage for internal depth/stencil buffers and bind to correct framebuffer
  void setupRenderBufferStorage(renderbuffer, RenderTarget renderTarget, bool isMultisample) {
    gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuffer);

    if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {
      dynamic glInternalFormat = gl.DEPTH_COMPONENT16;

      if (isMultisample || useMultisampledRenderToTexture(renderTarget)) {
        final depthTexture = renderTarget.depthTexture;

        if (depthTexture != null) {
          if (depthTexture.type == FloatType) {
            glInternalFormat = gl.DEPTH_COMPONENT32F;
          } else if (depthTexture.type == UnsignedIntType) {
            glInternalFormat = gl.DEPTH_COMPONENT24;
          }
        }

        final samples = getRenderTargetSamples(renderTarget);

        // gl.renderbufferStorageMultisample(gl.RENDERBUFFER, samples,
        //     glInternalFormat, renderTarget.width, renderTarget.height);

        if (useMultisampledRenderToTexture(renderTarget)) {
          multisampledRenderToTextureExtension.renderbufferStorageMultisampleEXT(
              gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt());
        } else {
          gl.renderbufferStorageMultisample(
              gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt());
        }
      } else {
        gl.renderbufferStorage(
            gl.RENDERBUFFER, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt());
      }

      gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
    } else if (renderTarget.depthBuffer && renderTarget.stencilBuffer) {
      final samples = getRenderTargetSamples(renderTarget);
      if (isMultisample && useMultisampledRenderToTexture(renderTarget) == false) {
        final samples = getRenderTargetSamples(renderTarget);

        gl.renderbufferStorageMultisample(
            gl.RENDERBUFFER, samples, gl.DEPTH24_STENCIL8, renderTarget.width.toInt(), renderTarget.height.toInt());
      } else if (useMultisampledRenderToTexture(renderTarget)) {
        multisampledRenderToTextureExtension.renderbufferStorageMultisampleEXT(
            _gl.RENDERBUFFER, samples, _gl.DEPTH24_STENCIL8, renderTarget.width.toInt(), renderTarget.height.toInt());
      } else {
        gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_STENCIL, renderTarget.width, renderTarget.height);
      }

      gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
    } else {
      // Use the first texture for MRT so far
      final texture = renderTarget.isWebGLMultipleRenderTargets == true ? renderTarget.texture[0] : renderTarget.texture;

      final glFormat = utils.convert(texture.format);
      final glType = utils.convert(texture.type);
      final glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.encoding);

      final samples = getRenderTargetSamples(renderTarget);

      if (isMultisample && useMultisampledRenderToTexture(renderTarget) == false) {
        gl.renderbufferStorageMultisample(
            gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);
      } else if (useMultisampledRenderToTexture(renderTarget)) {
        multisampledRenderToTextureExtension.renderbufferStorageMultisampleEXT(
            _gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height);
      } else {
        gl.renderbufferStorage(gl.RENDERBUFFER, glInternalFormat, renderTarget.width, renderTarget.height);
      }
    }

    gl.bindRenderbuffer(gl.RENDERBUFFER, null);
  }

  // Setup resources for a Depth Texture for a FBO (needs an extension)
  void setupDepthTexture(framebuffer, RenderTarget renderTarget) {
    final isCube = (renderTarget.isWebGLCubeRenderTarget);
    if (isCube) {
      throw ('Depth Texture with cube render targets is not supported');
    }

    state.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);

    if (!(renderTarget.depthTexture != null && renderTarget.depthTexture is DepthTexture)) {
      throw ('renderTarget.depthTexture must be an instance of three.DepthTexture');
    }

    // upload an empty depth texture with framebuffer size
    final depthTexture = renderTarget.depthTexture!;
    if (properties.get(depthTexture)["__webglTexture"] == null ||
        depthTexture.image.width != renderTarget.width ||
        depthTexture.image.height != renderTarget.height) {
      depthTexture.image.width = renderTarget.width;
      depthTexture.image.height = renderTarget.height;
      depthTexture.needsUpdate = true;
    }

    setTexture2D(depthTexture, 0);

    final webglDepthTexture = properties.get(depthTexture)["__webglTexture"];
    final samples = getRenderTargetSamples(renderTarget);

    if (depthTexture.format == DepthFormat) {
      if (useMultisampledRenderToTexture(renderTarget)) {
        multisampledRenderToTextureExtension.framebufferTexture2DMultisampleEXT(
            gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, webglDepthTexture, 0, samples);
      } else {
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, webglDepthTexture, 0);
      }
    } else if (depthTexture.format == DepthStencilFormat) {
      if (useMultisampledRenderToTexture(renderTarget)) {
        multisampledRenderToTextureExtension.framebufferTexture2DMultisampleEXT(
            _gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0, samples);
      } else {
        _gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.TEXTURE_2D, webglDepthTexture, 0);
      }
    } else {
      throw ('Unknown depthTexture format');
    }
  }

  // Setup GL resources for a non-texture depth buffer
  void setupDepthRenderbuffer(RenderTarget renderTarget) {
    final renderTargetProperties = properties.get(renderTarget);

    final isCube = (renderTarget.isWebGLCubeRenderTarget == true);

    if (renderTarget.depthTexture != null) {
      if (isCube) {
        throw ('target.depthTexture not supported in Cube render targets');
      }

      setupDepthTexture(renderTargetProperties["__webglFramebuffer"], renderTarget);
    } else {
      if (isCube) {
        renderTargetProperties["__webglDepthbuffer"] = [];

        for (int i = 0; i < 6; i++) {
          state.bindFramebuffer(gl.FRAMEBUFFER, renderTargetProperties["__webglFramebuffer"][i]);

          // renderTargetProperties["__webglDepthbuffer"][ i ] = gl.createRenderbuffer();
          renderTargetProperties["__webglDepthbuffer"].add(gl.createRenderbuffer());

          setupRenderBufferStorage(renderTargetProperties["__webglDepthbuffer"][i], renderTarget, false);
        }
      } else {
        state.bindFramebuffer(gl.FRAMEBUFFER, renderTargetProperties["__webglFramebuffer"]);

        renderTargetProperties["__webglDepthbuffer"] = gl.createRenderbuffer();
        setupRenderBufferStorage(renderTargetProperties["__webglDepthbuffer"], renderTarget, false);
      }
    }

    state.bindFramebuffer(gl.FRAMEBUFFER, null);
  }

  // rebind framebuffer with external textures
  void rebindTextures(RenderTarget renderTarget, colorTexture, depthTexture) {
    final renderTargetProperties = properties.get(renderTarget);

    if (colorTexture != null) {
      setupFrameBufferTexture(renderTargetProperties["__webglFramebuffer"], renderTarget, renderTarget.texture,
          _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D);
    }

    if (depthTexture != null) {
      setupDepthRenderbuffer(renderTarget);
    }
  }

  // Set up GL resources for the render target
  void setupRenderTarget(RenderTarget renderTarget) {
    final texture = renderTarget.texture;

    final renderTargetProperties = properties.get(renderTarget);
    final textureProperties = properties.get(renderTarget.texture);

    renderTarget.addEventListener('dispose', onRenderTargetDispose);

    if (renderTarget.isWebGLMultipleRenderTargets != true) {
      textureProperties["__webglTexture"] = gl.createTexture();
      textureProperties["__version"] = texture.version;
      info.memory["textures"] = info.memory["textures"]! + 1;
    }

    final isCube = (renderTarget.isWebGLCubeRenderTarget == true);
    final isMultipleRenderTargets = (renderTarget.isWebGLMultipleRenderTargets == true);
    final supportsMips = isPowerOfTwo(renderTarget) || isWebGL2;

    // Setup framebuffer

    if (isCube) {
      renderTargetProperties["__webglFramebuffer"] = [];

      for (int i = 0; i < 6; i++) {
        // renderTargetProperties["__webglFramebuffer"][ i ] = gl.createFramebuffer();

        renderTargetProperties["__webglFramebuffer"].add(gl.createFramebuffer());
      }
    } else {
      renderTargetProperties["__webglFramebuffer"] = gl.createFramebuffer();

      if (isMultipleRenderTargets) {
        if (capabilities.drawBuffers) {
          final textures = renderTarget.texture;

          for (int i = 0, il = textures.length; i < il; i++) {
            final attachmentProperties = properties.get(textures[i]);

            if (attachmentProperties["__webglTexture"] == null) {
              attachmentProperties["__webglTexture"] = gl.createTexture();

              info.memory["textures"] = info.memory["textures"]! + 1;
            }
          }
        } else {
          console.error('WebGLRenderer: WebGLMultipleRenderTargets can only be used with WebGL2 or WEBGL_draw_buffers extension.');
        }
      } else if ((isWebGL2 && renderTarget.samples > 0) && useMultisampledRenderToTexture(renderTarget) == false) {
        renderTargetProperties["__webglMultisampledFramebuffer"] = _gl.createFramebuffer();
        renderTargetProperties["__webglColorRenderbuffer"] = _gl.createRenderbuffer();

        _gl.bindRenderbuffer(_gl.RENDERBUFFER, renderTargetProperties["__webglColorRenderbuffer"]);

        final glFormat = utils.convert(texture.format, texture.encoding);
        final glType = utils.convert(texture.type);
        final glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.encoding);
        final samples = getRenderTargetSamples(renderTarget);
        _gl.renderbufferStorageMultisample(
            _gl.RENDERBUFFER, samples, glInternalFormat, renderTarget.width.toInt(), renderTarget.height.toInt());

        state.bindFramebuffer(_gl.FRAMEBUFFER, renderTargetProperties["__webglMultisampledFramebuffer"]);
        _gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.RENDERBUFFER,
            renderTargetProperties["__webglColorRenderbuffer"]);
        _gl.bindRenderbuffer(_gl.RENDERBUFFER, null);

        if (renderTarget.depthBuffer) {
          renderTargetProperties["__webglDepthRenderbuffer"] = _gl.createRenderbuffer();
          setupRenderBufferStorage(renderTargetProperties["__webglDepthRenderbuffer"], renderTarget, true);
        }

        state.bindFramebuffer(_gl.FRAMEBUFFER, null);
      }
    }

    // Setup color buffer

    if (isCube) {
      state.bindTexture(gl.TEXTURE_CUBE_MAP, textureProperties["__webglTexture"]);
      setTextureParameters(gl.TEXTURE_CUBE_MAP, texture, supportsMips);

      for (int i = 0; i < 6; i++) {
        setupFrameBufferTexture(renderTargetProperties["__webglFramebuffer"][i], renderTarget, texture,
            gl.COLOR_ATTACHMENT0, gl.TEXTURE_CUBE_MAP_POSITIVE_X + i);
      }

      if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
        generateMipmap(gl.TEXTURE_CUBE_MAP);
      }

      state.bindTexture(gl.TEXTURE_CUBE_MAP, null);
    } else if (isMultipleRenderTargets) {
      final textures = renderTarget.texture;

      for (int i = 0, il = textures.length; i < il; i++) {
        final attachment = textures[i];
        final attachmentProperties = properties.get(attachment);

        state.bindTexture(gl.TEXTURE_2D, attachmentProperties["__webglTexture"]);
        setTextureParameters(gl.TEXTURE_2D, attachment, supportsMips);
        setupFrameBufferTexture(renderTargetProperties["__webglFramebuffer"], renderTarget, attachment,
            gl.COLOR_ATTACHMENT0 + i, gl.TEXTURE_2D);

        if (textureNeedsGenerateMipmaps(attachment, supportsMips)) {
          generateMipmap(gl.TEXTURE_2D);
        }
      }

      state.bindTexture(gl.TEXTURE_2D, null);
    } else {
      dynamic glTextureType = gl.TEXTURE_2D;

      if (renderTarget is WebGL3DRenderTarget || renderTarget is WebGLArrayRenderTarget) {
        if (isWebGL2) {
          glTextureType = renderTarget is WebGL3DRenderTarget ? _gl.TEXTURE_3D : _gl.TEXTURE_2D_ARRAY;
        } else {
          print('three.DataTexture3D and three.DataTexture2DArray only supported with WebGL2.');
        }
      }

      state.bindTexture(glTextureType, textureProperties["__webglTexture"]);
      setTextureParameters(glTextureType, texture, supportsMips);
      setupFrameBufferTexture(
          renderTargetProperties["__webglFramebuffer"], renderTarget, texture, gl.COLOR_ATTACHMENT0, glTextureType);

      if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
        generateMipmap(glTextureType);
      }

      state.bindTexture(glTextureType, null);
    }

    // Setup depth and stencil buffers

    if (renderTarget.depthBuffer) {
      setupDepthRenderbuffer(renderTarget);
    }
  }

  void updateRenderTargetMipmap(RenderTarget renderTarget) {
    final supportsMips = isPowerOfTwo(renderTarget) || isWebGL2;

    final textures = renderTarget.isWebGLMultipleRenderTargets == true ? renderTarget.texture : [renderTarget.texture];

    for (int i = 0, il = textures.length; i < il; i++) {
      final texture = textures[i];

      if (textureNeedsGenerateMipmaps(texture, supportsMips)) {
        final target = renderTarget.isWebGLCubeRenderTarget ? gl.TEXTURE_CUBE_MAP : gl.TEXTURE_2D;
        final webglTexture = properties.get(texture)["__webglTexture"];

        state.bindTexture(target, webglTexture);
        generateMipmap(target);
        state.bindTexture(target, null);
      }
    }
  }

  void updateMultisampleRenderTarget(RenderTarget renderTarget) {
    if ((isWebGL2 && renderTarget.samples > 0) && useMultisampledRenderToTexture(renderTarget) == false) {
      final width = renderTarget.width.toInt();
      final height = renderTarget.height.toInt();
      dynamic mask = _gl.COLOR_BUFFER_BIT;
      final invalidationArray = [_gl.COLOR_ATTACHMENT0];
      final depthStyle = renderTarget.stencilBuffer ? _gl.DEPTH_STENCIL_ATTACHMENT : _gl.DEPTH_ATTACHMENT;

      if (renderTarget.depthBuffer) {
        invalidationArray.add(depthStyle);
      }

      final renderTargetProperties = properties.get(renderTarget);
      final ignoreDepthValues = (renderTargetProperties["__ignoreDepthValues"] != null)
          ? renderTargetProperties["__ignoreDepthValues"]
          : true;

      if (ignoreDepthValues == false) {
        if (renderTarget.depthBuffer) mask |= _gl.DEPTH_BUFFER_BIT;
        if (renderTarget.stencilBuffer) mask |= _gl.STENCIL_BUFFER_BIT;
      }

      state.bindFramebuffer(_gl.READ_FRAMEBUFFER, renderTargetProperties["__webglMultisampledFramebuffer"]);
      state.bindFramebuffer(_gl.DRAW_FRAMEBUFFER, renderTargetProperties["__webglFramebuffer"]);

      if (ignoreDepthValues == true) {
        _gl.invalidateFramebuffer(_gl.READ_FRAMEBUFFER, [depthStyle]);
        _gl.invalidateFramebuffer(_gl.DRAW_FRAMEBUFFER, [depthStyle]);
      }

      _gl.blitFramebuffer(0, 0, width, height, 0, 0, width, height, mask, _gl.NEAREST);

      if (supportsInvalidateFramenbuffer) {
        _gl.invalidateFramebuffer(_gl.READ_FRAMEBUFFER, invalidationArray);
      }

      state.bindFramebuffer(_gl.READ_FRAMEBUFFER, null);
      state.bindFramebuffer(_gl.DRAW_FRAMEBUFFER, renderTargetProperties["__webglMultisampledFramebuffer"]);
    }
  }

  int getRenderTargetSamples(RenderTarget renderTarget) {
    return math.min(maxSamples, renderTarget.samples);
  }

  bool useMultisampledRenderToTexture(RenderTarget renderTarget) {
    final renderTargetProperties = properties.get(renderTarget);

    return isWebGL2 &&
        renderTarget.samples > 0 &&
        extensions.has('WEBGL_multisampled_render_to_texture') == true &&
        renderTargetProperties["__useRenderToTexture"] != false;
  }

  void updateVideoTexture(VideoTexture texture) {
    final frame = info.render["frame"];

    // Check the last frame we updated the VideoTexture

    if (_videoTextures[texture] != frame) {
      _videoTextures[texture] = frame;
      texture.update();
    }
  }

  void uploadOpenGLTexture(Map<String, dynamic> textureProperties, OpenGLTexture texture, int slot) {
    final frame = info.render["frame"];
    if (_videoTextures[texture] != frame) {
      _videoTextures[texture] = frame;
      texture.update();
    }

    final textureType = gl.TEXTURE_2D;

    initTexture(textureProperties, texture);

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(textureType, textureProperties["__webglTexture"]);

    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
  }

  verifyColorSpace(Texture texture, image) {
    final encoding = texture.encoding;
    final format = texture.format;
    final type = texture.type;

    if (texture.isCompressedTexture == true || texture.isVideoTexture == true || texture.format == SRGBAFormat) {
      return image;
    }

    if (encoding != LinearEncoding) {
      // sRGB

      if (encoding == sRGBEncoding) {
        if (isWebGL2 == false) {
          // in WebGL 1, try to use EXT_sRGB extension and unsized formats

          if (extensions.has('EXT_sRGB') == true && format == RGBAFormat) {
            texture.format = SRGBAFormat;

            // it's not possible to generate mips in WebGL 1 with this extension

            texture.minFilter = LinearFilter;
            texture.generateMipmaps = false;
          } else {
            // slow fallback (CPU decode)

            //image = ImageUtils.sRGBToLinear(image);
          }
        } else {
          // in WebGL 2 uncompressed textures can only be sRGB encoded if they have the RGBA8 format

          if (format != RGBAFormat || type != UnsignedByteType) {
            console.warning('WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.');
          }
        }
      } else {
        console.warning('WebGLTextures: Unsupported texture encoding: $encoding');
      }
    }

    return image;
  }

  void dispose() {}
}
