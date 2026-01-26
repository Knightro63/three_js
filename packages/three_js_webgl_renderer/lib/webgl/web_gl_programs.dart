part of three_webgl;

class WebGLPrograms {
  final shaderIDs = {
    "MeshDepthMaterial": 'depth',
    "MeshDistanceMaterial": 'distanceRGBA',
    "MeshNormalMaterial": 'normal',
    "MeshBasicMaterial": 'basic',
    "MeshLambertMaterial": 'lambert',
    "MeshPhongMaterial": 'phong',
    "MeshToonMaterial": 'toon',
    "MeshStandardMaterial": 'physical',
    "MeshPhysicalMaterial": 'physical',
    "MeshMatcapMaterial": 'matcap',
    "LineBasicMaterial": 'basic',
    "LineDashedMaterial": 'dashed',
    "PointsMaterial": 'points',
    "ShadowMaterial": 'shadow',
    "SpriteMaterial": 'sprite'
  };

  WebGLRenderer renderer;
  WebGLCubeMaps cubemaps;
  WebGLCubeUVMaps cubeuvmaps;
  WebGLExtensions extensions;
  WebGLCapabilities capabilities;
  WebGLBindingStates bindingStates;
  WebGLClipping clipping;

  final _programLayers = Layers();
  final _customShaders = WebGLShaderCache();
  List<WebGLProgram> programs = [];
  final List<int> _activeChannels = [];

  late bool logarithmicDepthBuffer;
  late bool vertexTextures;
  late String precision;
  bool _didDispose = false;

  WebGLPrograms(this.renderer, this.cubemaps, this.cubeuvmaps, this.extensions, this.capabilities, this.bindingStates, this.clipping) {
    logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
    vertexTextures = capabilities.vertexTextures;

    precision = capabilities.precision;
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    renderer.dispose();
    cubemaps.dispose();
    extensions.dispose();
    capabilities.dispose();
    bindingStates.dispose();
    clipping.dispose();
    _customShaders.dispose();
    programs.clear();
  }

	String getChannel(int value ) {
		_activeChannels.add( value );
		if ( value == 0 ) return 'uv';
		return 'uv$value';
	}

  WebGLParameters getParameters(Material material, LightState lights, List<Light> shadows, Scene scene, Object3D object) {
    final fog = scene.fog;
    final geometry = object.geometry;
    final environment = material is MeshStandardMaterial ? scene.environment : null;

    Texture? envMap = material is MeshStandardMaterial?cubeuvmaps.get(material.envMap ?? environment):cubemaps.get(material.envMap ?? environment);

    final envMapCubeUVHeight = (envMap != null) && (envMap.mapping == CubeUVReflectionMapping) ? envMap.image?.height : null;

    final shaderID = shaderIDs[material.shaderID];

    // heuristics to create shader parameters according to lights in the scene
    // (not to blow over maxLights budget)

    if (material.precision != null) {
      precision = capabilities.getMaxPrecision(material.precision);

      if (precision != material.precision) {
        console.warning('WebGLProgram.getParameters: ${material.precision} not supported, using $precision instead.');
      }
    }

    final morphAttribute = geometry?.morphAttributes["position"] ?? geometry?.morphAttributes["normal"] ?? geometry?.morphAttributes["color"];
    final morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

    int morphTextureStride = 0;

    if (geometry?.morphAttributes["position"] != null) morphTextureStride = 1;
    if (geometry?.morphAttributes["normal"] != null) morphTextureStride = 2;
    if (geometry?.morphAttributes["color"] != null) morphTextureStride = 3;

    //

    String? vertexShader, fragmentShader;
    dynamic customVertexShaderID;
    dynamic customFragmentShaderID;

    if (shaderID != null) {
      final shader = shaderLib[shaderID];
      vertexShader = shader["vertexShader"];
      fragmentShader = shader["fragmentShader"];
    } else {
      vertexShader = material.vertexShader;
      fragmentShader = material.fragmentShader;

      _customShaders.update(material);

      customVertexShaderID = _customShaders.getVertexShaderID(material);
      customFragmentShaderID = _customShaders.getFragmentShaderID(material);
    }

    // print(" WebGLPrograms material : ${material.type} ${material.shaderID} ${material.id} object: ${object.type} ${object.id} shaderID: ${shaderID} vertexColors: ${material.vertexColors} ");

    final currentRenderTarget = renderer.getRenderTarget();

    final useAlphaTest = material.alphaTest > 0;
    final useClearcoat = material.clearcoat > 0;

    final parameters = WebGLParameters(
			shaderID: shaderID,
			shaderType: material.type,
			shaderName: "${material.type} - ${material.name}",

			vertexShader: vertexShader ?? '',
			fragmentShader: fragmentShader ?? '',
			defines: material.defines,

			customVertexShaderID: customVertexShaderID,
			customFragmentShaderID: customFragmentShaderID,

			isRawShaderMaterial: material is RawShaderMaterial,
			glslVersion: material.glslVersion,

			precision: precision,

			batching: object is BatchedMesh,
			instancing: object is InstancedMesh,
			instancingColor: object is InstancedMesh && object.instanceColor != null,
			instancingMorph: object is InstancedMesh && object.morphTexture != null,

			supportsVertexTextures: vertexTextures,
			outputColorSpace: ( currentRenderTarget == null ) ? renderer.outputColorSpace : ( currentRenderTarget.isXRRenderTarget? currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace ),
			alphaToCoverage: !! material.alphaToCoverage,

			map: material.map != null,
			matcap: material.matcap != null,
			envMap: envMap != null,
			envMapMode: envMap?.mapping,
			envMapCubeUVHeight: envMapCubeUVHeight,
			aoMap: material.aoMap != null,
			lightMap: material.lightMap != null,
			bumpMap: material.bumpMap != null,
			normalMap: material.normalMap != null,
			displacementMap: capabilities.vertexTextures && material.displacementMap != null,
			emissiveMap: material.emissiveMap != null,

			normalMapObjectSpace: material.normalMap != null && material.normalMapType == ObjectSpaceNormalMap,
			normalMapTangentSpace: material.normalMap != null && material.normalMapType == TangentSpaceNormalMap,

			metalnessMap: material.metalnessMap != null,
			roughnessMap: material.roughnessMap != null,

			anisotropy: material is MeshPhysicalMaterial && material.anisotropy > 0,
			anisotropyMap: material is MeshPhysicalMaterial && material.anisotropy > 0 && material.anisotropyMap != null,

			clearcoat: useClearcoat,
			clearcoatMap: useClearcoat && material.clearcoatMap != null,
			clearcoatNormalMap: useClearcoat && material.clearcoatRoughnessMap != null,
			clearcoatRoughnessMap: useClearcoat && material.clearcoatNormalMap != null,

			dispersion: material is MeshPhysicalMaterial && material.dispersion > 0,

			iridescence: material is MeshPhysicalMaterial && material.iridescence > 0,
			iridescenceMap: material is MeshPhysicalMaterial && material.iridescence > 0 && material.iridescenceMap != null,
			iridescenceThicknessMap: material is MeshPhysicalMaterial && material.iridescence > 0 && material.iridescenceThicknessMap != null,

			sheen: material.sheen > 0,
			sheenColorMap: material.sheenColorMap != null,
			sheenRoughnessMap: material.sheenRoughnessMap != null,

			specularMap: material.specularMap != null,
			specularColorMap: material.specularColorMap != null,
			specularIntensityMap: material.specularIntensityMap != null,

			transmission: material.transmission > 0,
			transmissionMap: material.transmissionMap != null,
			thicknessMap: material.thicknessMap != null,

			gradientMap: material.gradientMap != null,

			opaque: !material.transparent && material.blending == NormalBlending && !material.alphaToCoverage,

			alphaMap: material.alphaMap != null,
			alphaTest: useAlphaTest,
			alphaHash: material.alphaHash,

			combine: material.combine,

			//

			mapUv: material.map ==null?null: getChannel( material.map!.channel ),
			aoMapUv: material.aoMap ==null?null:getChannel( material.aoMap!.channel ),
			lightMapUv: material.lightMap ==null?null:getChannel( material.lightMap!.channel ),
			bumpMapUv: material.bumpMap ==null?null:getChannel( material.bumpMap!.channel ),
			normalMapUv:material.normalMap ==null?null:getChannel( material.normalMap!.channel ),
			displacementMapUv: material.displacementMap ==null?null:getChannel( material.displacementMap!.channel ),
			emissiveMapUv: material.emissiveMap ==null?null:getChannel( material.emissiveMap!.channel ),

			metalnessMapUv: material.metalnessMap ==null?null:getChannel( material.metalnessMap!.channel ),
			roughnessMapUv: material.roughnessMap ==null?null:getChannel( material.roughnessMap!.channel ),

			anisotropyMapUv: material.anisotropyMap==null?null:getChannel( material.anisotropyMap!.channel ),

			clearcoatMapUv: material.clearcoatMap ==null?null:getChannel( material.clearcoatMap!.channel ),
			clearcoatNormalMapUv: material.clearcoatNormalMap ==null?null:getChannel( material.clearcoatNormalMap!.channel ),
			clearcoatRoughnessMapUv: material.clearcoatRoughnessMap ==null?null:getChannel( material.clearcoatRoughnessMap!.channel ),

			iridescenceMapUv: material.iridescenceMap ==null?null:getChannel( material.iridescenceMap!.channel ),
			iridescenceThicknessMapUv: material.iridescenceThicknessMap ==null?null:getChannel( material.iridescenceThicknessMap!.channel ),

			sheenColorMapUv: material.sheenColorMap ==null?null:getChannel( material.sheenColorMap!.channel ),
			sheenRoughnessMapUv: material.sheenRoughnessMap ==null?null:getChannel( material.sheenRoughnessMap!.channel ),

			specularMapUv: material.specularMap ==null?null:getChannel( material.specularMap!.channel ),
			specularColorMapUv: material.specularColorMap ==null?null:getChannel( material.specularColorMap!.channel ),
			specularIntensityMapUv: material.specularIntensityMap ==null?null:getChannel( material.specularIntensityMap!.channel ),

			transmissionMapUv: material.transmissionMap == null?null:getChannel( material.transmissionMap!.channel ),
			thicknessMapUv: material.thicknessMap ==null?null:getChannel( material.thicknessMap!.channel ),

			alphaMapUv: material.alphaMap ==null?null:getChannel( material.alphaMap!.channel ),

			//

			vertexTangents: (material.normalMap != null && geometry != null && geometry.attributes["tangent"] != null),
			vertexColors: material.vertexColors,
			vertexAlphas: material.vertexColors == true &&
        geometry != null &&
        geometry.attributes["color"] != null &&
        geometry.attributes["color"].itemSize == 4,

			pointsUvs: object is Points && geometry?.attributes['uv'] != null && ( material.map != null || material.alphaMap != null ),

			fog: fog != null,
			useFog: material.fog,
			fogExp2: (fog != null && fog.isFogExp2),

			flatShading: material.flatShading,

			sizeAttenuation: material.sizeAttenuation,
			logarithmicDepthBuffer: logarithmicDepthBuffer,

			skinning: object is SkinnedMesh,

			morphTargets: geometry?.morphAttributes['position'] != null,
			morphNormals: geometry?.morphAttributes['normal'] != null,
			morphColors: geometry?.morphAttributes['color'] != null,
			morphTargetsCount: morphTargetsCount,
			morphTextureStride: morphTextureStride,

			numDirLights: lights.directional.length,
			numPointLights: lights.point.length,
			numSpotLights: lights.spot.length,
			numSpotLightMaps: lights.spotLightMap.length,
			numRectAreaLights: lights.rectArea.length,
			numHemiLights: lights.hemi.length,

			numDirLightShadows: lights.directionalShadowMap.length,
			numPointLightShadows: lights.pointShadowMap.length,
			numSpotLightShadows: lights.spotShadowMap.length,
			numSpotLightShadowsWithMaps: lights.numSpotLightShadowsWithMaps,

			numLightProbes: lights.numLightProbes,

			numClippingPlanes: clipping.numPlanes,
			numClipIntersection: clipping.numIntersection,

			dithering: material.dithering,

			shadowMapEnabled: renderer.shadowMap.enabled && shadows.length > 0,
			shadowMapType: renderer.shadowMap.type,

			toneMapping: material.toneMapped ? renderer.toneMapping : NoToneMapping,
			useLegacyLights: renderer.useLegacyLights,

			decodeVideoTexture: material.map != null && 
        ( material.map is VideoTexture) && 
        ( ColorManagement.getTransfer( ColorSpace.fromString(material.map!.colorSpace) ) == SRGBTransfer ),

			premultipliedAlpha: material.premultipliedAlpha,

			doubleSided: material.side == DoubleSide,
			flipSided: material.side == BackSide,

			useDepthPacking: (material.depthPacking ?? 0) >= 0,
			depthPacking: material.depthPacking ?? 0,

			index0AttributeName: material.index0AttributeName,

			extensionClipCullDistance: material.extensions != null && material.extensions?['clipCullDistance'] == true && extensions.has( 'WEBGL_clip_cull_distance' ),
			extensionMultiDraw: material.extensions != null && material.extensions?['multiDraw'] == true && extensions.has( 'WEBGL_multi_draw' ),

			rendererExtensionParallelShaderCompile: extensions.has( 'KHR_parallel_shader_compile' ),

			customProgramCacheKey: material.customProgramCacheKey()
    );

		parameters.vertexUv1s = _activeChannels.contains( 1 );
		parameters.vertexUv2s = _activeChannels.contains( 2 );
		parameters.vertexUv3s = _activeChannels.contains( 3 );

    _activeChannels.clear();

    return parameters;
  }

  String getProgramCacheKey(WebGLParameters parameters) {
    List<dynamic> array = [];

    if (parameters.shaderID != null) {
      array.add(parameters.shaderID!);
    } else {
      array.add(parameters.customVertexShaderID);
      array.add(parameters.customFragmentShaderID);
    }

    if (parameters.defines != null) {
      for (final name in parameters.defines!.keys) {
        array.add(name);
        array.add(parameters.defines![name].toString());
      }
    }

    if (parameters is! RawShaderMaterial) {
      getProgramCacheKeyParameters(array, parameters);
      getProgramCacheKeyBooleans(array, parameters);

      array.add(renderer.outputEncoding.toString());
    }
    array.add(parameters.customProgramCacheKey);

    return array.join();
  }

  void getProgramCacheKeyParameters(List array, WebGLParameters parameters) {
		array.add( parameters.precision );
		array.add( parameters.outputColorSpace );
		array.add( parameters.envMapMode );
		array.add( parameters.envMapCubeUVHeight );
		array.add( parameters.mapUv );
		array.add( parameters.alphaMapUv );
		array.add( parameters.lightMapUv );
		array.add( parameters.aoMapUv );
		array.add( parameters.bumpMapUv );
		array.add( parameters.normalMapUv );
		array.add( parameters.displacementMapUv );
		array.add( parameters.emissiveMapUv );
		array.add( parameters.metalnessMapUv );
		array.add( parameters.roughnessMapUv );
		array.add( parameters.anisotropyMapUv );
		array.add( parameters.clearcoatMapUv );
		array.add( parameters.clearcoatNormalMapUv );
		array.add( parameters.clearcoatRoughnessMapUv );
		array.add( parameters.iridescenceMapUv );
		array.add( parameters.iridescenceThicknessMapUv );
		array.add( parameters.sheenColorMapUv );
		array.add( parameters.sheenRoughnessMapUv );
		array.add( parameters.specularMapUv );
		array.add( parameters.specularColorMapUv );
		array.add( parameters.specularIntensityMapUv );
		array.add( parameters.transmissionMapUv );
		array.add( parameters.thicknessMapUv );
		array.add( parameters.combine );
		array.add( parameters.fogExp2 );
		array.add( parameters.sizeAttenuation );
		array.add( parameters.morphTargetsCount );
		array.add( parameters.morphAttributeCount );
		array.add( parameters.numDirLights );
		array.add( parameters.numPointLights );
		array.add( parameters.numSpotLights );
		array.add( parameters.numSpotLightMaps );
		array.add( parameters.numHemiLights );
		array.add( parameters.numRectAreaLights );
		array.add( parameters.numDirLightShadows );
		array.add( parameters.numPointLightShadows );
		array.add( parameters.numSpotLightShadows );
		array.add( parameters.numSpotLightShadowsWithMaps );
		array.add( parameters.numLightProbes );
		array.add( parameters.shadowMapType );
		array.add( parameters.toneMapping );
		array.add( parameters.numClippingPlanes );
		array.add( parameters.numClipIntersection );
		array.add( parameters.depthPacking );
  }

  void getProgramCacheKeyBooleans(List array, WebGLParameters parameters) {

		_programLayers.disableAll();

		if ( parameters.supportsVertexTextures )_programLayers.enable( 0 );
		if ( parameters.instancing )_programLayers.enable( 1 );
		if ( parameters.instancingColor )_programLayers.enable( 2 );
		if ( parameters.instancingMorph )_programLayers.enable( 3 );
		if ( parameters.matcap )_programLayers.enable( 4 );
		if ( parameters.envMap )_programLayers.enable( 5 );
		if ( parameters.normalMapObjectSpace )_programLayers.enable( 6 );
		if ( parameters.normalMapTangentSpace )_programLayers.enable( 7 );
		if ( parameters.clearcoat )_programLayers.enable( 8 );
		if ( parameters.iridescence )_programLayers.enable( 9 );
		if ( parameters.alphaTest )_programLayers.enable( 10 );
		if ( parameters.vertexColors )_programLayers.enable( 11 );
		if ( parameters.vertexAlphas )_programLayers.enable( 12 );
		if ( parameters.vertexUv1s )_programLayers.enable( 13 );
		if ( parameters.vertexUv2s )_programLayers.enable( 14 );
		if ( parameters.vertexUv3s )_programLayers.enable( 15 );
		if ( parameters.vertexTangents )_programLayers.enable( 16 );
		if ( parameters.anisotropy )_programLayers.enable( 17 );
		if ( parameters.alphaHash )_programLayers.enable( 18 );
		if ( parameters.batching )_programLayers.enable( 19 );
		if ( parameters.dispersion )_programLayers.enable( 20 );
		if ( parameters.batchingColor )_programLayers.enable( 21 );

		array.add( _programLayers.mask );
		_programLayers.disableAll();

		if ( parameters.fog )_programLayers.enable( 0 );
		if ( parameters.useFog )_programLayers.enable( 1 );
		if ( parameters.flatShading )_programLayers.enable( 2 );
		if ( parameters.logarithmicDepthBuffer )_programLayers.enable( 3 );
		if ( parameters.skinning )_programLayers.enable( 4 );
		if ( parameters.morphTargets )_programLayers.enable( 5 );
		if ( parameters.morphNormals )_programLayers.enable( 6 );
		if ( parameters.morphColors )_programLayers.enable( 7 );
		if ( parameters.premultipliedAlpha )_programLayers.enable( 8 );
		if ( parameters.shadowMapEnabled )_programLayers.enable( 9 );
		if ( parameters.useLegacyLights )_programLayers.enable( 10 );
		if ( parameters.doubleSided )_programLayers.enable( 11 );
		if ( parameters.flipSided )_programLayers.enable( 12 );
		if ( parameters.useDepthPacking )_programLayers.enable( 13 );
		if ( parameters.dithering )_programLayers.enable( 14 );
		if ( parameters.transmission )_programLayers.enable( 15 );
		if ( parameters.sheen )_programLayers.enable( 16 );
		if ( parameters.opaque )_programLayers.enable( 17 );
		if ( parameters.pointsUvs )_programLayers.enable( 18 );
		if ( parameters.decodeVideoTexture )_programLayers.enable( 19 );
		if ( parameters.decodeVideoTextureEmissive )_programLayers.enable( 20 );
		if ( parameters.alphaToCoverage )_programLayers.enable( 21 );

		array.add( _programLayers.mask );
  }

  Map<String, dynamic> getUniforms(Material material) {
    String? shaderID = shaderIDs[material.shaderID];
    Map<String, dynamic> uniforms;

    if (shaderID != null) {
      final shader = shaderLib[shaderID];
      uniforms = cloneUniforms(shader["uniforms"]);
    } else {
      uniforms = material.uniforms;
    }

    return uniforms;
  }

  WebGLProgram? acquireProgram(WebGLParameters parameters, String cacheKey) {
    WebGLProgram? program;

    // Check if code has been already compiled
    for (int p = 0, pl = programs.length; p < pl; p++) {
      final preexistingProgram = programs[p];

      if (preexistingProgram.cacheKey == cacheKey) {
        program = preexistingProgram;
        ++program.usedTimes;

        break;
      }
    }

    if (program == null) {
      program = WebGLProgram(renderer, cacheKey, parameters, bindingStates);
      programs.add(program);
    }

    return program;
  }

  void releaseProgram(WebGLProgram program) {
    if (--program.usedTimes == 0) {
      // Remove from unordered set
      final i = programs.indexOf(program);
      programs[i] = programs[programs.length - 1];
      programs.removeLast();

      // Free WebGL resources
      program.destroy();
    }
  }

  void releaseShaderCache(Material material) {
    _customShaders.remove(material);
  }
}
