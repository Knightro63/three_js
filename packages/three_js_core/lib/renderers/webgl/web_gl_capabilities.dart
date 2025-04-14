part of three_webgl;

class WebGLCapabilities {
  bool _didDispose = false;
  bool isWebGL2 = true;

  Map<String, dynamic> parameters;
  RenderingContext gl;
  WebGLExtensions extensions;
  WebGLUtils utils;

  String precision = 'highp';
  String maxPrecision = "highp";

  bool logarithmicDepthBuffer = false;
  late int maxTextures;
  late int maxVertexTextures;
  late int maxTextureSize;
  late int maxCubemapSize;
  late int maxAttributes;
  late int maxVertexUniforms;
  late int maxVaryings;
  late int maxFragmentUniforms;
  late bool reverseDepthBuffer;

  num? maxAnisotropy;

  late bool vertexTextures;
  late int maxSamples;

  bool drawBuffers = true;

  WebGLCapabilities(this.gl, this.extensions, this.parameters, this.utils) {
    precision = parameters["precision"] ?? "highp";

    maxPrecision = getMaxPrecision(precision);
    if (maxPrecision != precision) {
      console.warning('WebGLRenderer: $precision not supported, using $maxPrecision instead.');
      precision = maxPrecision;
    }

    logarithmicDepthBuffer = parameters["logarithmicDepthBuffer"] == true;
    reverseDepthBuffer = parameters['reverseDepthBuffer'] == true && extensions.has( 'EXT_clip_control' );

    maxTextures = gl.getParameter(WebGL.MAX_TEXTURE_IMAGE_UNITS);
    maxVertexTextures = gl.getParameter(WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    maxTextureSize = gl.getParameter(WebGL.MAX_TEXTURE_SIZE);
    maxCubemapSize = gl.getParameter(WebGL.MAX_CUBE_MAP_TEXTURE_SIZE);

    maxAttributes = gl.getParameter(WebGL.MAX_VERTEX_ATTRIBS);
    maxVertexUniforms = gl.getParameter(WebGL.MAX_VERTEX_UNIFORM_VECTORS);
    maxVaryings = gl.getParameter(WebGL.MAX_VARYING_VECTORS);
    maxFragmentUniforms = gl.getParameter(WebGL.MAX_FRAGMENT_UNIFORM_VECTORS);

    vertexTextures = maxVertexTextures > 0;

    maxSamples = gl.getParameter(WebGL.MAX_SAMPLES);
  }

  num getMaxAnisotropy() {
    if (maxAnisotropy != null) return maxAnisotropy!;

    final extension = extensions.get('EXT_texture_filter_anisotropic');

    if (extension != null) {
      maxAnisotropy = gl.getParameter(WebGL.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
    } else {
      maxAnisotropy = 0;
    }

    return maxAnisotropy!;
  }

	bool textureFormatReadable(int textureFormat ) {
		if ( textureFormat != RGBAFormat && utils.convert( textureFormat ) != gl.getParameter( WebGL.IMPLEMENTATION_COLOR_READ_FORMAT ) ) {
			return false;
		}
		return true;
	}

	bool textureTypeReadable(int textureType ) {
		final halfFloatSupportedByExt = ( textureType == HalfFloatType ) && ( extensions.has( 'EXT_color_buffer_half_float' ) || extensions.has( 'EXT_color_buffer_float' ) );

		if ( textureType != UnsignedByteType && utils.convert( textureType ) != gl.getParameter( WebGL.IMPLEMENTATION_COLOR_READ_TYPE ) && // Edge and Chrome Mac < 52 (#9513)
			textureType != FloatType && ! halfFloatSupportedByExt ) {
			return false;
		}

		return true;
	}
  String getMaxPrecision([String? precision]) {
		if ( precision == 'highp' ) {
			if ( gl.getShaderPrecisionFormat( WebGL.VERTEX_SHADER, WebGL.HIGH_FLOAT ).precision > 0 &&
				gl.getShaderPrecisionFormat( WebGL.FRAGMENT_SHADER, WebGL.HIGH_FLOAT ).precision > 0 ) {
				return 'highp';
			}

			precision = 'mediump';
		}

		if ( precision == 'mediump' ) {
			if ( gl.getShaderPrecisionFormat( WebGL.VERTEX_SHADER, WebGL.MEDIUM_FLOAT ).precision > 0 &&
				gl.getShaderPrecisionFormat( WebGL.FRAGMENT_SHADER, WebGL.MEDIUM_FLOAT ).precision > 0 ) {
				return 'mediump';
			}
		}

		return 'lowp';
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    parameters.clear();
    extensions.dispose();
  }
}
