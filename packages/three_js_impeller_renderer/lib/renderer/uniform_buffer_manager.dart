import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
// import '../material/material_description_registry.dart';
// import 'buffer.dart'; // To interface with Mesh, Camera, Vector3, etc.

class FrameDebugInfo {
  final int frameCount;
  final int drawCallCount;

  const FrameDebugInfo({
    required this.frameCount,
    required this.drawCallCount,
  });
}

final Float32List _sceneData = Float32List(48 + (4 * 16 * 4));

class SceneUniformData {
  final int lightCount;
  final Float32List cameraPosition;
  final Float32List ambientColor;
  final Float32List fogColor;
  final Float32List fogParams;
  final Float32List lightDirection;
  final Float32List lightColor;

  const SceneUniformData({
    required this.cameraPosition,
    required this.ambientColor,
    required this.fogColor,
    required this.fogParams,
    required this.lightDirection,
    required this.lightColor,
    required this.lightCount,
  });

  static Float32List updateUniforms({
    required Camera camera,
    required Scene scene,
    List<Light>? activeLights,
  }) {
    final lightsList = activeLights ?? const [];
    final int totalCount = lightsList.length;

    camera.updateMatrixWorld();
    final projMatrix = camera.projectionMatrix.storage;
    final viewMatrix = camera.matrixWorldInverse.storage;

    // Total size layout footprint matching GLSL:
    // Header: 48 floats
    // Arrays: 4 arrays * 16 elements * 4 floats = 256 floats
    // Total allocation size = 304 floats

    // [Offsets 0-31]: Matrices
    for (int i = 0; i < 16; i++) {
      _sceneData[i] = projMatrix[i];
      _sceneData[16 + i] = viewMatrix[i];
    }

    // [Offsets 32-35]: Camera World Position & Count
    _sceneData[32] = camera.position.x;
    _sceneData[33] = camera.position.y;
    _sceneData[34] = camera.position.z;
    _sceneData[35] = totalCount.toDouble();

    // [Offsets 36-39]: Ambient Color
    _sceneData[36] = 0.0;
    _sceneData[37] = 0.0;
    _sceneData[38] = 0.0;
    _sceneData[39] = 0.0;

    // [Offsets 40-43]: Fog Color
    final fogColor = scene.fog?.color ?? Color();
    _sceneData[40] = fogColor.red;
    _sceneData[41] = fogColor.green;
    _sceneData[42] = fogColor.blue;
    _sceneData[43] = fogColor.alpha;

    // [Offsets 44-47]: Fog Params
    _sceneData[44] = scene.fog?.isFogExp2 == false ? scene.fog?.near ?? 0.0 : 0.0;
    _sceneData[45] = scene.fog?.isFogExp2 == false ? scene.fog?.far ?? 0.0 : 0.0;
    _sceneData[46] = (scene.fog?.isFogExp2 == true ? scene.fog?.density : 0.0) ?? 0.0;
    _sceneData[47] = scene.fog?.isFogExp2 == true ? 1.0 : 0.0;

    // Base pointer coordinates for sequential parallel blocks
    final int positionsBase     = 48;
    final int colorsBase        = 48 + (16 * 4);       // Offset 112
    final int attenuationBase   = 48 + (16 * 4 * 2);   // Offset 176
    final int extendedBase      = 48 + (16 * 4 * 3);   // Offset 240

    // Serialize each block sequentially to align perfectly with GLSL std140
    for (int i = 0; i < totalCount; i++) {
      final Light light = lightsList[i];
      final int stride = i * 4;

      double typeToken = 1.0; 
      if (light is AmbientLight) typeToken = 6.0;
      else if (light is PointLight) typeToken = 2.0;
      else if (light is SpotLight) typeToken = 3.0;
      else if (light is HemisphereLight) typeToken = 4.0;
      else if (light is RectAreaLight) typeToken = 5.0;

      // 1. Pack lightPositions[16]
      _sceneData[positionsBase + stride]     = light.position.x;
      _sceneData[positionsBase + stride + 1] = light.position.y;
      _sceneData[positionsBase + stride + 2] = light.position.z;
      _sceneData[positionsBase + stride + 3] = typeToken;

      // 2. Pack lightColors[16]
      _sceneData[colorsBase + stride]     = light.color?.red ?? 1.0;
      _sceneData[colorsBase + stride + 1] = light.color?.green ?? 1.0;
      _sceneData[colorsBase + stride + 2] = light.color?.blue ?? 1.0;
      _sceneData[colorsBase + stride + 3] = light.intensity;

      // 3. Pack lightAttenuationParams[16]
      _sceneData[attenuationBase + stride]     = light.distance ?? 0.0;
      _sceneData[attenuationBase + stride + 1] = light.decay ?? 2.0;
      _sceneData[attenuationBase + stride + 2] = light.angle ?? 0.0;
      _sceneData[attenuationBase + stride + 3] = light.penumbra ?? 0.0;

      // 4. Pack lightExtendedParams[16]
      if (typeToken == 4.0 && light.groundColor != null) {
        _sceneData[extendedBase + stride]     = light.groundColor!.red;
        _sceneData[extendedBase + stride + 1] = light.groundColor!.green;
        _sceneData[extendedBase + stride + 2] = light.groundColor!.blue;
      } else if (typeToken == 5.0) {
        _sceneData[extendedBase + stride]     = light.width ?? 1.0;
        _sceneData[extendedBase + stride + 1] = light.height ?? 1.0;
        _sceneData[extendedBase + stride + 2] = 0.0;
      } else {
        _sceneData[extendedBase + stride]     = 0.0;
        _sceneData[extendedBase + stride + 1] = 0.0;
        _sceneData[extendedBase + stride + 2] = 0.0;
      }
      _sceneData[extendedBase + stride + 3] = 0.0;
    }

    return _sceneData;
  }
}

final _uniformData = Float32List(156);

class MaterialUniformData {
  final List<Plane> clippingPlanes;
  final Color? baseColor;       // r, g, b, opacity
  final Color? emissiveColor;   // r, g, b
  final double emissiveIntensity;
  final double roughness;
  final double metalness;
  final double envIntensity;
  final int prefilterMipCount;
  final bool flatShading;
  final double alphaTest;

  // Blinn-Phong & General Configs
  final double shininess;
  final bool wireframe;

  // MeshPhysicalMaterial Specifics
  final double clearcoat;
  final double clearcoatRoughness;
  final Color? specularColor;  // r, g, b
  final double specularIntensity;
  final double ior;
  final Color? sheenColor;     // r, g, b
  final double sheen;
  final double sheenRoughness;
  final double reflectivity;
  final double transmission;
  final double attenuationDistance;
  final Color? attenuationColor; // r, g, b

  // Map Scaling Factors
  final double bumpScale;
  final double lightMapIntensity;
  final double aoMapIntensity;

  final double rotation;

  // Line & Dash Material Specifics
  final double linewidth;
  final double dashSize;
  final double gapSize;
  final double scale;
  final String linecap;                  // 0 = Round, 1 = Square, 2 = Butt
  final String linejoin;                 // 0 = Round, 1 = Bevel,  2 = Miter

  const MaterialUniformData({
    required this.baseColor,
    this.emissiveColor,
    this.emissiveIntensity = 1.0,
    required this.roughness,
    required this.metalness,
    required this.envIntensity,
    required this.prefilterMipCount,
    required this.flatShading,
    this.alphaTest = 0.0,
    this.shininess = 30.0,
    this.wireframe = false,
    this.clearcoat = 0.0,
    this.clearcoatRoughness = 0.0,
    this.specularColor,
    this.specularIntensity = 1.0,
    this.ior = 1.5,
    this.sheenColor,
    this.sheen = 0.0,
    this.sheenRoughness = 1.0,
    this.reflectivity = 0.5,
    this.transmission = 0.0,
    this.attenuationDistance = 0.0,
    this.attenuationColor,
    this.bumpScale = 1.0,
    this.lightMapIntensity = 1.0,
    this.aoMapIntensity = 1.0,
    this.linewidth = 1.0,
    this.dashSize = 0.0,
    this.gapSize = 0.0,
    this.scale = 1.0,
    this.linecap = 'square',
    this.linejoin = 'bevel',
    this.rotation = 0.0,
    required this.clippingPlanes,
  });

  // Line Cap Integer Constants
  final int lineCapRound = 0;
  final int lineCapSquare = 1;
  final int lineCapButt = 2;

  /// Maps WebGL linecap strings ('round', 'square', 'butt') to integer tokens.
  int mapLineCap(String? cap) {
    if (cap == null) return lineCapRound;
    
    // Clean string inputs to handle accidental case variances
    final normalized = cap.toLowerCase().trim();
    
    if (normalized == 'square') return lineCapSquare;
    if (normalized == 'butt') return lineCapButt;
    
    return lineCapRound; // Default WebGL fallback
  }

  // Line Join Integer Constants
  final int lineJoinRound = 0;
  final int lineJoinBevel = 1;
  final int lineJoinMiter = 2;

  /// Maps WebGL linejoin strings ('round', 'bevel', 'miter') to integer tokens.
  int mapLineJoin(String? join) {
    if (join == null) return lineJoinRound;
    
    final normalized = join.toLowerCase().trim();
    
    if (normalized == 'bevel') return lineJoinBevel;
    if (normalized == 'miter') return lineJoinMiter;
    
    return lineJoinRound; // Default WebGL fallback
  }

  Float32List updateUniforms(Object3D object) {
    final material = object.material!;
    object.updateMatrixWorld();
    final modelMatrix = object.matrixWorld.storage;

    // Exact Footprint:
    // modelMatrix (16) + 13 vec4 vectors (13 * 4 = 52) + 6 clipping planes (6 * 4 = 24) 
    // + 1 clippingPlaneParams vector (4) = 96 floats total (384 bytes).
    
    int last = 119;

    // ========================================================
    // 1. MODEL MATRIX (Offsets 0 - 15) -> 64 Bytes
    // ========================================================
    for (int i = 0; i < 16; i++) {
      _uniformData[i] = modelMatrix[i];
      _uniformData[last+i] = object.bindMatrix?[i] ?? 0.0;
      _uniformData[last+16+i] = object is SkinnedMesh?object.bindMatrixInverse[i]:0.0;
    }

    // ========================================================
    // 2. MATERIAL PROPERTIES (Offsets 16 - 67)
    // ========================================================
    
    // [Offsets 16-19]: baseColor (vec4)
    _uniformData[16] = baseColor?.red ?? 1.0;
    _uniformData[17] = baseColor?.green ?? 1.0;
    _uniformData[18] = baseColor?.blue ?? 1.0;
    _uniformData[19] = baseColor?.alpha ?? 1.0;

    // [Offsets 20-23]: emissiveColor & Intensity (vec4)
    _uniformData[20] = emissiveColor?.red ?? 0.0;
    _uniformData[21] = emissiveColor?.green ?? 0.0;
    _uniformData[22] = emissiveColor?.blue ?? 0.0;
    _uniformData[23] = this.emissiveIntensity;

    // [Offsets 24-27]: pbrParams (vec4) -> roughness, metalness, flatShading, alphaTest
    _uniformData[24] = this.roughness;
    _uniformData[25] = this.metalness;
    _uniformData[26] = (this.flatShading) ? 1.0 : 0.0;
    _uniformData[27] = this.alphaTest;

    // [Offsets 28-31]: materialParams (vec4) -> shininess, clearcoat, clearcoatRoughness, wireframe
    _uniformData[28] = this.shininess;
    _uniformData[29] = this.clearcoat;
    _uniformData[30] = this.clearcoatRoughness;
    _uniformData[31] = (this.wireframe) ? 1.0 : 0.0;

    // [Offsets 32-35]: mapIntensities (vec4) -> bumpScale, envIntensity, lightMapIntensity, aoMapIntensity
    _uniformData[32] = this.bumpScale;
    _uniformData[33] = this.envIntensity;
    _uniformData[34] = this.lightMapIntensity;
    _uniformData[35] = this.aoMapIntensity;

    // [Offsets 36-39]: specularAndIOR (vec4)
    if (specularColor != null) {
      _uniformData[36] = specularColor!.red * specularIntensity;
      _uniformData[37] = specularColor!.green * specularIntensity;
      _uniformData[38] = specularColor!.blue * specularIntensity;
    } else {
      _uniformData[36] = specularIntensity;
      _uniformData[37] = specularIntensity;
      _uniformData[38] = specularIntensity;
    }
    _uniformData[39] = this.ior;

    // [Offsets 40-43]: sheenColorAndIntensity (vec4)
    if (sheenColor != null) {
      _uniformData[40] = sheenColor!.red;
      _uniformData[41] = sheenColor!.green;
      _uniformData[42] = sheenColor!.blue;
    } else {
      _uniformData[40] = 0.0;
      _uniformData[41] = 0.0;
      _uniformData[42] = 0.0;
    }
    _uniformData[43] = this.sheen;

    // [Offsets 44-47]: physicalAdvancedParams (vec4)
    _uniformData[44] = this.sheenRoughness;
    _uniformData[45] = this.reflectivity;
    _uniformData[46] = this.attenuationDistance;
    _uniformData[47] = this.transmission;

    // [Offsets 48-51]: attenuationColorVec & prefilterMipCount (vec4)
    if (attenuationColor != null) {
      _uniformData[48] = attenuationColor!.red;
      _uniformData[49] = attenuationColor!.green;
      _uniformData[50] = attenuationColor!.blue;
    } else {
      _uniformData[48] = 0.0;
      _uniformData[49] = 0.0;
      _uniformData[50] = 0.0;
    }
    _uniformData[51] = (this.prefilterMipCount).toDouble();

    // [Offsets 52-55]: lineParams (vec4)
    if(material is PointsMaterial){
      _uniformData[52] = (material.size ?? 1);
      _uniformData[53] = material.sizeAttenuation==true?1:0;
      _uniformData[54] = (material.scale ?? 1)*250;
      _uniformData[55] = 0;
    }
    else{
      _uniformData[52] = this.linewidth;
      _uniformData[53] = this.dashSize;
      _uniformData[54] = this.mapLineCap(linecap).toDouble();
      _uniformData[55] = this.mapLineJoin(linejoin).toDouble();
    }

    // [Offsets 56-59]: lineExtendedParams (vec4)
    _uniformData[56] = this.gapSize;
    _uniformData[57] = this.scale;
    _uniformData[58] = 2; // ColorSpace field template fallback
    _uniformData[59] = this.rotation;

    // [Offsets 60-67]: morphInfluences0 & morphInfluences1 (2 x vec4)
    final List<double>? morphInfluenceSource = object.morphTargetInfluences;
    for (int i = 0; i < 8; i++) {
      double val = (morphInfluenceSource != null && i < morphInfluenceSource.length) 
          ? morphInfluenceSource[i] 
          : 0.0;
      _uniformData[60 + i] = val;
    }

    // ========================================================
    // 3. CLIPPING PLANES (Offsets 68 - 91) -> 6 planes * vec4
    // ========================================================
    for (int i = 0; i < 6; i++) {
      final int planeOffset = 68 + (i * 4);
      if (i < clippingPlanes.length) {
        final plane = clippingPlanes[i];
        _uniformData[planeOffset + 0] = plane.normal.x;
        _uniformData[planeOffset + 1] = plane.normal.y;
        _uniformData[planeOffset + 2] = plane.normal.z;
        _uniformData[planeOffset + 3] = plane.constant;
      } else {
        _uniformData[planeOffset + 0] = 0.0;
        _uniformData[planeOffset + 1] = 0.0;
        _uniformData[planeOffset + 2] = 0.0;
        _uniformData[planeOffset + 3] = 0.0;
      }
    }

    // ========================================================
    // 4. TAILING SCALAR + PADDING (Offsets 92 - 95) -> vec4
    // ========================================================
    _uniformData[92] = clippingPlanes.length.toDouble(); // material.clippingPlaneParams.x
    _uniformData[93] = material.clipIntersection?clippingPlanes.length.toDouble():0.0; // material.clippingPlaneParams.x
    _uniformData[94] = material.alphaToCoverage?1.0:0.0; // material.clippingPlaneParams.x
    _uniformData[95] = 0.0; //padding

    double checkMap(Texture? prop) => prop != null ? 1 : 0;
    bool hasBone = object.skeleton?.boneTexture != null;
    bool hasMorph = object.geometry?.morphAttributes["position"] != null;
    
    _uniformData[96]  = hasBone?1:hasMorph?1:0; //padding
    _uniformData[97]  = checkMap(material.map);                        // 0: hasMap
    _uniformData[98]  = checkMap(material.alphaMap);                   // 1: hasAlphaMap
    _uniformData[99]  = checkMap(material.aoMap);                      // 2: hasAoMap
    
    _uniformData[100]  = checkMap(material.specularMap);                // 3: hasSpecularMap
    _uniformData[101]  = checkMap(material.lightMap);                   // 4: hasLightMap
    _uniformData[102]  = checkMap(material.bumpMap);                    // 5: hasBumpMap
    _uniformData[103]  = checkMap(material.normalMap);                  // 6: hasNormalMap
    
    _uniformData[104] = checkMap(material.displacementMap);            // 7: hasDisplacementMap
    _uniformData[105] = checkMap(material.roughnessMap);               // 8: hasRoughnessMap
    _uniformData[106] = checkMap(material.metalnessMap);               // 9: hasMetalnessMap
    _uniformData[107] = checkMap(material.emissiveMap);                // 10: hasEmissiveMap
    
    _uniformData[108] = checkMap(material.clearcoatMap);               // 11: hasClearcoatMap
    _uniformData[109] = checkMap(material.clearcoatNormalMap);         // 12: hasClearcoatNormalMap
    _uniformData[110] = checkMap(material.clearcoatRoughnessMap);      // 13: hasClearcoatRoughnessMap
    _uniformData[111] = checkMap(material.sheenColorMap);              // 14: hasSheenColorMap
    
    _uniformData[112] = checkMap(material.sheenRoughnessMap);          // 15: hasSheenRoughnessMap
    _uniformData[113] = checkMap(material.transmissionMap);            // 16: hasTransmissionMap
    _uniformData[114] = checkMap(material.thicknessMap);               // 17: hasThicknessMap
    _uniformData[115] = checkMap(material.iridescenceMap);             // 18: hasIridescenceMap
    
    _uniformData[116] = checkMap(material.iridescenceThicknessMap);    // 19: hasIridescenceThicknessMap
    _uniformData[117] = checkMap(material.gradientMap);                // 20: hasGradientMap
    _uniformData[118] = checkMap(material.matcap);                     // 21: hasMatcap
    _uniformData[119] = object is InstancedMesh?object.instanceColor!=null?2:1:0;                   // 22: hasInstancingTexture
    
    /// 152 - 155 boneTextureParm
    final double morphCount = object.geometry?.morphAttributes["position"]?.length.toDouble()??0;
    final double boneSize = object.skeleton?.boneTextureSize.toDouble() ?? 0;
    final double vertexCount = object.geometry?.attributes["position"]?.length.toDouble();
    _uniformData[152] = hasBone?boneSize:(hasMorph?morphCount:0.0);
    if (object is InstancedMesh) {
      _uniformData[153] = vertexCount; // This slot remains open for your structural features
      
      // 1. Fetch raw total floating point data components
      final int matrixFloats = object.instanceMatrix?.length ?? 0; // 16000
      final int colorFloats = object.instanceColor?.length ?? 0;   // 3000
      final int totalFloats = matrixFloats + colorFloats~/4;          // 19000
      // 2. FIXED: Calculate height using float division and ceil it!
      // 19000 / 16 = 1187.5 -> .ceil() becomes exactly 1188.0 rows
      final double calculatedTexHeight = (totalFloats).ceilToDouble();

      // 3. Lock clean distinct properties to your uniform buffer slots
      _uniformData[154] = calculatedTexHeight; // boneTextureParm.z: Total True Height (1188.0)
      _uniformData[155] = object.count?.toDouble() ?? 0.0; // boneTextureParm.w: Matrix Rows Cutoff (1000.0)
    }

    return _uniformData;
  }
}
