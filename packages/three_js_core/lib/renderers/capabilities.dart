

abstract class Capabilities {
  bool isWebGL2 = true;

  String precision = 'highp';
  String maxPrecision = "highp";

  bool logarithmicDepthBuffer = false;
  num? maxAnisotropy;
  bool drawBuffers = true;

  late int maxTextures;
  late int maxVertexTextures;
  late int maxTextureSize;
  late int maxCubemapSize;
  late int maxAttributes;
  late int maxVertexUniforms;
  late int maxVaryings;
  late int maxFragmentUniforms;
  late bool reverseDepthBuffer;

  late bool vertexTextures;
  late int maxSamples;

  num getMaxAnisotropy();

	bool textureFormatReadable(int textureFormat );

	bool textureTypeReadable(int textureType );
  String getMaxPrecision([String? precision]);

  void dispose();
}
