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
    final uniformData = Float32List(48 + (4 * 16 * 4));

    // [Offsets 0-31]: Matrices
    for (int i = 0; i < 16; i++) {
      uniformData[i] = projMatrix[i];
      uniformData[16 + i] = viewMatrix[i];
    }

    // [Offsets 32-35]: Camera World Position & Count
    uniformData[32] = camera.position.x;
    uniformData[33] = camera.position.y;
    uniformData[34] = camera.position.z;
    uniformData[35] = totalCount.toDouble();

    // [Offsets 36-39]: Ambient Color
    uniformData[36] = 0.0;
    uniformData[37] = 0.0;
    uniformData[38] = 0.0;
    uniformData[39] = 0.0;

    // [Offsets 40-43]: Fog Color
    final fogColor = scene.fog?.color ?? Color();
    uniformData[40] = fogColor.red;
    uniformData[41] = fogColor.green;
    uniformData[42] = fogColor.blue;
    uniformData[43] = fogColor.alpha;

    // [Offsets 44-47]: Fog Params
    uniformData[44] = scene.fog?.isFogExp2 == false ? scene.fog?.near ?? 0.0 : 0.0;
    uniformData[45] = scene.fog?.isFogExp2 == false ? scene.fog?.far ?? 0.0 : 0.0;
    uniformData[46] = (scene.fog?.isFogExp2 == true ? scene.fog?.density : 0.0) ?? 0.0;
    uniformData[47] = scene.fog?.isFogExp2 == true ? 1.0 : 0.0;

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
      uniformData[positionsBase + stride]     = light.position.x;
      uniformData[positionsBase + stride + 1] = light.position.y;
      uniformData[positionsBase + stride + 2] = light.position.z;
      uniformData[positionsBase + stride + 3] = typeToken;

      // 2. Pack lightColors[16]
      uniformData[colorsBase + stride]     = light.color?.red ?? 1.0;
      uniformData[colorsBase + stride + 1] = light.color?.green ?? 1.0;
      uniformData[colorsBase + stride + 2] = light.color?.blue ?? 1.0;
      uniformData[colorsBase + stride + 3] = light.intensity;

      // 3. Pack lightAttenuationParams[16]
      uniformData[attenuationBase + stride]     = light.distance ?? 0.0;
      uniformData[attenuationBase + stride + 1] = light.decay ?? 2.0;
      uniformData[attenuationBase + stride + 2] = light.angle ?? 0.0;
      uniformData[attenuationBase + stride + 3] = light.penumbra ?? 0.0;

      // 4. Pack lightExtendedParams[16]
      if (typeToken == 4.0 && light.groundColor != null) {
        uniformData[extendedBase + stride]     = light.groundColor!.red;
        uniformData[extendedBase + stride + 1] = light.groundColor!.green;
        uniformData[extendedBase + stride + 2] = light.groundColor!.blue;
      } else if (typeToken == 5.0) {
        uniformData[extendedBase + stride]     = light.width ?? 1.0;
        uniformData[extendedBase + stride + 1] = light.height ?? 1.0;
        uniformData[extendedBase + stride + 2] = 0.0;
      } else {
        uniformData[extendedBase + stride]     = 0.0;
        uniformData[extendedBase + stride + 1] = 0.0;
        uniformData[extendedBase + stride + 2] = 0.0;
      }
      uniformData[extendedBase + stride + 3] = 0.0;
    }

    return uniformData;
  }
}

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

  Float32List updateUniforms(Object3D mesh) {
    final material = mesh.material!;
    mesh.updateMatrixWorld();
    final modelMatrix = mesh.matrixWorld.storage;

    // Exact Footprint:
    // modelMatrix (16) + 13 vec4 vectors (13 * 4 = 52) + 6 clipping planes (6 * 4 = 24) 
    // + 1 clippingPlaneParams vector (4) = 96 floats total (384 bytes).
    final uniformData = Float32List(116);

    // ========================================================
    // 1. MODEL MATRIX (Offsets 0 - 15) -> 64 Bytes
    // ========================================================
    for (int i = 0; i < 16; i++) {
      uniformData[i] = modelMatrix[i];
    }

    // ========================================================
    // 2. MATERIAL PROPERTIES (Offsets 16 - 67)
    // ========================================================
    
    // [Offsets 16-19]: baseColor (vec4)
    uniformData[16] = baseColor?.red ?? 1.0;
    uniformData[17] = baseColor?.green ?? 1.0;
    uniformData[18] = baseColor?.blue ?? 1.0;
    uniformData[19] = baseColor?.alpha ?? 1.0;

    // [Offsets 20-23]: emissiveColor & Intensity (vec4)
    uniformData[20] = emissiveColor?.red ?? 0.0;
    uniformData[21] = emissiveColor?.green ?? 0.0;
    uniformData[22] = emissiveColor?.blue ?? 0.0;
    uniformData[23] = this.emissiveIntensity;

    // [Offsets 24-27]: pbrParams (vec4) -> roughness, metalness, flatShading, alphaTest
    uniformData[24] = this.roughness;
    uniformData[25] = this.metalness;
    uniformData[26] = (this.flatShading) ? 1.0 : 0.0;
    uniformData[27] = this.alphaTest;

    // [Offsets 28-31]: materialParams (vec4) -> shininess, clearcoat, clearcoatRoughness, wireframe
    uniformData[28] = this.shininess;
    uniformData[29] = this.clearcoat;
    uniformData[30] = this.clearcoatRoughness;
    uniformData[31] = (this.wireframe) ? 1.0 : 0.0;

    // [Offsets 32-35]: mapIntensities (vec4) -> bumpScale, envIntensity, lightMapIntensity, aoMapIntensity
    uniformData[32] = this.bumpScale;
    uniformData[33] = this.envIntensity;
    uniformData[34] = this.lightMapIntensity;
    uniformData[35] = this.aoMapIntensity;

    // [Offsets 36-39]: specularAndIOR (vec4)
    if (specularColor != null) {
      uniformData[36] = specularColor!.red * specularIntensity;
      uniformData[37] = specularColor!.green * specularIntensity;
      uniformData[38] = specularColor!.blue * specularIntensity;
    } else {
      uniformData[36] = specularIntensity;
      uniformData[37] = specularIntensity;
      uniformData[38] = specularIntensity;
    }
    uniformData[39] = this.ior;

    // [Offsets 40-43]: sheenColorAndIntensity (vec4)
    if (sheenColor != null) {
      uniformData[40] = sheenColor!.red;
      uniformData[41] = sheenColor!.green;
      uniformData[42] = sheenColor!.blue;
    } else {
      uniformData[40] = 0.0;
      uniformData[41] = 0.0;
      uniformData[42] = 0.0;
    }
    uniformData[43] = this.sheen;

    // [Offsets 44-47]: physicalAdvancedParams (vec4)
    uniformData[44] = this.sheenRoughness;
    uniformData[45] = this.reflectivity;
    uniformData[46] = this.attenuationDistance;
    uniformData[47] = this.transmission;

    // [Offsets 48-51]: attenuationColorVec & prefilterMipCount (vec4)
    if (attenuationColor != null) {
      uniformData[48] = attenuationColor!.red;
      uniformData[49] = attenuationColor!.green;
      uniformData[50] = attenuationColor!.blue;
    } else {
      uniformData[48] = 0.0;
      uniformData[49] = 0.0;
      uniformData[50] = 0.0;
    }
    uniformData[51] = (this.prefilterMipCount).toDouble();

    // [Offsets 52-55]: lineParams (vec4)
    if(material is PointsMaterial){
      uniformData[52] = (material.size ?? 1)*25;
      uniformData[53] = material.sizeAttenuation==true?1:0;
      uniformData[54] = (material.scale ?? 1)*10;
      uniformData[55] = 0;
    }
    else{
      uniformData[52] = this.linewidth;
      uniformData[53] = this.dashSize;
      uniformData[54] = this.mapLineCap(linecap).toDouble();
      uniformData[55] = this.mapLineJoin(linejoin).toDouble();
    }

    // [Offsets 56-59]: lineExtendedParams (vec4)
    uniformData[56] = this.gapSize;
    uniformData[57] = this.scale;
    uniformData[58] = 2; // ColorSpace field template fallback
    uniformData[59] = this.rotation;

    // [Offsets 60-67]: morphInfluences0 & morphInfluences1 (2 x vec4)
    final List<double>? morphInfluenceSource = mesh.morphTargetInfluences;
    for (int i = 0; i < 8; i++) {
      double val = (morphInfluenceSource != null && i < morphInfluenceSource.length) 
          ? morphInfluenceSource[i] 
          : 0.0;
      uniformData[60 + i] = val;
    }

    // ========================================================
    // 3. CLIPPING PLANES (Offsets 68 - 91) -> 6 planes * vec4
    // ========================================================
    for (int i = 0; i < 6; i++) {
      final int planeOffset = 68 + (i * 4);
      if (i < clippingPlanes.length) {
        final plane = clippingPlanes[i];
        uniformData[planeOffset + 0] = plane.normal.x;
        uniformData[planeOffset + 1] = plane.normal.y;
        uniformData[planeOffset + 2] = plane.normal.z;
        uniformData[planeOffset + 3] = plane.constant;
      } else {
        uniformData[planeOffset + 0] = 0.0;
        uniformData[planeOffset + 1] = 0.0;
        uniformData[planeOffset + 2] = 0.0;
        uniformData[planeOffset + 3] = 0.0;
      }
    }

    // ========================================================
    // 4. TAILING SCALAR + PADDING (Offsets 92 - 95) -> vec4
    // ========================================================
    uniformData[92] = clippingPlanes.length.toDouble(); // material.clippingPlaneParams.x

    double checkMap(Texture? prop) => prop != null ? 1 : 0;
    uniformData[93]  = checkMap(material.map);                        // 0: hasMap
    uniformData[94]  = checkMap(material.alphaMap);                   // 1: hasAlphaMap
    uniformData[95]  = checkMap(material.aoMap);                      // 2: hasAoMap
    
    uniformData[96]  = checkMap(material.specularMap);                // 3: hasSpecularMap
    uniformData[97]  = checkMap(material.lightMap);                   // 4: hasLightMap
    uniformData[98]  = checkMap(material.bumpMap);                    // 5: hasBumpMap
    uniformData[99]  = checkMap(material.normalMap);                  // 6: hasNormalMap
    
    uniformData[100] = checkMap(material.displacementMap);            // 7: hasDisplacementMap
    uniformData[101] = checkMap(material.roughnessMap);               // 8: hasRoughnessMap
    uniformData[102] = checkMap(material.metalnessMap);               // 9: hasMetalnessMap
    uniformData[103] = checkMap(material.emissiveMap);                // 10: hasEmissiveMap
    
    uniformData[104] = checkMap(material.clearcoatMap);               // 11: hasClearcoatMap
    uniformData[105] = checkMap(material.clearcoatNormalMap);         // 12: hasClearcoatNormalMap
    uniformData[106] = checkMap(material.clearcoatRoughnessMap);      // 13: hasClearcoatRoughnessMap
    uniformData[107] = checkMap(material.sheenColorMap);              // 14: hasSheenColorMap
    
    uniformData[108] = checkMap(material.sheenRoughnessMap);          // 15: hasSheenRoughnessMap
    uniformData[109] = checkMap(material.transmissionMap);            // 16: hasTransmissionMap
    uniformData[110] = checkMap(material.thicknessMap);               // 17: hasThicknessMap
    uniformData[111] = checkMap(material.iridescenceMap);             // 18: hasIridescenceMap
    
    uniformData[112] = checkMap(material.iridescenceThicknessMap);    // 19: hasIridescenceThicknessMap
    uniformData[113] = checkMap(material.gradientMap);                // 20: hasGradientMap
    uniformData[114] = checkMap(material.matcap);                     // 21: hasMatcap

    uniformData[115] = 0.0;

    return uniformData;
  }
}
