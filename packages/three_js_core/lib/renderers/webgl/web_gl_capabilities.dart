part of three_webgl;

class WebGLCapabilities {
  bool isWebGL2 = true;

  Map<String, dynamic> parameters;
  RenderingContext gl;
  WebGLExtensions extensions;

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

  num? maxAnisotropy;

  late bool vertexTextures;
  late bool floatFragmentTextures;
  late bool floatVertexTextures;

  late int maxSamples;

  bool get drawBuffers => isWebGL2 || extensions.has('WEBGL_draw_buffers');

  WebGLCapabilities(this.gl, this.extensions, this.parameters) {
    precision = parameters["precision"] ?? "highp";

    maxPrecision = getMaxPrecision(precision);
    if (maxPrecision != precision) {
      console.warning('WebGLRenderer: $precision not supported, using $maxPrecision instead.');
      precision = maxPrecision;
    }

    logarithmicDepthBuffer = parameters["logarithmicDepthBuffer"] == true;

    maxTextures = gl.getParameter(WebGL.MAX_TEXTURE_IMAGE_UNITS);
    maxVertexTextures = gl.getParameter(WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    maxTextureSize = gl.getParameter(WebGL.MAX_TEXTURE_SIZE);
    maxCubemapSize = gl.getParameter(WebGL.MAX_CUBE_MAP_TEXTURE_SIZE);

    maxAttributes = gl.getParameter(WebGL.MAX_VERTEX_ATTRIBS);
    maxVertexUniforms = gl.getParameter(WebGL.MAX_VERTEX_UNIFORM_VECTORS);
    maxVaryings = gl.getParameter(WebGL.MAX_VARYING_VECTORS);
    maxFragmentUniforms = gl.getParameter(WebGL.MAX_FRAGMENT_UNIFORM_VECTORS);

    vertexTextures = maxVertexTextures > 0;
    floatFragmentTextures = isWebGL2;
    floatVertexTextures = vertexTextures && floatFragmentTextures;

    maxSamples = isWebGL2 ? gl.getParameter(WebGL.MAX_SAMPLES) : 0;
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

  String getMaxPrecision(precision) {
    return 'highp';
  }
}
