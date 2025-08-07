part of three_webgl;

class WebGLTextures {
  bool _didDispose = false;
  RenderingContext gl;
  RenderingContext get _gl => gl;
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

  //final _imageDimensions = Vector2();
  final WeakMap _videoTextures = WeakMap();

  final WeakMap _sources = WeakMap();
  // maps WebglTexture objects to instances of Source

  Map<int, int> wrappingToGL = {};
  Map<int, int> filterToGL = {};
  Map<int, int> compareToGL = {};

  dynamic multisampledRenderToTextureExtension;
  dynamic multisampledRTTExt;
  final bool supportsInvalidateFramebuffer = false;//typeof navigator === 'undefined' ? false : /OculusBrowser/g.test( navigator.userAgent );


  WebGLTextures(this.gl, this.extensions, this.state, this.properties, this.capabilities, this.utils, this.info) {
    maxTextures = capabilities.maxTextures;
    maxCubemapSize = capabilities.maxCubemapSize;
    maxTextureSize = capabilities.maxTextureSize;
    maxSamples = capabilities.maxSamples;

    multisampledRTTExt = extensions.has( 'WEBGL_multisampled_render_to_texture' )? extensions.get( 'WEBGL_multisampled_render_to_texture' ) : null;
    multisampledRenderToTextureExtension = extensions.has('WEBGL_multisampled_render_to_texture')
        ? extensions.get('WEBGL_multisampled_render_to_texture')
        : null;

    wrappingToGL[RepeatWrapping] = WebGL.REPEAT;
    wrappingToGL[ClampToEdgeWrapping] = WebGL.CLAMP_TO_EDGE;
    wrappingToGL[MirroredRepeatWrapping] = WebGL.MIRRORED_REPEAT;

    filterToGL[NearestFilter] = WebGL.NEAREST;
    filterToGL[NearestMipmapNearestFilter] = WebGL.NEAREST_MIPMAP_NEAREST;
    filterToGL[NearestMipmapLinearFilter] = WebGL.NEAREST_MIPMAP_LINEAR;
    filterToGL[LinearFilter] = WebGL.LINEAR;
    filterToGL[LinearMipmapNearestFilter] = WebGL.LINEAR_MIPMAP_NEAREST;
    filterToGL[LinearMipmapLinearFilter] = WebGL.LINEAR_MIPMAP_LINEAR;

		compareToGL[ NeverCompare ] = WebGL.NEVER;
		compareToGL[ AlwaysCompare ] = WebGL.ALWAYS;
		compareToGL[ LessCompare ] = WebGL.LESS;
		compareToGL[ LessEqualCompare ] = WebGL.LEQUAL;
		compareToGL[ EqualCompare ] = WebGL.EQUAL;
		compareToGL[ GreaterEqualCompare ] = WebGL.GEQUAL;
		compareToGL[ GreaterCompare ] = WebGL.GREATER;
		compareToGL[ NotEqualCompare ] = WebGL.NOTEQUAL;

    // TODO FIXME when on web && is OculusBrowser
    // supportsInvalidateFramenbuffer = kIsWeb && RegExp(r"OculusBrowser").hasMatch( navigator.userAgent );
  }

  bool isPowerOfTwo(image) {
    return MathUtils.isPowerOfTwo(image.width.toInt()) && MathUtils.isPowerOfTwo(image.height.toInt());
  }

  bool textureNeedsGenerateMipmaps(Texture texture) {
    return texture.generateMipmaps;
  }

  generateMipmap(target) {
    gl.generateMipmap(target);
  }

  int getInternalFormat(internalFormatName, int glFormat, int glType, String colorSpace, [bool forceLinearTransfer = false]) {
		if ( internalFormatName != null ) {
			if ( WebGL.get( internalFormatName ) != null ) return WebGL.get( internalFormatName )!;
			console.warning( 'THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format \'' + internalFormatName + '\'' );
		}

		int internalFormat = glFormat;

		if ( glFormat == WebGL.RED ) {
			if ( glType == WebGL.FLOAT ) internalFormat = WebGL.R32F;
			if ( glType == WebGL.HALF_FLOAT ) internalFormat = WebGL.R16F;
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.R8;
		}

		if ( glFormat == WebGL.RED_INTEGER ) {
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.R8UI;
			if ( glType == WebGL.UNSIGNED_SHORT ) internalFormat = WebGL.R16UI;
			if ( glType == WebGL.UNSIGNED_INT ) internalFormat = WebGL.R32UI;
			if ( glType == WebGL.BYTE ) internalFormat = WebGL.R8I;
			if ( glType == WebGL.SHORT ) internalFormat = WebGL.R16I;
			if ( glType == WebGL.INT ) internalFormat = WebGL.R32I;
		}

		if ( glFormat == WebGL.RG ) {
			if ( glType == WebGL.FLOAT ) internalFormat = WebGL.RG32F;
			if ( glType == WebGL.HALF_FLOAT ) internalFormat = WebGL.RG16F;
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.RG8;
		}

		if ( glFormat == WebGL.RG_INTEGER ) {
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.RG8UI;
			if ( glType == WebGL.UNSIGNED_SHORT ) internalFormat = WebGL.RG16UI;
			if ( glType == WebGL.UNSIGNED_INT ) internalFormat = WebGL.RG32UI;
			if ( glType == WebGL.BYTE ) internalFormat = WebGL.RG8I;
			if ( glType == WebGL.SHORT ) internalFormat = WebGL.RG16I;
			if ( glType == WebGL.INT ) internalFormat = WebGL.RG32I;
		}

		if ( glFormat == WebGL.RGB_INTEGER ) {
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.RGB8UI;
			if ( glType == WebGL.UNSIGNED_SHORT ) internalFormat = WebGL.RGB16UI;
			if ( glType == WebGL.UNSIGNED_INT ) internalFormat = WebGL.RGB32UI;
			if ( glType == WebGL.BYTE ) internalFormat = WebGL.RGB8I;
			if ( glType == WebGL.SHORT ) internalFormat = WebGL.RGB16I;
			if ( glType == WebGL.INT ) internalFormat = WebGL.RGB32I;
		}

		if ( glFormat == WebGL.RGBA_INTEGER ) {

			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = WebGL.RGBA8UI;
			if ( glType == WebGL.UNSIGNED_SHORT ) internalFormat = WebGL.RGBA16UI;
			if ( glType == WebGL.UNSIGNED_INT ) internalFormat = WebGL.RGBA32UI;
			if ( glType == WebGL.SHORT ) internalFormat = WebGL.RGBA16I;
			if ( glType == WebGL.INT ) internalFormat = WebGL.RGBA32I;

		}

		if ( glFormat == WebGL.RGB ) {
			if ( glType == WebGL.UNSIGNED_INT_5_9_9_9_REV ) internalFormat = WebGL.RGB9_E5;
		}

		if ( glFormat == WebGL.RGBA ) {
			final String transfer = forceLinearTransfer ? LinearTransfer : ColorManagement.getTransfer( ColorSpace.fromString(colorSpace));

			if ( glType == WebGL.FLOAT ) internalFormat = WebGL.RGBA32F;
			if ( glType == WebGL.HALF_FLOAT ) internalFormat = WebGL.RGBA16F;
			if ( glType == WebGL.UNSIGNED_BYTE ) internalFormat = ( transfer == SRGBTransfer ) ? WebGL.SRGB8_ALPHA8 : WebGL.RGBA8;
			if ( glType == WebGL.UNSIGNED_SHORT_4_4_4_4 ) internalFormat = WebGL.RGBA4;
			if ( glType == WebGL.UNSIGNED_SHORT_5_5_5_1 ) internalFormat = WebGL.RGB5_A1;
		}

		if ( internalFormat == WebGL.R16F || internalFormat == WebGL.R32F ||
			internalFormat == WebGL.RG16F || internalFormat == WebGL.RG32F ||
			internalFormat == WebGL.RGBA16F || internalFormat == WebGL.RGBA32F ) {
			extensions.get( 'EXT_color_buffer_float' );
		}

		return internalFormat;
  }

	int getInternalDepthFormat(bool useStencil, [int? depthType ]) {
		late int glInternalFormat;

		if ( useStencil ) {
			if ( depthType == null || depthType == UnsignedIntType || depthType == UnsignedInt248Type ) {
				glInternalFormat = WebGL.DEPTH24_STENCIL8;
			} else if ( depthType == FloatType ) {
				glInternalFormat = WebGL.DEPTH32F_STENCIL8;
			} else if ( depthType == UnsignedShortType ) {
				glInternalFormat = WebGL.DEPTH24_STENCIL8;
				console.warning( 'DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.' );
			}
		} else {
			if ( depthType == null || depthType == UnsignedIntType || depthType == UnsignedInt248Type ) {
				glInternalFormat = WebGL.DEPTH_COMPONENT24;
			} else if ( depthType == FloatType ) {
				glInternalFormat = WebGL.DEPTH_COMPONENT32F;
			} else if ( depthType == UnsignedShortType ) {
				glInternalFormat = WebGL.DEPTH_COMPONENT16;
			}
		}

		return glInternalFormat;
	}

  int getMipLevels(Texture texture, image) {
    if (
      textureNeedsGenerateMipmaps(texture)||
      (texture is FramebufferTexture && 
        texture.minFilter != NearestFilter && 
        texture.minFilter != LinearFilter
      )
    ){
      return MathUtils.log2(
        math.max(
          image.width,
          image.height
        )
      ).toInt() + 1;
    } 
    else if (texture.mipmaps.isNotEmpty) {
      // user-defined mipmaps
      return texture.mipmaps.length;
    } 
    else if (texture is CompressedTexture && texture.image is List) {
      // Dart: TODO texture.image is List ???
      return image.mipmaps.length;
    } 
    else {
      // texture without mipmaps (only base level)
      return 1;
    }
  }

  //

  void onTextureDispose(Event event) {
    final texture = event.target;

    texture.removeEventListener('dispose', onTextureDispose);

    deallocateTexture(texture);

    if (texture is VideoTexture) {
      _videoTextures.delete(texture);
    }
  }

  void onRenderTargetDispose(Event event) {
    final renderTarget = event.target;
    renderTarget.removeEventListener('dispose', onRenderTargetDispose);
    deallocateRenderTarget(renderTarget);
  }

  void deallocateTexture(Texture texture) {
    final textureProperties = properties.get(texture);

    if (textureProperties["__webglInit"] == null) return;

    final source = texture.source;
    final webglTextures = _sources.get(source);

    if (webglTextures != null) {
      Map webglTexture = webglTextures[textureProperties["__cacheKey"]];
      webglTexture["usedTimes"]--;

      if (webglTexture["usedTimes"] == 0) {
        deleteTexture(texture);
      }

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
    final renderTargetProperties = properties.get(renderTarget);

    if (renderTarget.depthTexture != null) {
      renderTarget.depthTexture!.dispose();
      properties.remove( renderTarget.depthTexture );
    }

    if (renderTarget is WebGLCubeRenderTarget) {
      for (int i = 0; i < 6; i++) {
        gl.deleteFramebuffer(renderTargetProperties["__webglFramebuffer"][i]);
				if (renderTargetProperties['__webglFramebuffer'][ i ] is List) {
					for (int level = 0; level < renderTargetProperties['__webglFramebuffer'][ i ].length; level ++ ) _gl.deleteFramebuffer( renderTargetProperties['__webglFramebuffer'][ i ][ level ] );
				} else {
					_gl.deleteFramebuffer( renderTargetProperties['__webglFramebuffer'][ i ] );
				}
        if (renderTargetProperties["__webglDepthbuffer"] != null) {
          gl.deleteRenderbuffer(renderTargetProperties["__webglDepthbuffer"][i]);
        }
      }
    } else {
			if (renderTargetProperties['__webglFramebuffer'] is List) {
				for (int level = 0; level < renderTargetProperties['__webglFramebuffer'].length; level ++ ) _gl.deleteFramebuffer( renderTargetProperties['__webglFramebuffer'][ level ] );
			} else {
				_gl.deleteFramebuffer( renderTargetProperties['__webglFramebuffer'] );
			}

      gl.deleteFramebuffer(renderTargetProperties["__webglFramebuffer"]);
      if (renderTargetProperties["__webglDepthbuffer"] != null) {
        gl.deleteRenderbuffer(renderTargetProperties["__webglDepthbuffer"]);
      }
      if (renderTargetProperties["__webglMultisampledFramebuffer"] != null) {
        gl.deleteFramebuffer(renderTargetProperties["__webglMultisampledFramebuffer"]);
      }
      if (renderTargetProperties["__webglColorRenderbuffer"] != null) {
				for (int i = 0; i < renderTargetProperties['__webglColorRenderbuffer'].length; i ++ ) {
					if ( renderTargetProperties['__webglColorRenderbuffer'][ i ] != null) _gl.deleteRenderbuffer( renderTargetProperties['__webglColorRenderbuffer'][ i ] );
				}
      }
      if (renderTargetProperties["__webglDepthRenderbuffer"] != null) {
        gl.deleteRenderbuffer(renderTargetProperties["__webglDepthRenderbuffer"]);
      }
    }

    final textures = renderTarget.textures;
    for (int i = 0, il = textures.length; i < il; i++) {
      final attachmentProperties = properties.get(textures[i]);

      if (attachmentProperties["__webglTexture"] != null) {
        gl.deleteTexture(attachmentProperties["__webglTexture"]);

        info.memory["textures"] = info.memory["textures"]! - 1;
      }

      properties.remove(textures[i]);
    }

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
    array.add(texture.wrapR);
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
    array.add(texture.colorSpace);

    return array.join();
  }

  void setTexture2D(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture is VideoTexture) updateVideoTexture(texture);

    if (!texture.isRenderTargetTexture && texture.version > 0 && textureProperties["__version"] != texture.version) {
      final image = texture.image;
      if (image == null) {
        console.warning('WebGLRenderer: Texture marked for update but image is null');
      } 
      else if (image.complete == false) {
        console.warning('WebGLRenderer: Texture marked for update but image is incomplete');
      } 
      else {
        uploadTexture(textureProperties, texture, slot);
        return;
      }
    }
    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(WebGL.TEXTURE_2D, textureProperties["__webglTexture"]);
  }

  void setTexture2DArray(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadTexture(textureProperties, texture, slot);
      return;
    }
    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(WebGL.TEXTURE_2D_ARRAY, textureProperties["__webglTexture"]);
  }

  void setTexture3D(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadTexture(textureProperties, texture, slot);
      return;
    }
    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(WebGL.TEXTURE_3D, textureProperties["__webglTexture"]);
  }

  void setTextureCube(Texture texture, int slot) {
    final textureProperties = properties.get(texture);

    if (texture.version > 0 && textureProperties["__version"] != texture.version) {
      uploadCubeTexture(textureProperties, texture, slot);
      return;
    }

    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(WebGL.TEXTURE_CUBE_MAP, textureProperties["__webglTexture"]);
  }

  void setTextureParameters(textureType, Texture texture, [supportsMips]) {
		if ( texture.type == FloatType && !extensions.has( 'OES_texture_float_linear' ) &&
			( texture.magFilter == LinearFilter || texture.magFilter == LinearMipmapNearestFilter || texture.magFilter == NearestMipmapLinearFilter || texture.magFilter == LinearMipmapLinearFilter ||
			texture.minFilter == LinearFilter || texture.minFilter == LinearMipmapNearestFilter || texture.minFilter == NearestMipmapLinearFilter || texture.minFilter == LinearMipmapLinearFilter ) ) {
			console.warning( 'THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device.' );
		}

		_gl.texParameteri( textureType, WebGL.TEXTURE_WRAP_S, wrappingToGL[ texture.wrapS ]! );
		_gl.texParameteri( textureType, WebGL.TEXTURE_WRAP_T, wrappingToGL[ texture.wrapT ]! );

		if ( textureType == WebGL.TEXTURE_3D || textureType == WebGL.TEXTURE_2D_ARRAY ) {
			_gl.texParameteri( textureType, WebGL.TEXTURE_WRAP_R, wrappingToGL[ texture.wrapR ]! );
		}

		_gl.texParameteri( textureType, WebGL.TEXTURE_MAG_FILTER, filterToGL[ texture.magFilter ]! );
		_gl.texParameteri( textureType, WebGL.TEXTURE_MIN_FILTER, filterToGL[ texture.minFilter ]! );

		if (texture is DepthTexture && texture.compareFunction != null) {
			_gl.texParameteri( textureType, WebGL.TEXTURE_COMPARE_MODE, WebGL.COMPARE_REF_TO_TEXTURE );
			_gl.texParameteri( textureType, WebGL.TEXTURE_COMPARE_FUNC, compareToGL[ texture.compareFunction ]! );
		}

		if ( extensions.has( 'EXT_texture_filter_anisotropic' )) {
			if ( texture.magFilter == NearestFilter ) return;
			if ( texture.minFilter != NearestMipmapLinearFilter && texture.minFilter != LinearMipmapLinearFilter ) return;
			if ( texture.type == FloatType && !extensions.has( 'OES_texture_float_linear' )) return; // verify extension

			if ( texture.anisotropy > 1 || properties.get( texture )['__currentAnisotropy'] != null) {
				final extension = extensions.get( 'EXT_texture_filter_anisotropic' );
        if (kIsWeb && !kIsWasm) {
          gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT,math.min(texture.anisotropy, capabilities.getMaxAnisotropy()).toDouble());
        } 
        else {
          gl.texParameterf(textureType, WebGL.TEXTURE_MAX_ANISOTROPY_EXT,math.min(texture.anisotropy, capabilities.getMaxAnisotropy()).toDouble());
        }				
        properties.get( texture )['__currentAnisotropy'] = texture.anisotropy;
      }
    }
  }

  bool initTexture(Map<String, dynamic> textureProperties, Texture texture) {
    bool forceUpload = false;

    if (textureProperties["__webglInit"] != true) {
      textureProperties["__webglInit"] = true;

      texture.addEventListener('dispose', onTextureDispose);
    }

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

	int getRow(int index, num rowLength, int componentStride ) {
		return ( ( index / componentStride ).floor() / rowLength ).floor();
	}

	void updateTexture(Texture texture, ImageElement image, int glFormat, int glType ) {
		int componentStride = 4; // only RGBA supported
		final updateRanges = texture.updateRanges;

		if ( updateRanges.length == 0 ) {
			state.texSubImage2D( WebGL.TEXTURE_2D, 0, 0, 0, image.width, image.height, glFormat, glType, image.data );
		} 
    else {

			// Before applying update ranges, we merge any adjacent / overlapping
			// ranges to reduce load on `gl.texSubImage2D`. Empirically, this has led
			// to performance improvements for applications which make heavy use of
			// update ranges. Likely due to GPU command overhead.
			//
			// Note that to reduce garbage collection between frames, we merge the
			// update ranges in-place. This is safe because this method will clear the
			// update ranges once updated.

			updateRanges.sort( ( a, b ) => a.start - b.start );

			// To merge the update ranges in-place, we work from left to right in the
			// existing updateRanges array, merging ranges. This may result in a final
			// array which is smaller than the original. This index tracks the last
			// index representing a merged range, any data after this index can be
			// trimmed once the merge algorithm is completed.
			int mergeIndex = 0;

			for (int i = 1; i < updateRanges.length; i ++ ) {
				final previousRange = updateRanges[ mergeIndex ];
				final range = updateRanges[ i ];

				// Only merge if in the same row and overlapping/adjacent
				final previousEnd = previousRange.start + previousRange.count;
				final currentRow = getRow( range.start, image.width, componentStride );
				final previousRow = getRow( previousRange.start, image.width, componentStride );

				// We add one here to merge adjacent ranges. This is safe because ranges
				// operate over positive integers.
				if (
					range.start <= previousEnd + 1 &&
					currentRow == previousRow &&
					getRow( range.start + range.count - 1, image.width, componentStride ) == currentRow // ensure range doesn't spill
				) {

					previousRange.count = math.max(
						previousRange.count,
						range.start + range.count - previousRange.start
					);

				} else {
					++ mergeIndex;
					updateRanges[ mergeIndex ] = range;
				}
			}

			// Trim the array to only contain the merged ranges.
			updateRanges.length = mergeIndex + 1;

			final currentUnpackRowLen = _gl.getParameter( WebGL.UNPACK_ROW_LENGTH );
			final currentUnpackSkipPixels = _gl.getParameter( WebGL.UNPACK_SKIP_PIXELS );
			final currentUnpackSkipRows = _gl.getParameter( WebGL.UNPACK_SKIP_ROWS );

			_gl.pixelStorei( WebGL.UNPACK_ROW_LENGTH, image.width.toInt() );

			for (int i = 0, l = updateRanges.length; i < l; i ++ ) {
				final range = updateRanges[ i ];

				final pixelStart = ( range.start / componentStride ).floor();
				final pixelCount = ( range.count / componentStride ).ceil();

				final x = (pixelStart % image.width).toInt();
				final y = ( pixelStart / image.width ).floor();

				// Assumes update ranges refer to contiguous memory
				final width = pixelCount;
				final height = 1;

				_gl.pixelStorei( WebGL.UNPACK_SKIP_PIXELS, x );
				_gl.pixelStorei( WebGL.UNPACK_SKIP_ROWS, y );

				state.texSubImage2D( WebGL.TEXTURE_2D, 0, x, y, width, height, glFormat, glType, image.data );
			}

			texture.clearUpdateRanges();

			_gl.pixelStorei( WebGL.UNPACK_ROW_LENGTH, currentUnpackRowLen );
			_gl.pixelStorei( WebGL.UNPACK_SKIP_PIXELS, currentUnpackSkipPixels );
			_gl.pixelStorei( WebGL.UNPACK_SKIP_ROWS, currentUnpackSkipRows );
		}
	}

  void uploadTexture(Map<String, dynamic> textureProperties, Texture texture, int slot) {
    dynamic textureType = WebGL.TEXTURE_2D;

    if (texture is DataArrayTexture) textureType = WebGL.TEXTURE_2D_ARRAY;
    if (texture is Data3DTexture) textureType = WebGL.TEXTURE_3D;

    final forceUpload = initTexture(textureProperties, texture);
    final source = texture.source;

    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(textureType, textureProperties["__webglTexture"]);

    if (source.version != source.currentVersion || forceUpload) {

      _gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, texture.unpackAlignment);
      if (kIsWeb) {
        _gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
        _gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
        _gl.pixelStorei(WebGL.UNPACK_COLORSPACE_CONVERSION_WEBGL, WebGL.NONE);
      }

      dynamic image = texture.image;//resizeImage(texture.image, needsPowerOfTwo, false, maxTextureSize);
      image = verifyColorSpace(texture, image);

      final int glFormat = utils.convert(texture.format, texture.colorSpace);
      int glType = utils.convert(texture.type);
      int glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, texture is VideoTexture);

      setTextureParameters(textureType, texture);

      dynamic mipmap;
      final mipmaps = texture.mipmaps;

      final useTexStorage = (isWebGL2 && texture is! VideoTexture);
      final allocateMemory = (textureProperties["__version"] == null) || (forceUpload == true);
      final dataReady = source.dataReady;
      final levels = getMipLevels(texture, image);
      
      if (texture is DepthTexture) {
				glInternalFormat = getInternalDepthFormat( texture.format == DepthStencilFormat, texture.type );
				if ( allocateMemory ) {
					if ( useTexStorage ) {
						state.texStorage2D( WebGL.TEXTURE_2D, 1, glInternalFormat, image.width, image.height );
					} else {
						state.texImage2D( WebGL.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, null );
					}
				}
      } 
      else if (texture is DataTexture) {
        // use manually created mipmaps if available
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels

        if (mipmaps.isNotEmpty) {
          if (useTexStorage && allocateMemory) {
            state.texStorage2D(WebGL.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
          }

          for (int i = 0, il = mipmaps.length; i < il; i++) {
            mipmap = mipmaps[i];
            if (useTexStorage && dataReady) {
              state.texSubImage2D(WebGL.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data);
            } 
            else {
              state.texImage2D(WebGL.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
            }
          }

          texture.generateMipmaps = false;
        } 
        else {

          if (useTexStorage) {
            if (allocateMemory) {
              state.texStorage2D(WebGL.TEXTURE_2D, levels, glInternalFormat, image.width.toInt(), image.height.toInt());
            }
						if ( dataReady ) {
							updateTexture( texture, image, glFormat, glType );
						}          
          } 
          else {
            state.texImage2D(WebGL.TEXTURE_2D, 0, glInternalFormat, image.width, image.height, 0, glFormat, glType, image.data);
          }
        }
      } 
      else if (texture is CompressedTexture) {
				if ( texture is CompressedArrayTexture ) {
					if ( useTexStorage && allocateMemory ) {
						state.texStorage3D( WebGL.TEXTURE_2D_ARRAY, levels, glInternalFormat, mipmaps[ 0 ].width, mipmaps[ 0 ].height, image.depth );
					}

					for ( int i = 0, il = mipmaps.length; i < il; i ++ ) {
						mipmap = mipmaps[ i ];
						if ( texture.format != RGBAFormat ) {
							if ( glFormat > 0 ) {
								if ( useTexStorage && dataReady) {
                  if ( texture.layerUpdates.isNotEmpty ) {
                    final layerByteLength = TextureUtils.getByteLength( mipmap.width, mipmap.height, texture.format, texture.type );
                    for ( final layerIndex in texture.layerUpdates ) {
                      final layerData = mipmap.data.subarray(
                        layerIndex * layerByteLength / mipmap.data.BYTES_PER_ELEMENT,
                        ( layerIndex + 1 ) * layerByteLength / mipmap.data.BYTES_PER_ELEMENT
                      );
                      state.compressedTexSubImage3D( WebGL.TEXTURE_2D_ARRAY, i, 0, 0, layerIndex, mipmap.width, mipmap.height, 1, glFormat, layerData );
                    }
                    texture.clearLayerUpdates();
                  } else {
                    state.compressedTexSubImage3D( WebGL.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, mipmap.data );
                  }
								} else {
									state.compressedTexImage3D( WebGL.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, mipmap.data);//, 0, 0 );
								}
							} else {
								console.warning( 'THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()' );
							}
						} else {
							if ( useTexStorage && dataReady) {
								state.texSubImage3D( WebGL.TEXTURE_2D_ARRAY, i, 0, 0, 0, mipmap.width, mipmap.height, image.depth, glFormat, glType, mipmap.data );
							} else {
								state.texImage3D( WebGL.TEXTURE_2D_ARRAY, i, glInternalFormat, mipmap.width, mipmap.height, image.depth, 0, glFormat, glType, mipmap.data );
							}
						}
					}
				} else {
					if ( useTexStorage && allocateMemory ) {
						state.texStorage2D( WebGL.TEXTURE_2D, levels, glInternalFormat, mipmaps[ 0 ].width, mipmaps[ 0 ].height );
					}

					for (int i = 0, il = mipmaps.length; i < il; i ++ ) {
						mipmap = mipmaps[ i ];

						if ( texture.format != RGBAFormat ) {
							if ( glFormat > 0 ) {
								if ( useTexStorage && dataReady) {
									state.compressedTexSubImage2D( WebGL.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data );
								} else {
									state.compressedTexImage2D( WebGL.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data );
								}
							} else {
								console.warning( 'THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()' );
							}
						} else {
							if ( useTexStorage && dataReady) {
								state.texSubImage2D( WebGL.TEXTURE_2D, i, 0, 0, mipmap.width, mipmap.height, glFormat, glType, mipmap.data );
							} else {
								state.texImage2D( WebGL.TEXTURE_2D, i, glInternalFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data );
							}
						}
					}
				}
      }
      else if (texture is DataArrayTexture) {
        if (useTexStorage) {
          if (allocateMemory) {
            state.texStorage3D(WebGL.TEXTURE_2D_ARRAY, levels, glInternalFormat, image.width, image.height, image.depth);
          }
          if(dataReady){
            if ( texture.layerUpdates.isNotEmpty ) {
              final layerByteLength = TextureUtils.getByteLength( image.width, image.height, texture.format, texture.type );
              for ( final layerIndex in texture.layerUpdates ) {
                final layerData = image.data.subarray(
                  layerIndex * layerByteLength / image.data.BYTES_PER_ELEMENT,
                  ( layerIndex + 1 ) * layerByteLength / image.data.BYTES_PER_ELEMENT
                );
                state.texSubImage3D( WebGL.TEXTURE_2D_ARRAY, 0, 0, 0, layerIndex, image.width, image.height, 1, glFormat, glType, layerData );
              }

              texture.clearLayerUpdates();
            } 
            else {
              state.texSubImage3D( WebGL.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data );
            }
          }
        } else {
          state.texImage3D(WebGL.TEXTURE_2D_ARRAY, 0, glInternalFormat, image.width, image.height, image.depth, 0,
              glFormat, glType, image.data);
        }
      } 
      else if (texture is Data3DTexture) {
        if (useTexStorage) {
          if (allocateMemory) {
            state.texStorage3D(WebGL.TEXTURE_3D, levels, glInternalFormat, image.width, image.height, image.depth);
          }
          if(dataReady){
            state.texSubImage3D(WebGL.TEXTURE_3D, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
          }
        } else {
          state.texImage3D(WebGL.TEXTURE_3D, 0, glInternalFormat, image.width, image.height, image.depth, 0, glFormat,glType, image.data);
        }
      } 
      else if (texture is FramebufferTexture) {
        if (allocateMemory) {
          if (useTexStorage) {
            state.texStorage2D(WebGL.TEXTURE_2D, levels, glInternalFormat, image.width, image.height);
          } else{
            int width = image.width, height = image.height;

            for (int i = 0; i < levels; i++) {
              state.texImage2D(WebGL.TEXTURE_2D, i, glInternalFormat, width, height, 0, glFormat, glType, null);

              width >>= 1;
              height >>= 1;
            }
          }
        }
      } 
      else {
        // regular Texture (image, video, canvas)

        // use manually created mipmaps if available
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels

        if (mipmaps.isNotEmpty) {
          if (useTexStorage && allocateMemory) {
            state.texStorage2D(WebGL.TEXTURE_2D, levels, glInternalFormat, mipmaps[0].width, mipmaps[0].height);
          }

          for (int i = 0, il = mipmaps.length; i < il; i++) {
            mipmap = mipmaps[i];
            if (useTexStorage && dataReady) {
              state.texSubImage2DIf(WebGL.TEXTURE_2D, i, 0, 0, glFormat, glType, mipmap);
            } 
            else {
              state.texImage2DIf(WebGL.TEXTURE_2D, i, glInternalFormat, glFormat, glType, mipmap);
            }
          }

          texture.generateMipmaps = false;
        } 
        else {
          if (useTexStorage) {
            if (allocateMemory) {
              state.texStorage2D(WebGL.TEXTURE_2D, levels, glInternalFormat, image.width.toInt(), image.height.toInt());
            }
            if(dataReady){
              state.texSubImage2DIf(WebGL.TEXTURE_2D, 0, 0, 0, glFormat, glType, image);
            }
          } 
          else {
            state.texImage2DIf(WebGL.TEXTURE_2D, 0, glInternalFormat, glFormat, glType, image);
          }
        }
      }

      if (textureNeedsGenerateMipmaps(texture)) {
        generateMipmap(textureType);
      }

      source.currentVersion = source.version;

      if (texture.onUpdate != null) texture.onUpdate!(texture);
    }

    textureProperties["__version"] = texture.version;
  }

  void uploadCubeTexture(Map<String, dynamic> textureProperties, Texture texture, int slot) {
    if (texture.image.length != 6) return;

    final forceUpload = initTexture(textureProperties, texture);
    final source = texture.source;

    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(WebGL.TEXTURE_CUBE_MAP, textureProperties['__webglTexture']);

    if (source.version != source.currentVersion || forceUpload) {
      state.activeTexture(WebGL.TEXTURE0 + slot);


      _gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, texture.unpackAlignment);
      if (kIsWeb) {
        final workingPrimaries = ColorManagement.getPrimaries( ColorManagement.workingColorSpace );
        final texturePrimaries = texture.colorSpace == NoColorSpace ? null : ColorManagement.getPrimaries( ColorSpace.fromString(texture.colorSpace) );
        final unpackConversion = texture.colorSpace == NoColorSpace || workingPrimaries == texturePrimaries ? WebGL.NONE : WebGL.BROWSER_DEFAULT_WEBGL;

        _gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
        _gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
        _gl.pixelStorei(WebGL.UNPACK_COLORSPACE_CONVERSION_WEBGL, unpackConversion);
      }

      final isCompressed = (texture.isCompressedTexture || texture is CompressedTexture);
      final isDataTexture = (texture.image[0] != null && texture is DataTexture);
      final isCubeTexture = (texture.image[0] != null && texture is CubeTexture);
      print('here1');
      final cubeImage = [];

      for (int i = 0; i < 6; i++) {
        if (!isCompressed && !isDataTexture) {
          cubeImage.add(texture.image[i]);
        } 
        else {
          print('here2');
          cubeImage.add(isDataTexture ? texture.image[i].image : texture.image[i]);
        }

        cubeImage[i] = verifyColorSpace(texture, cubeImage[i]);
      }

      final image = cubeImage[0],
          glFormat = utils.convert(texture.format, texture.colorSpace),
          glType = utils.convert(texture.type),
          glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace);

      final useTexStorage = (isWebGL2 && texture is! VideoTexture);
      final allocateMemory = (textureProperties['__version'] == null);
      final dataReady = source.dataReady;
      int levels = getMipLevels(texture, image);

      setTextureParameters(WebGL.TEXTURE_CUBE_MAP, texture);

      dynamic mipmaps;

      if (isCompressed) {
        if (useTexStorage && allocateMemory) {
          state.texStorage2D(WebGL.TEXTURE_CUBE_MAP, levels, glInternalFormat, image.width, image.height);
        }

        for (int i = 0; i < 6; i++) {
          mipmaps = cubeImage[i].mipmaps;

          for (int j = 0; j < mipmaps.length; j++) {
            final mipmap = mipmaps[j];

            if (texture.format != RGBAFormat) {
              if (glFormat != null) {
                if (useTexStorage && dataReady) {
                  state.compressedTexSubImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat, mipmap.data);
                } 
                else {
                  state.compressedTexImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width, mipmap.height, 0, mipmap.data);
                }
              } 
              else {
                console.warning('WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()');
              }
            } 
            else {
              if (useTexStorage && dataReady) {
                state.texSubImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, 0, 0, mipmap.width, mipmap.height, glFormat,glType, mipmap.data);
              } 
              else {
                state.texImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glInternalFormat, mipmap.width, mipmap.height,0, glFormat, glType, mipmap.data);
              }
            }
          }
        }
      } 
      else {
        mipmaps = texture.mipmaps;

        if (useTexStorage && allocateMemory) {
          // TODO: Uniformly handle mipmap definitions
          // Normal textures and compressed cube textures define base level + mips with their mipmap array
          // Uncompressed cube textures use their mipmap array only for mips (no base level)

          if (mipmaps.length > 0) levels++;

          state.texStorage2D(WebGL.TEXTURE_CUBE_MAP, levels, glInternalFormat, cubeImage[0].width, cubeImage[0].height);
        }

        for (int i = 0; i < 6; i++) {
          if (isDataTexture || isCubeTexture) {
            if (useTexStorage && dataReady) {
              if( kIsWeb ){
                state.texSubImage2DNoSize(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, glFormat, glType, cubeImage[i].data);
              }
              else{
                state.texSubImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, cubeImage[i].width, cubeImage[i].height, glFormat, glType, cubeImage[i].data);
              }
            } 
            else {
              if( kIsWeb ){
                state.texImage2DNoSize(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, glFormat, glType, cubeImage[i].data);
              }
              else{
                state.texImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, cubeImage[i].width,cubeImage[i].height, 0, glFormat, glType, cubeImage[i].data);
              }
            }

            for (int j = 0; j < mipmaps.length; j++) {
              final mipmap = mipmaps[j];
              final mipmapImage = mipmap.image[i].image;

              if (useTexStorage && dataReady) {
                state.texSubImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, mipmapImage.width,mipmapImage.height, glFormat, glType, mipmapImage.data);
              } 
              else {
                state.texImage2D(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, mipmapImage.width,mipmapImage.height, 0, glFormat, glType, mipmapImage.data);
              }
            }
          } 
          else {
            if (useTexStorage && dataReady) {
              state.texSubImage2DIf(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, glFormat, glType, cubeImage[i]);
            } 
            else {
              state.texImage2DIf(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glInternalFormat, glFormat, glType, cubeImage[i]);
            }

            for (int j = 0; j < mipmaps.length; j++) {
              final mipmap = mipmaps[j];

              if (useTexStorage && dataReady) {
                state.texSubImage2DIf(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, 0, 0, glFormat, glType, mipmap.image[i]);
              } 
              else {
                state.texImage2DIf(WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, j + 1, glInternalFormat, glFormat, glType, mipmap.image[i]);
              }
            }
          }
        }
      }

      if (textureNeedsGenerateMipmaps(texture)) {
        // We assume images for cube map have the same size.
        generateMipmap(WebGL.TEXTURE_CUBE_MAP);
      }

      source.currentVersion = source.version;

      if (texture.onUpdate != null) texture.onUpdate!(texture);
    }

    textureProperties['__version'] = texture.version;
  }

  // Render targets

  // Setup storage for target texture and bind it to correct framebuffer
  void setupFrameBufferTexture(framebuffer, RenderTarget renderTarget, Texture texture, attachment, textureTarget, level ) {
		final glFormat = utils.convert( texture.format, texture.colorSpace );
		final glType = utils.convert( texture.type );
		final glInternalFormat = getInternalFormat( texture.internalFormat, glFormat, glType, texture.colorSpace );
		final renderTargetProperties = properties.get( renderTarget );
		final textureProperties = properties.get( texture );

		textureProperties['__renderTarget'] = renderTarget;

		if (renderTargetProperties['__hasExternalTextures'] == null) {

			final width = math.max( 1, renderTarget.width >> level );
			final height = math.max( 1, renderTarget.height >> level );

			if ( textureTarget == WebGL.TEXTURE_3D || textureTarget == WebGL.TEXTURE_2D_ARRAY ) {
				state.texImage3D( textureTarget, level, glInternalFormat, width, height, renderTarget.depth, 0, glFormat, glType, null );
			} else {
				state.texImage2D( textureTarget, level, glInternalFormat, width, height, 0, glFormat, glType, null );
			}
		}

		state.bindFramebuffer( WebGL.FRAMEBUFFER, framebuffer );

		if ( useMultisampledRTT( renderTarget ) && multisampledRTTExt != null) {
			multisampledRTTExt.framebufferTexture2DMultisampleEXT( WebGL.FRAMEBUFFER, attachment, textureTarget, textureProperties['__webglTexture'], 0, getRenderTargetSamples( renderTarget ) );
		} 
    else if ( textureTarget == WebGL.TEXTURE_2D || ( textureTarget >= WebGL.TEXTURE_CUBE_MAP_POSITIVE_X && textureTarget <= WebGL.TEXTURE_CUBE_MAP_NEGATIVE_Z ) ) { // see #24753
			_gl.framebufferTexture2D( WebGL.FRAMEBUFFER, attachment, textureTarget, textureProperties['__webglTexture'], level );
		}

		state.bindFramebuffer( WebGL.FRAMEBUFFER, null );
  }

  // Setup storage for internal depth/stencil buffers and bind to correct framebuffer
  void setupRenderBufferStorage(Renderbuffer renderbuffer, RenderTarget renderTarget, bool isMultisample) {
		_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderbuffer );

		if ( renderTarget.depthBuffer ) {
			// retrieve the depth attachment types
			final depthTexture = renderTarget.depthTexture;
			final depthType = depthTexture != null && depthTexture.isDepthTexture ? depthTexture.type : null;
			final glInternalFormat = getInternalDepthFormat( renderTarget.stencilBuffer, depthType );
			final glAttachmentType = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;

			// set up the attachment
			final samples = getRenderTargetSamples( renderTarget );
			final isUseMultisampledRTT = useMultisampledRTT( renderTarget );
			if ( isUseMultisampledRTT && multisampledRTTExt != null) {
				multisampledRTTExt.renderbufferStorageMultisampleEXT( WebGL.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );
			} 
      else if ( isMultisample ) {
				_gl.renderbufferStorageMultisample( WebGL.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );
			} else {
				_gl.renderbufferStorage( WebGL.RENDERBUFFER, glInternalFormat, renderTarget.width, renderTarget.height );
			}

			_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, glAttachmentType, WebGL.RENDERBUFFER, renderbuffer );
		} else {
			final textures = renderTarget.textures;

			for (int i = 0; i < textures.length; i ++ ) {
				final texture = textures[ i ];

				final glFormat = utils.convert( texture.format, texture.colorSpace );
				final glType = utils.convert( texture.type );
				final glInternalFormat = getInternalFormat( texture.internalFormat, glFormat, glType, texture.colorSpace );
				final samples = getRenderTargetSamples( renderTarget );

				if ( isMultisample && useMultisampledRTT( renderTarget ) == false ) {
					_gl.renderbufferStorageMultisample( WebGL.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );
				} else if ( useMultisampledRTT( renderTarget ) ) {
					multisampledRTTExt.renderbufferStorageMultisampleEXT( WebGL.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );
				} else {
					_gl.renderbufferStorage( WebGL.RENDERBUFFER, glInternalFormat, renderTarget.width, renderTarget.height );
				}
			}
		}

		_gl.bindRenderbuffer( WebGL.RENDERBUFFER, null );
  }


  // Setup resources for a Depth Texture for a FBO (needs an extension)
  void setupDepthTexture(framebuffer, RenderTarget renderTarget) {
		final renderTargetProperties = properties.get( renderTarget );
		final isCube = renderTarget is WebGLCubeRenderTarget;

		// if the bound depth texture has changed
		if ( renderTargetProperties['__boundDepthTexture'] != renderTarget.depthTexture ) {
			// fire the dispose event to get rid of stored state associated with the previously bound depth buffer
			final depthTexture = renderTarget.depthTexture;
			if ( renderTargetProperties['__depthDisposeCallback'] != null) {
				renderTargetProperties['__depthDisposeCallback']();
			}

			// set up dispose listeners to track when the currently attached buffer is implicitly unbound
			if ( depthTexture != null) {
				disposeEvent(){
					renderTargetProperties.remove('__boundDepthTexture');//delete renderTargetProperties.__boundDepthTexture;
					renderTargetProperties.remove('__depthDisposeCallback');//delete renderTargetProperties.__depthDisposeCallback;
					depthTexture.removeEventListener( 'dispose', disposeEvent );
				};

				depthTexture.addEventListener( 'dispose', disposeEvent );
				renderTargetProperties['__depthDisposeCallback'] = disposeEvent;
			}
			renderTargetProperties['__boundDepthTexture'] = depthTexture;
		}

		if ( renderTarget.depthTexture != null && ! renderTargetProperties['__autoAllocateDepthBuffer'] ) {
			if ( isCube ) throw( 'target.depthTexture not supported in Cube render targets' );
			setupDepthTexture( renderTargetProperties['__webglFramebuffer'], renderTarget );
		} else {
			if ( isCube ) {
				renderTargetProperties['__webglDepthbuffer'] = [];

				for (int i = 0; i < 6; i ++ ) {
					state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'][ i ] );

					if ( renderTargetProperties['__webglDepthbuffer'][ i ] == null ) {
						renderTargetProperties['__webglDepthbuffer'][ i ] = _gl.createRenderbuffer();
						setupRenderBufferStorage( renderTargetProperties['__webglDepthbuffer'][ i ], renderTarget, false );
					} else {
						// attach buffer if it's been created already
						final glAttachmentType = renderTarget.stencilBuffer? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
						final renderbuffer = renderTargetProperties['__webglDepthbuffer'][ i ];
						_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderbuffer );
						_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, glAttachmentType, WebGL.RENDERBUFFER, renderbuffer );
					}
				}
			} else {
				state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'] );

				if ( renderTargetProperties['__webglDepthbuffer'] == null ) {
					renderTargetProperties['__webglDepthbuffer'] = _gl.createRenderbuffer();
					setupRenderBufferStorage( renderTargetProperties['__webglDepthbuffer'], renderTarget, false );
				} else {
					// attach buffer if it's been created already
					final glAttachmentType = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
					final renderbuffer = renderTargetProperties['__webglDepthbuffer'];
					_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderbuffer );
					_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, glAttachmentType, WebGL.RENDERBUFFER, renderbuffer );
				}
			}
		}

		state.bindFramebuffer( WebGL.FRAMEBUFFER, null );
  }

  // Setup GL resources for a non-texture depth buffer
  void setupDepthRenderbuffer(RenderTarget renderTarget) {
		final renderTargetProperties = properties.get( renderTarget );
		final isCube = ( renderTarget is WebGLCubeRenderTarget == true );

		// if the bound depth texture has changed
		if ( renderTargetProperties['__boundDepthTexture'] != renderTarget.depthTexture ) {
			// fire the dispose event to get rid of stored state associated with the previously bound depth buffer
			final depthTexture = renderTarget.depthTexture;
			if ( renderTargetProperties['__depthDisposeCallback'] ) {
				renderTargetProperties['__depthDisposeCallback']();
			}

			// set up dispose listeners to track when the currently attached buffer is implicitly unbound
			if ( depthTexture != null) {
				disposeEvent(){
					renderTargetProperties.remove('__boundDepthTexture');//delete renderTargetProperties.__boundDepthTexture;
					renderTargetProperties.remove('__depthDisposeCallback');//delete renderTargetProperties.__depthDisposeCallback;
					depthTexture.removeEventListener( 'dispose', disposeEvent );
				}
				depthTexture.addEventListener( 'dispose', disposeEvent );
				renderTargetProperties['__depthDisposeCallback'] = disposeEvent;
			}
			renderTargetProperties['__boundDepthTexture'] = depthTexture;
		}

		if ( renderTarget.depthTexture != null && !renderTargetProperties['__autoAllocateDepthBuffer'] ) {
			if ( isCube ) throw( 'target.depthTexture not supported in Cube render targets' );
			setupDepthTexture( renderTargetProperties['__webglFramebuffer'], renderTarget );
		} else {
			if (isCube) {
				renderTargetProperties['__webglDepthbuffer'] = [];

				for (int i = 0; i < 6; i++) {
					state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'][ i ] );

					if (renderTargetProperties['__webglDepthbuffer'].length <= i || renderTargetProperties['__webglDepthbuffer'][ i ] == null ) {
						(renderTargetProperties['__webglDepthbuffer'] as List).listSetter(i,_gl.createRenderbuffer());// [ i ] = _gl.createRenderbuffer();
						setupRenderBufferStorage( renderTargetProperties['__webglDepthbuffer'][ i ], renderTarget, false );
					} else {
						// attach buffer if it's been created already
						final glAttachmentType = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
						final renderbuffer = renderTargetProperties['__webglDepthbuffer'][ i ];
						_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderbuffer );
						_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, glAttachmentType, WebGL.RENDERBUFFER, renderbuffer );
					}
				}
			} else {
				state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'] );

				if ( renderTargetProperties['__webglDepthbuffer'] == null ) {
					renderTargetProperties['__webglDepthbuffer'] = _gl.createRenderbuffer();
					setupRenderBufferStorage( renderTargetProperties['__webglDepthbuffer'], renderTarget, false );
				} else {
					// attach buffer if it's been created already
					final glAttachmentType = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
					final renderbuffer = renderTargetProperties['__webglDepthbuffer'];
					_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderbuffer );
					_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, glAttachmentType, WebGL.RENDERBUFFER, renderbuffer );
				}
			}
		}

		state.bindFramebuffer( WebGL.FRAMEBUFFER, null );
  }

  // rebind framebuffer with external textures
  void rebindTextures(RenderTarget renderTarget, colorTexture, depthTexture) {
    final renderTargetProperties = properties.get(renderTarget);

    if (colorTexture != null) {
      setupFrameBufferTexture(renderTargetProperties["__webglFramebuffer"], renderTarget, renderTarget.texture,
          WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D,0);
    }

    if (depthTexture != null) {
      setupDepthRenderbuffer(renderTarget);
    }
  }

  // Set up GL resources for the render target
  void setupRenderTarget(RenderTarget renderTarget) {
		final texture = renderTarget.texture;

		final renderTargetProperties = properties.get( renderTarget );
		final textureProperties = properties.get( texture );

		renderTarget.addEventListener( 'dispose', onRenderTargetDispose );

		final textures = renderTarget.textures;

		final isCube = renderTarget is WebGLCubeRenderTarget;
		final isMultipleRenderTargets = ( textures.length > 1 );

		if ( ! isMultipleRenderTargets ) {
			if ( textureProperties['__webglTexture'] == null ) {
				textureProperties['__webglTexture'] = _gl.createTexture();
			}

			textureProperties['__version'] = texture.version;
			info.memory['textures'] = info.memory['textures']! + 1;
		}

		// Setup framebuffer

		if ( isCube ) {
			renderTargetProperties['__webglFramebuffer'] = [];
			for ( int i = 0; i < 6; i ++ ) {
				if (texture.mipmaps.isNotEmpty ) {
					renderTargetProperties['__webglFramebuffer'][ i ] = [];
					for ( int level = 0; level < texture.mipmaps.length; level ++ ) {
						renderTargetProperties['__webglFramebuffer'][ i ][ level ] = _gl.createFramebuffer();
					}
				} else {
					(renderTargetProperties['__webglFramebuffer'] as List).listSetter(i, _gl.createFramebuffer());
				}
			}
		} else {
			if ( texture.mipmaps.isNotEmpty ) {
				renderTargetProperties['__webglFramebuffer'] = [];
				for ( int level = 0; level < texture.mipmaps.length; level ++ ) {
					renderTargetProperties['__webglFramebuffer'][ level ] = _gl.createFramebuffer();
				}
			} else {
				renderTargetProperties['__webglFramebuffer'] = _gl.createFramebuffer();
			}

			if ( isMultipleRenderTargets ) {
				for ( int i = 0, il = textures.length; i < il; i ++ ) {
					final attachmentProperties = properties.get( textures[ i ] );
					if ( attachmentProperties['__webglTexture'] == null ) {
						attachmentProperties['__webglTexture'] = _gl.createTexture();
						info.memory['textures'] = info.memory['textures']! +1;;
					}
				}
			}

			if ( ( renderTarget.samples > 0 ) && useMultisampledRTT( renderTarget ) == false ) {
				renderTargetProperties['__webglMultisampledFramebuffer'] = _gl.createFramebuffer();
				renderTargetProperties['__webglColorRenderbuffer'] = [];

				state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglMultisampledFramebuffer'] );

				for ( int i = 0; i < textures.length; i ++ ) {
					final texture = textures[ i ];
					(renderTargetProperties['__webglColorRenderbuffer'] as List).listSetter(i, _gl.createRenderbuffer());

					_gl.bindRenderbuffer( WebGL.RENDERBUFFER, renderTargetProperties['__webglColorRenderbuffer'][ i ] );

					final glFormat = utils.convert( texture.format, texture.colorSpace );
					final glType = utils.convert( texture.type );
					final glInternalFormat = getInternalFormat( texture.internalFormat, glFormat, glType, texture.colorSpace, renderTarget.isXRRenderTarget == true );
					final samples = getRenderTargetSamples( renderTarget );

					_gl.renderbufferStorageMultisample( WebGL.RENDERBUFFER, samples, glInternalFormat, renderTarget.width, renderTarget.height );
					_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0 + i, WebGL.RENDERBUFFER, renderTargetProperties['__webglColorRenderbuffer'][ i ] );
				}

				_gl.bindRenderbuffer( WebGL.RENDERBUFFER, null );

				if ( renderTarget.depthBuffer ) {
					renderTargetProperties['__webglDepthRenderbuffer'] = _gl.createRenderbuffer();
					setupRenderBufferStorage( renderTargetProperties['__webglDepthRenderbuffer'], renderTarget, true );
				}

				state.bindFramebuffer( WebGL.FRAMEBUFFER, null );
			}
		}

		// Setup color buffer

		if ( isCube ) {
			state.bindTexture( WebGL.TEXTURE_CUBE_MAP, textureProperties['__webglTexture'] );
			setTextureParameters( WebGL.TEXTURE_CUBE_MAP, texture );

			for ( int i = 0; i < 6; i ++ ) {
				if (texture.mipmaps.isNotEmpty ) {
					for ( int level = 0; level < texture.mipmaps.length; level ++ ) {
						setupFrameBufferTexture( renderTargetProperties['__webglFramebuffer'][ i ][ level ], renderTarget, texture, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, level );
					}
				} else {
					setupFrameBufferTexture( renderTargetProperties['__webglFramebuffer'][ i ], renderTarget, texture, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0 );
				}
			}

			if ( textureNeedsGenerateMipmaps( texture ) ) {
				generateMipmap( WebGL.TEXTURE_CUBE_MAP );
			}

			state.unbindTexture();

		} else if ( isMultipleRenderTargets ) {
			for ( int i = 0, il = textures.length; i < il; i ++ ) {
				final attachment = textures[ i ];
				final attachmentProperties = properties.get( attachment );

				state.bindTexture( WebGL.TEXTURE_2D, attachmentProperties['__webglTexture'] );
				setTextureParameters( WebGL.TEXTURE_2D, attachment );
				setupFrameBufferTexture( renderTargetProperties['__webglFramebuffer'], renderTarget, attachment, WebGL.COLOR_ATTACHMENT0 + i, WebGL.TEXTURE_2D, 0 );

				if ( textureNeedsGenerateMipmaps( attachment ) ) {
					generateMipmap( WebGL.TEXTURE_2D );
				}
			}

			state.unbindTexture();
		} else {
			int glTextureType = WebGL.TEXTURE_2D;

			if ( renderTarget is WebGL3DRenderTarget || renderTarget is WebGLArrayRenderTarget ) {
				glTextureType = renderTarget is WebGL3DRenderTarget ? WebGL.TEXTURE_3D : WebGL.TEXTURE_2D_ARRAY;
			}

			state.bindTexture( glTextureType, textureProperties['__webglTexture'] );
			setTextureParameters( glTextureType, texture );

			if (texture.mipmaps.isNotEmpty ) {
				for ( int level = 0; level < texture.mipmaps.length; level ++ ) {
					setupFrameBufferTexture( renderTargetProperties['__webglFramebuffer'][ level ], renderTarget, texture, WebGL.COLOR_ATTACHMENT0, glTextureType, level );
				}
			} else {
				setupFrameBufferTexture( renderTargetProperties['__webglFramebuffer'], renderTarget, texture, WebGL.COLOR_ATTACHMENT0, glTextureType, 0 );
			}

			if ( textureNeedsGenerateMipmaps( texture ) ) {
				generateMipmap( glTextureType );
			}
			state.unbindTexture();
		}


		if ( renderTarget.depthBuffer ) {
			setupDepthRenderbuffer( renderTarget );
		}
  }

  void updateRenderTargetMipmap(RenderTarget renderTarget) {
    final textures = renderTarget.textures;
    for (int i = 0, il = textures.length; i < il; i++) {
      final texture = textures[i];

      if (textureNeedsGenerateMipmaps(texture)) {
        final target = renderTarget is WebGLCubeRenderTarget ? WebGL.TEXTURE_CUBE_MAP : WebGL.TEXTURE_2D;
        final webglTexture = properties.get(texture)["__webglTexture"];

        state.bindTexture(target, webglTexture);
        generateMipmap(target);
        state.bindTexture(target, null);
      }
    }
  }

	final List<int> invalidationArrayRead = [];
	final List<int> invalidationArrayDraw = [];
  void updateMultisampleRenderTarget(RenderTarget renderTarget) {
		if ( renderTarget.samples > 0 ) {
			if ( !useMultisampledRTT( renderTarget )) {
				final textures = renderTarget.textures;
				final width = renderTarget.width;
				final height = renderTarget.height;
				int mask = WebGL.COLOR_BUFFER_BIT;
				final depthStyle = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
				final renderTargetProperties = properties.get( renderTarget );
				final isMultipleRenderTargets = ( textures.length > 1 );

				// If MRT we need to remove FBO attachments
				if ( isMultipleRenderTargets ) {
					for (int i = 0; i < textures.length; i ++ ) {
						state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglMultisampledFramebuffer'] );
						_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0 + i, WebGL.RENDERBUFFER, null );

						state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'] );
						_gl.framebufferTexture2D( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0 + i, WebGL.TEXTURE_2D, null, 0 );
					}
				}

				state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, renderTargetProperties['__webglMultisampledFramebuffer'] );
				state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'] );

				for (int i = 0; i < textures.length; i ++ ) {
					if ( renderTarget.resolveDepthBuffer ) {
						if ( renderTarget.depthBuffer ) mask |= WebGL.DEPTH_BUFFER_BIT;
						if ( renderTarget.stencilBuffer && renderTarget.resolveStencilBuffer ) mask |= WebGL.STENCIL_BUFFER_BIT;
					}

					if ( isMultipleRenderTargets ) {
						_gl.framebufferRenderbuffer( WebGL.READ_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.RENDERBUFFER, renderTargetProperties['__webglColorRenderbuffer'][ i ] );

						final webglTexture = properties.get( textures[ i ] )['__webglTexture'];
						_gl.framebufferTexture2D( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, webglTexture, 0 );
					}

					_gl.blitFramebuffer( 0, 0, width, height, 0, 0, width, height, mask, WebGL.NEAREST );

					if ( supportsInvalidateFramebuffer) {
						invalidationArrayRead.length = 0;
						invalidationArrayDraw.length = 0;

						invalidationArrayRead.add( WebGL.COLOR_ATTACHMENT0 + i );

						if ( renderTarget.depthBuffer && !renderTarget.resolveDepthBuffer) {
							invalidationArrayRead.add( depthStyle );
							invalidationArrayDraw.add( depthStyle );

							_gl.invalidateFramebuffer( WebGL.DRAW_FRAMEBUFFER, invalidationArrayDraw );
						}

						_gl.invalidateFramebuffer( WebGL.READ_FRAMEBUFFER, invalidationArrayRead );
					}
				}

				state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, null );
				state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, null );

				// If MRT since pre-blit we removed the FBO we need to reconstruct the attachments
				if ( isMultipleRenderTargets ) {
					for (int i = 0; i < textures.length; i ++ ) {
						state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglMultisampledFramebuffer'] );
						_gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0 + i, WebGL.RENDERBUFFER, renderTargetProperties['__webglColorRenderbuffer'][ i ] );

						final webglTexture = properties.get( textures[ i ] )['__webglTexture'];

						state.bindFramebuffer( WebGL.FRAMEBUFFER, renderTargetProperties['__webglFramebuffer'] );
						_gl.framebufferTexture2D( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0 + i, WebGL.TEXTURE_2D, webglTexture, 0 );
					}
				}

				state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, renderTargetProperties['__webglMultisampledFramebuffer'] );
			} else {
				if ( renderTarget.depthBuffer && !renderTarget.resolveDepthBuffer && supportsInvalidateFramebuffer ) {
					final depthStyle = renderTarget.stencilBuffer ? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
					_gl.invalidateFramebuffer( WebGL.DRAW_FRAMEBUFFER, [ depthStyle ] );
				}
			}
		}
  }
  
  bool useMultisampledRenderToTexture(RenderTarget renderTarget) {
    final renderTargetProperties = properties.get(renderTarget);

    return isWebGL2 &&
        renderTarget.samples > 0 &&
        extensions.has('WEBGL_multisampled_render_to_texture') == true &&
        renderTargetProperties["__useRenderToTexture"] != false;
  }
  
  int getRenderTargetSamples(RenderTarget renderTarget) {
    return math.min(maxSamples, renderTarget.samples);
  }

  bool useMultisampledRTT(RenderTarget renderTarget) {
    final renderTargetProperties = properties.get(renderTarget);

    return renderTarget.samples > 0 &&
        extensions.has('WEBGL_multisampled_render_to_texture') &&
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

    const textureType = WebGL.TEXTURE_2D;

    initTexture(textureProperties, texture);

    state.activeTexture(WebGL.TEXTURE0 + slot);
    state.bindTexture(textureType, textureProperties["__webglTexture"]);
    if( kIsWeb ){
      gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
      gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
    }
    gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, texture.unpackAlignment);
  }

  verifyColorSpace(Texture texture, image) {
		final colorSpace = texture.colorSpace;
		final format = texture.format;
		final type = texture.type;

		if ( texture.isCompressedTexture || texture is VideoTexture ) return image;

		if ( colorSpace != LinearSRGBColorSpace && colorSpace != NoColorSpace ) {

			// sRGB

			if ( ColorManagement.getTransfer( ColorSpace.fromString( colorSpace)) == SRGBTransfer ) {

				// in WebGL 2 uncompressed textures can only be sRGB encoded if they have the RGBA8 format

				if ( format != RGBAFormat || type != UnsignedByteType ) {
					console.warning( 'THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.' );
				}
			} else {
				console.error( 'THREE.WebGLTextures: Unsupported texture color space: $colorSpace');
			}
		}

		return image;
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    extensions.dispose();
    state.dispose();
    properties.dispose();
    capabilities.dispose();
    utils.dispose();
    info.dispose();
    _videoTextures.clear();
    _sources.clear();
    wrappingToGL.clear();
    filterToGL.clear();
  }
}
