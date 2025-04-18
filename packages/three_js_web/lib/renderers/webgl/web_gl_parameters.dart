part of three_webgl;

class WebGLParameters {
  int? customVertexShaderID;
  int? customFragmentShaderID;

  bool rendererExtensionParallelShaderCompile = false;

  String? shaderID;
  String? shaderType;
  String outputColorSpace = NoColorSpace;
  String shaderName = '';

  String vertexShader = '';
  String fragmentShader = '';

  Map<String, dynamic>? defines;

  bool isRawShaderMaterial = false;
  String? glslVersion;

  late String precision;

  bool instancing = false;
  bool instancingColor = false;

  bool supportsVertexTextures = false;
  bool map = false;
  bool matcap = false;
  bool envMap = false;
  int? envMapMode;
  bool lightMap = false;
  bool aoMap = false;
  bool emissiveMap = false;
  bool bumpMap = false;
  bool normalMap = false;
  bool normalMapObjectSpace = false;
  bool normalMapTangentSpace = false;

  bool clearcoat = false;
  bool clearcoatMap = false;
  bool clearcoatRoughnessMap = false;
  bool clearcoatNormalMap = false;

  bool displacementMap = false;
  bool roughnessMap = false;
  bool metalnessMap = false;
  bool specularMap = false;
  bool specularIntensityMap = false;
  bool specularColorMap = false;
  bool alphaMap = false;
  bool sheenColorMap = false;

  bool gradientMap = false;
  bool sheenRoughnessMap = false;
  bool sheen = false;
  bool transmission = false;
  bool transmissionMap = false;
  bool thicknessMap = false;
  int? combine;
  bool vertexTangents = false;
  bool vertexColors = false;
  bool vertexUvs = false;
  bool pointsUvs = false;
  bool fog = false;
  bool useFog = false;
  bool fogExp2 = false;
  bool flatShading = false;
  bool sizeAttenuation = false;
  bool logarithmicDepthBuffer = false;

  bool skinning = false;

  bool morphTargets = false;
  bool morphNormals = false;
  bool morphColors = false;

  int numDirLights = 0;
  int numPointLights = 0;
  int numSpotLights = 0;
  int numRectAreaLights = 0;
  int numHemiLights = 0;
  int numSpotLightMaps = 0;

  int numDirLightShadows = 0;
  int numPointLightShadows = 0;
  int numSpotLightShadows = 0;
  int numLightProbes = 0;
  int numSpotLightShadowsWithMaps = 0;

  int numClippingPlanes = 0;
  int numClipIntersection = 0;
  bool dithering = false;
  bool shadowMapEnabled = false;
  int? shadowMapType;
  int? toneMapping;
  bool useLegacyLights = false;
  bool physicallyCorrectLights = false;
  bool premultipliedAlpha = false;
  bool alphaTest = false;

  bool doubleSided = false;
  bool flipSided = false;

  bool useDepthPacking = false;
  int? depthPacking;

  String? index0AttributeName;

  late bool extensionDerivatives;
  late bool extensionFragDepth;
  late bool extensionDrawBuffers;
  late bool extensionShaderTextureLOD;

  late bool rendererExtensionFragDepth;
  late bool rendererExtensionDrawBuffers;
  late bool rendererExtensionShaderTextureLod;
  String? customProgramCacheKey;

  bool decodeVideoTexture = false;
  bool decodeVideoTextureEmissive = false;

  Map<String, dynamic>? uniforms;

  bool vertexAlphas = false;
  bool opaque = false;
  bool batching = false;

  bool anisotropy = false;
  bool anisotropyMap = false;

  bool iridescence = false;
  bool iridescenceMap = false;
  bool iridescenceThicknessMap = false;
  bool alphaHash = false;
  bool dispersion = false;
  bool batchingColor = false;

  int morphTargetsCount = 0;
  num? cubeUVHeight;

  num? envMapCubeUVHeight;
  bool instancingMorph = false;
  bool alphaToCoverage = false;
  int? morphTextureStride;

  bool extensionClipCullDistance = false;
  bool extensionMultiDraw = false;

  String? mapUv;
  String? aoMapUv;
  String? lightMapUv;
  String? bumpMapUv;
  String? normalMapUv;
  String? displacementMapUv;
  String? emissiveMapUv;

  String? metalnessMapUv;
  String? roughnessMapUv;

  String? anisotropyMapUv;

  String? clearcoatMapUv;
  String? clearcoatNormalMapUv;
  String? clearcoatRoughnessMapUv;

  String? iridescenceMapUv;
  String? iridescenceThicknessMapUv;

  String? sheenColorMapUv;
  String? sheenRoughnessMapUv;

  String? specularMapUv;
  String? specularColorMapUv;
  String? specularIntensityMapUv;

  String? transmissionMapUv;
  String? thicknessMapUv;

  String? alphaMapUv;

  bool vertexUv1s = false;
  bool vertexUv2s = false;
  bool vertexUv3s = false;

  int morphAttributeCount = 0;

  bool tangentSpaceNormalMap = false;
  bool objectSpaceNormalMap = false;
  bool uvsVertexOnly = false;
  int outputEncoding = 0;

  WebGLParameters.create();

  void dispose(){
    uniforms?.clear();
  }

  WebGLParameters({
    this.shaderID,
    this.shaderType,
    this.shaderName = '',
    this.vertexShader = '',
    this.fragmentShader = '',
    this.defines,
    this.customVertexShaderID,
    this.customFragmentShaderID,
    this.isRawShaderMaterial = false,
    this.glslVersion,
    required this.precision,
    this.batching = false,
    this.instancing = false,
    this.instancingColor = false,
    this.instancingMorph = false,
    this.supportsVertexTextures = false,
    this.outputColorSpace = NoColorSpace,
    this.alphaToCoverage = false,
    this.map = false,
    this.displacementMap = false,
    this.matcap = false,
    this.envMap = false,
    this.envMapMode,
    this.envMapCubeUVHeight,
    this.lightMap = false,
    this.aoMap = false,
    this.emissiveMap = false,
    this.bumpMap = false,
    this.normalMap = false,

    this.morphAttributeCount = 0,

    this.normalMapObjectSpace = false,
    this.normalMapTangentSpace = false,
    this.roughnessMap = false,
    this.metalnessMap = false,
      
    this.anisotropy = false,
    this.anisotropyMap = false,

    this.clearcoat = false,
    this.clearcoatMap = false,
    this.clearcoatRoughnessMap = false,
    this.clearcoatNormalMap = false,

    this.dispersion = false,
    this.batchingColor = false,

    this.iridescence = false,
    this.iridescenceMap = false,
    this.iridescenceThicknessMap = false,

    this.sheen = false,
    this.sheenColorMap = false,
    this.sheenRoughnessMap = false,

    this.specularMap = false,
    this.specularIntensityMap = false,
    this.specularColorMap = false,

    this.transmission = false,
    this.transmissionMap = false,
    this.thicknessMap = false,

    this.gradientMap = false,

    this.opaque = false,

    this.alphaMap = false,
    this.alphaTest = false,
    this.alphaHash = false,

    this.combine,

    this.mapUv,
    this.aoMapUv,
    this.lightMapUv,
    this.bumpMapUv,
    this.normalMapUv,
    this.displacementMapUv,
    this.emissiveMapUv,

    this.metalnessMapUv,
    this.roughnessMapUv,

    this.anisotropyMapUv,

    this.clearcoatMapUv,
    this.clearcoatNormalMapUv,
    this.clearcoatRoughnessMapUv,

    this.iridescenceMapUv,
    this.iridescenceThicknessMapUv,

    this.sheenColorMapUv,
    this.sheenRoughnessMapUv,

    this.specularMapUv,
    this.specularColorMapUv,
    this.specularIntensityMapUv,

    this.transmissionMapUv,
    this.thicknessMapUv,

    this.alphaMapUv,

    this.vertexTangents = false,
    this.vertexColors = false,
    this.vertexAlphas = false,

    this.pointsUvs = false,
    this.fog = false,
    this.useFog = false,
    this.fogExp2 = false,

    this.flatShading = false,

    this.sizeAttenuation = false,
    this.logarithmicDepthBuffer = false,

    this.skinning = false,

    this.morphTargets = false,
    this.morphNormals = false,
    this.morphColors = false,
    this.morphTargetsCount = 0,
    this.morphTextureStride,

    this.numDirLights = 0,
    this.numPointLights = 0,
    this.numSpotLights = 0,
    this.numSpotLightMaps = 0,
    this.numRectAreaLights = 0,
    this.numHemiLights = 0,

    this.numDirLightShadows = 0,
    this.numPointLightShadows = 0,
    this.numSpotLightShadows = 0,
    this.numSpotLightShadowsWithMaps = 0,
    this.numLightProbes = 0,
    this.numClippingPlanes = 0,
    this.numClipIntersection = 0,

    this.dithering = false,

    this.shadowMapEnabled = false,
    this.shadowMapType,

    this.toneMapping,
    this.useLegacyLights = false,

    this.decodeVideoTexture = false,
    this.decodeVideoTextureEmissive = false,

    this.premultipliedAlpha = false,

    this.doubleSided = false,
    this.flipSided = false,

    this.useDepthPacking = false,
    this.depthPacking,

    this.index0AttributeName,

    this.extensionClipCullDistance = false,
    this.extensionMultiDraw = false,
    this.rendererExtensionParallelShaderCompile = false,
    this.customProgramCacheKey,
  });

  WebGLParameters.fromJson(Map<String, dynamic> json) {
    shaderID = json['shaderID'];
    shaderType = json['shaderType'];
    shaderName = json['shaderName'] ?? '';

    vertexShader = json['vertexShader'] ?? '';
    fragmentShader = json['fragmentShader'] ?? '';
    defines = json['defines'];

    customVertexShaderID = json['customVertexShaderID'];
    customFragmentShaderID = json['customFragmentShaderID'];

    isRawShaderMaterial = json['isRawShaderMaterial'] ?? false;
    glslVersion = json['glslVersion'];

    precision = json['precision'] ?? '';
    batching = json['batching'] ?? false;
    instancing = json['instancing'] ?? false;
    instancingColor = json['instancingColor'] ?? false;
    instancingMorph = json['instancingMorph'] ?? false;

    supportsVertexTextures = json['supportsVertexTextures'] ?? false;
    outputColorSpace = json['outputColorSpace'] ?? NoColorSpace;
    alphaToCoverage = json['alphaToCoverage'] ?? false;

    map = json['map'] ?? false;
    matcap = json['matcap'] ?? false;
    envMap = json['envMap'] ?? false;
    envMapMode = json['envMapMode'] ?? false;
    envMapCubeUVHeight = json['envMapCubeUVHeight'];
    lightMap = json['lightMap'] ?? false;
    aoMap = json['aoMap'] ?? false;
    emissiveMap = json['emissiveMap'] ?? false;
    bumpMap = json['bumpMap'] ?? false;
    normalMap = json['normalMap'] ?? false;

    normalMapObjectSpace = json['normalMapObjectSpace'] ?? false;
    normalMapTangentSpace = json['normalMapTangentSpace'] ?? false;
    roughnessMap = json['roughnessMap'] ?? false;
    metalnessMap = json['metalnessMap'] ?? false;
      
    anisotropy = json['anisotropy'] ?? false;
    anisotropyMap = json['anisotropyMap'] ?? false;

    clearcoat = json['clearcoat'] ?? false;
    clearcoatMap = json['clearcoatMap'] ?? false;
    clearcoatRoughnessMap = json['clearcoatRoughnessMap'] ?? false;
    clearcoatNormalMap = json['clearcoatNormalMap'] ?? false;

    displacementMap = json['displacementMap'] ?? false;

    iridescence = json['iridescence'] ?? false;
    iridescenceMap = json['iridescenceMap'] ?? false;
    iridescenceThicknessMap = json['iridescenceThicknessMap'] ?? false;

    sheen = json['sheen'] ?? false;
    sheenColorMap = json['sheenColorMap'] ?? false;
    sheenRoughnessMap = json['sheenRoughnessMap'] ?? false;

    specularMap = json['specularMap'] ?? false;
    specularIntensityMap = json['specularIntensityMap'] ?? false;
    specularColorMap = json['specularColorMap'] ?? false;

    transmission = json['transmission'] ?? false;
    transmissionMap = json['transmissionMap'] ?? false;
    thicknessMap = json['thicknessMap'] ?? false;

    gradientMap = json['gradientMap'] ?? false;

    opaque = json['opaque'] ?? false;
    dispersion = json['dispersion'] ?? false;
    batchingColor = json['batchingColor'] ?? false;

    alphaMap = json['alphaMap'] ?? false;
    alphaTest = json['alphaTest'] ?? false;
    alphaHash = json['alphaHash'] ?? false;

    combine = json['combine'];

    mapUv = json['mapUv'];
    aoMapUv = json['aoMapUv'];
    lightMapUv = json['lightMapUv'];
    bumpMapUv = json['bumpMapUv'];
    normalMapUv = json['normalMapUv'];
    displacementMapUv = json['displacementMapUv'];
    emissiveMapUv = json['emissiveMapUv'];

    metalnessMapUv = json['metalnessMapUv'];
    roughnessMapUv = json['roughnessMapUv'];

    anisotropyMapUv = json['anisotropyMapUv'];

    clearcoatMapUv = json['clearcoatMapUv'];
    clearcoatNormalMapUv = json['clearcoatNormalMapUv'];
    clearcoatRoughnessMapUv = json['clearcoatRoughnessMapUv'];

    iridescenceMapUv = json['iridescenceMapUv'];
    iridescenceThicknessMapUv = json['iridescenceThicknessMapUv'];

    sheenColorMapUv = json['sheenColorMapUv'];
    sheenRoughnessMapUv = json['sheenRoughnessMapUv'];

    specularMapUv = json['specularMapUv'];
    specularColorMapUv = json['specularColorMapUv'];
    specularIntensityMapUv = json['specularIntensityMapUv'];

    transmissionMapUv = json['transmissionMapUv'];
    thicknessMapUv = json['thicknessMapUv'];

    alphaMapUv = json['alphaMapUv'];

    vertexTangents = json['vertexTangents'] ?? false;
    vertexColors = json['vertexColors'] ?? false;
    vertexAlphas = json['vertexAlphas'] ?? false;

    vertexUvs = json['vertexUvs'] ?? false;

    fog = json['fog'] ?? false;
    useFog = json['useFog'] ?? false;
    fogExp2 = json['fogExp2'] ?? false;

    flatShading = json['flatShading'] ?? false;

    sizeAttenuation = json['sizeAttenuation'] ?? false;
    logarithmicDepthBuffer = json['logarithmicDepthBuffer'] ?? false;

    skinning = json['skinning'] ?? false;

    morphTargets = json['morphTargets'] ?? false;
    morphNormals = json['morphNormals'] ?? false;
    morphColors = json['morphColors'] ?? false;
    morphTargetsCount = json['morphTargetsCount'] ?? 0;
    morphTextureStride = json['morphTextureStride'];

    numDirLights = json['numDirLights'] ?? 0;
    numPointLights = json['numPointLights'] ?? 0;
    numSpotLights = json['numSpotLights'] ?? 0;
    numSpotLightMaps = json['numSpotLightMaps'] ?? 0;
    numRectAreaLights = json['numRectAreaLights'] ?? 0;
    numHemiLights = json['numHemiLights'] ?? 0;

    numDirLightShadows = json['numDirLightShadows'] ?? 0;
    numPointLightShadows = json['numPointLightShadows'] ?? 0;
    numSpotLightShadows = json['numSpotLightShadows'] ?? 0;
    numSpotLightShadowsWithMaps = json['numSpotLightShadowsWithMaps'] ?? 0;

    numLightProbes = json['numLightProbes'] ?? 0;

    numClippingPlanes = json['numClippingPlanes'] ?? 0;
    numClipIntersection = json['numClipIntersection'] ?? 0;

    dithering = json['dithering'] ?? false;

    shadowMapEnabled = json['shadowMapEnabled'] ?? false;
    shadowMapType = json['shadowMapType'];

    toneMapping = json['toneMapping'];
    useLegacyLights = json['useLegacyLights'] ?? false;

    decodeVideoTexture = json['decodeVideoTexture'] ?? false;
    decodeVideoTextureEmissive = json['decodeVideoTextureEmissive'] ?? false;

    premultipliedAlpha = json['premultipliedAlpha'] ?? false;

    doubleSided = json['doubleSided'] ?? false;
    flipSided = json['flipSided'] ?? false;

    useDepthPacking = json['useDepthPacking'] ?? false;
    depthPacking = json['depthPacking'];

    index0AttributeName = json['index0AttributeName'];

    pointsUvs = json['pointsUvs'] ?? false;

    extensionClipCullDistance = json['extensionClipCullDistance'] ?? false;
    extensionMultiDraw = json['extensionMultiDraw'] ?? false;

    customProgramCacheKey = json['customProgramCacheKey'];

    tangentSpaceNormalMap = json["tangentSpaceNormalMap"];
    objectSpaceNormalMap = json["objectSpaceNormalMap"];
    uvsVertexOnly = json["uvsVertexOnly"];
    outputEncoding = json["outputEncoding"];
  }

  getValue(String name) {
    Map<String, dynamic> json = toJson();

    return json[name];
  }

  toJson() {
    Map<String, dynamic> json = {
      "shaderID": shaderID,
      "customVertexShaderID": customVertexShaderID,
      "customFragmentShaderID": customFragmentShaderID,
      "shaderName": shaderName,
      "vertexShader": vertexShader,
      "fragmentShader": fragmentShader,
      "defines": defines,
      "isRawShaderMaterial": isRawShaderMaterial,
      "glslVersion": glslVersion,
      "precision": precision,
      "instancing": instancing,
      "instancingColor": instancingColor,
      "supportsVertexTextures": supportsVertexTextures,
      "outputColorSpace": outputColorSpace,
      "outputEncoding": outputEncoding,
      'opaque': opaque,
      'dispersion': dispersion,
      'batchingColor': batchingColor,
      "map": map,
      "matcap": matcap,
      "envMap": envMap,
      "envMapMode": envMapMode,
      "lightMap": lightMap,
      "aoMap": aoMap,
      "emissiveMap": emissiveMap,
      "bumpMap": bumpMap,
      "normalMap": normalMap,
      "normalMapObjectSpace": normalMapObjectSpace,
      "normalMapTangentSpace": normalMapTangentSpace,
      "clearcoat": clearcoat,
      "clearcoatMap": clearcoatMap,
      "clearcoatRoughnessMap": clearcoatRoughnessMap,
      "clearcoatNormalMap": clearcoatNormalMap,
      "displacementMap": displacementMap,
      "roughnessMap": roughnessMap,
      "metalnessMap": metalnessMap,
      "specularMap": specularMap,
      "specularIntensityMap": specularIntensityMap,
      "specularColorMap": specularColorMap,
      "alphaMap": alphaMap,
      "gradientMap": gradientMap,
      "sheenColorMap": sheenColorMap,
      "sheenRoughnessMap": sheenRoughnessMap,
      "sheen": sheen,
      "transmission": transmission,
      "transmissionMap": transmissionMap,
      "transmissionMapUv": transmissionMapUv,
      "thicknessMap": thicknessMap,
      "combine": combine,
      "vertexTangents": vertexTangents,
      "vertexColors": vertexColors,
      "vertexUvs": vertexUvs,
      "uvsVertexOnly": uvsVertexOnly,
      "pointsUvs": pointsUvs,
      "fog": fog,
      "useFog": useFog,
      "fogExp2": fogExp2,
      "flatShading": flatShading,
      "sizeAttenuation": sizeAttenuation,
      "logarithmicDepthBuffer": logarithmicDepthBuffer,
      "skinning": skinning,
      "morphTargets": morphTargets,
      "morphNormals": morphNormals,
      "morphColors": morphColors,
      "numDirLights": numDirLights,
      "numPointLights": numPointLights,
      "numSpotLights": numSpotLights,
      "numRectAreaLights": numRectAreaLights,
      "numHemiLights": numHemiLights,
      "numDirLightShadows": numDirLightShadows,
      "numPointLightShadows": numPointLightShadows,
      "numSpotLightShadows": numSpotLightShadows,
      "numClippingPlanes": numClippingPlanes,
      "numClipIntersection": numClipIntersection,
      "dithering": dithering,
      "shadowMapEnabled": shadowMapEnabled,
      "shadowMapType": shadowMapType,
      "toneMapping": toneMapping,
      "physicallyCorrectLights": physicallyCorrectLights,
      "useLegacyLights": useLegacyLights,
      "premultipliedAlpha": premultipliedAlpha,
      "alphaTest": alphaTest,
      "doubleSided": doubleSided,
      "flipSided": flipSided,
      "useDepthPacking": useDepthPacking,
      "depthPacking": depthPacking,
      "index0AttributeName": index0AttributeName,
      "extensionDerivatives": extensionDerivatives,
      "extensionFragDepth": extensionFragDepth,
      "extensionDrawBuffers": extensionDrawBuffers,
      "extensionShaderTextureLOD": extensionShaderTextureLOD,
      "rendererExtensionFragDepth": rendererExtensionFragDepth,
      "rendererExtensionDrawBuffers": rendererExtensionDrawBuffers,
      "rendererExtensionShaderTextureLod": rendererExtensionShaderTextureLod,
      "customProgramCacheKey": customProgramCacheKey,
      "uniforms": uniforms,
      "vertexAlphas": vertexAlphas,
      "decodeVideoTexture": decodeVideoTexture,
      'decodeVideoTextureEmissive': decodeVideoTextureEmissive,
      "morphTargetsCount": morphTargetsCount,
      "cubeUVHeight": cubeUVHeight,
      "envMapCubeUVHeight": envMapCubeUVHeight,
      "morphTextureStride": morphTextureStride
    };

    return json;
  }
}
