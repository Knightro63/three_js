String envmapCommonParsFragment = """
#ifdef USE_ENVMAP

	uniform float envMapIntensity;
	uniform float flipEnvMapX;
  uniform float flipEnvMapY;

	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif
""";
