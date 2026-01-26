part of three_shaders;

Map<String, dynamic> shaderLibStandard = {
  "uniforms": mergeUniforms([
    uniformsLib["common"],
    uniformsLib["envmap"],
    uniformsLib["aomap"],
    uniformsLib["lightmap"],
    uniformsLib["emissivemap"],
    uniformsLib["bumpmap"],
    uniformsLib["normalmap"],
    uniformsLib["displacementmap"],
    uniformsLib["roughnessmap"],
    uniformsLib["metalnessmap"],
    uniformsLib["fog"],
    uniformsLib["lights"],
    {
      "emissive": {"value": Color(0, 0, 0)},
      "roughness": {"value": 1.0},
      "metalness": {"value": 0.0},
      "envMapIntensity": {"value": 1} // temporary
    }
  ]),
  "vertexShader": shaderChunk["meshphysical_vert"],
  "fragmentShader": shaderChunk["meshphysical_frag"]
};

Map<String, dynamic> shaderLib = {
  "basic": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["specularmap"],
      uniformsLib["envmap"],
      uniformsLib["aomap"],
      uniformsLib["lightmap"],
      uniformsLib["fog"]
    ]),
    "vertexShader": shaderChunk["meshbasic_vert"],
    "fragmentShader": shaderChunk["meshbasic_frag"]
  },
  "lambert": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["specularmap"],
      uniformsLib["envmap"],
      uniformsLib["aomap"],
      uniformsLib["lightmap"],
      uniformsLib["emissivemap"],
      uniformsLib["bumpmap"],
      uniformsLib["normalmap"],
      uniformsLib["displacementmap"],
      uniformsLib["fog"],
      uniformsLib["lights"],
      {
        "emissive": {"value": Color.fromHex32(0x000000)}
      }
    ]),
    "vertexShader": shaderChunk["meshlambert_vert"],
    "fragmentShader": shaderChunk["meshlambert_frag"]
  },
  "phong": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["specularmap"],
      uniformsLib["envmap"],
      uniformsLib["aomap"],
      uniformsLib["lightmap"],
      uniformsLib["emissivemap"],
      uniformsLib["bumpmap"],
      uniformsLib["normalmap"],
      uniformsLib["displacementmap"],
      uniformsLib["fog"],
      uniformsLib["lights"],
      {
        "emissive": {"value": Color.fromHex32(0x000000)},
        "specular": {"value": Color.fromHex32(0x111111)},
        "shininess": {"value": 30}
      }
    ]),
    "vertexShader": shaderChunk["meshphong_vert"],
    "fragmentShader": shaderChunk["meshphong_frag"]
  },
  "standard": shaderLibStandard,
  "toon": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["aomap"],
      uniformsLib["lightmap"],
      uniformsLib["emissivemap"],
      uniformsLib["bumpmap"],
      uniformsLib["normalmap"],
      uniformsLib["displacementmap"],
      uniformsLib["gradientmap"],
      uniformsLib["fog"],
      uniformsLib["lights"],
      {
        "emissive": {"value": Color.fromHex32(0x000000)}
      }
    ]),
    "vertexShader": shaderChunk["meshtoon_vert"],
    "fragmentShader": shaderChunk["meshtoon_frag"]
  },
  "matcap": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["bumpmap"],
      uniformsLib["normalmap"],
      uniformsLib["displacementmap"],
      uniformsLib["fog"],
      {
        "matcap": <String,dynamic>{"value": null}
      }
    ]),
    "vertexShader": shaderChunk["meshmatcap_vert"],
    "fragmentShader": shaderChunk["meshmatcap_frag"]
  },
  "points": {
    "uniforms": mergeUniforms([uniformsLib["points"], uniformsLib["fog"]]),
    "vertexShader": shaderChunk["points_vert"],
    "fragmentShader": shaderChunk["points_frag"]
  },
  "dashed": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["fog"],
      {
        "scale": {"value": 1},
        "dashSize": {"value": 1},
        "totalSize": {"value": 2}
      }
    ]),
    "vertexShader": shaderChunk["linedashed_vert"],
    "fragmentShader": shaderChunk["linedashed_frag"]
  },
  "depth": {
    "uniforms":
        mergeUniforms([uniformsLib["common"], uniformsLib["displacementmap"]]),
    "vertexShader": shaderChunk["depth_vert"],
    "fragmentShader": shaderChunk["depth_frag"]
  },
  "normal": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["bumpmap"],
      uniformsLib["normalmap"],
      uniformsLib["displacementmap"],
      {
        "opacity": {"value": 1.0}
      }
    ]),
    "vertexShader": shaderChunk["meshnormal_vert"],
    "fragmentShader": shaderChunk["meshnormal_frag"]
  },
  "sprite": {
    "uniforms": mergeUniforms([uniformsLib["sprite"], uniformsLib["fog"]]),
    "vertexShader": shaderChunk["sprite_vert"],
    "fragmentShader": shaderChunk["sprite_frag"]
  },
  "background": {
    "uniforms": {
      "uvTransform": {"value": Matrix3.identity()},
      "t2D": <String,dynamic>{"value": null},
      'backgroundIntensity': { 'value': 1 }
    },
    "vertexShader": shaderChunk["background_vert"],
    "fragmentShader": shaderChunk["background_frag"]
  },
	'backgroundCube': {

		'uniforms': {
			'envMap': <String,dynamic>{ 'value': null },
			'flipEnvMap': { 'value': - 1 },
			'backgroundBlurriness': { 'value': 0 },
			'backgroundIntensity': { 'value': 1 },
			'backgroundRotation': { 'value': Matrix3.identity() }
		},

		'vertexShader': shaderChunk['backgroundCube_vert'],
		'fragmentShader': shaderChunk['backgroundCube_frag']
	},
  /* -------------------------------------------------------------------------
	//	Cube map shader
	 ------------------------------------------------------------------------- */

  "cube": {
		'uniforms': {
			'tCube': <String,dynamic>{ 'value': null },
			'tFlip': { 'value': - 1 },
			'opacity': { 'value': 1.0 },
		},
    "vertexShader": shaderChunk["cube_vert"],
    "fragmentShader": shaderChunk["cube_frag"]
  },
  "equirect": {
    "uniforms": {
      "tEquirect": <String,dynamic>{"value": null},
    },
    "vertexShader": shaderChunk["equirect_vert"],
    "fragmentShader": shaderChunk["equirect_frag"]
  },
  "distanceRGBA": {
    "uniforms": mergeUniforms([
      uniformsLib["common"],
      uniformsLib["displacementmap"],
      {
        "referencePosition": {"value": Vector3.zero()},
        "nearDistance": {"value": 1},
        "farDistance": {"value": 1000}
      }
    ]),
    "vertexShader": shaderChunk["distanceRGBA_vert"],
    "fragmentShader": shaderChunk["distanceRGBA_frag"]
  },
  "shadow": {
    "uniforms": mergeUniforms([
      uniformsLib["lights"],
      uniformsLib["fog"],
      {
        "color": {"value": Color.fromHex32(0x000000)},
        "opacity": {"value": 1.0}
      },
    ]),
    "vertexShader": shaderChunk["shadow_vert"],
    "fragmentShader": shaderChunk["shadow_frag"]
  },
  "physical": {
    "uniforms": mergeUniforms([
      shaderLibStandard["uniforms"],
      {
        'clearcoat': { 'value': 0 },
        'clearcoatMap': <String,dynamic>{ 'value': null },
        'clearcoatMapTransform': { 'value': Matrix3.identity() },
        'clearcoatNormalMap': <String,dynamic>{ 'value': null },
        'clearcoatNormalMapTransform': { 'value': Matrix3.identity() },
        'clearcoatNormalScale': { 'value': Vector2( 1, 1 ) },
        'clearcoatRoughness': { 'value': 0 },
        'clearcoatRoughnessMap': <String,dynamic>{ 'value': null },
        'clearcoatRoughnessMapTransform': { 'value': Matrix3.identity() },
        'dispersion': { 'value': 0 },
        'iridescence': { 'value': 0 },
        'iridescenceMap': <String,dynamic>{ 'value': null },
        'iridescenceMapTransform': { 'value': Matrix3.identity() },
        'iridescenceIOR': { 'value': 1.3 },
        'iridescenceThicknessMinimum': { 'value': 100 },
        'iridescenceThicknessMaximum': { 'value': 400 },
        'iridescenceThicknessMap': <String,dynamic>{ 'value': null },
        'iridescenceThicknessMapTransform': { 'value': Matrix3.identity() },
        'sheen': { 'value': 0 },
        'sheenColor': { 'value': Color( 0x000000 ) },
        'sheenColorMap': <String,dynamic>{ 'value': null },
        'sheenColorMapTransform': { 'value': Matrix3.identity() },
        'sheenRoughness': { 'value': 1 },
        'sheenRoughnessMap': <String,dynamic>{ 'value': null },
        'sheenRoughnessMapTransform': { 'value': Matrix3.identity() },
        'transmission': { 'value': 0 },
        'transmissionMap': <String,dynamic>{ 'value': null },
        'transmissionMapTransform': { 'value': Matrix3.identity() },
        'transmissionSamplerSize': { 'value': Vector2() },
        'transmissionSamplerMap': <String,dynamic>{ 'value': null },
        'thickness': { 'value': 0 },
        'thicknessMap': <String,dynamic>{ 'value': null },
        'thicknessMapTransform': { 'value': Matrix3.identity() },
        'attenuationDistance': { 'value': 0 },
        'attenuationColor': { 'value': Color( 0x000000 ) },
        'specularColor': { 'value': Color( 1, 1, 1 ) },
        'specularColorMap': <String,dynamic>{ 'value': null },
        'specularColorMapTransform': { 'value': Matrix3.identity() },
        'specularIntensity': { 'value': 1 },
        'specularIntensityMap': <String,dynamic>{ 'value': null },
        'specularIntensityMapTransform': { 'value': Matrix3.identity() },
        'anisotropyVector': { 'value': Vector2() },
        'anisotropyMap': <String,dynamic>{ 'value': null },
        'anisotropyMapTransform': { 'value': Matrix3.identity() },
      }
    ]),
    "vertexShader": shaderChunk["meshphysical_vert"],
    "fragmentShader": shaderChunk["meshphysical_frag"]
  }
};