import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/renderer.dart';
import 'package:three_js_math/three_js_math.dart';
// import '../material/material_description_registry.dart';
// import 'buffer.dart'; // To interface with Mesh, Camera, Vector3, etc.

enum LineCap{round,square,butt}
enum LineJoint{round,bevel,miter}

class FrameDebugInfo {
  final int frameCount;
  final int drawCallCount;

  const FrameDebugInfo({
    required this.frameCount,
    required this.drawCallCount,
  });
}

final _m1 = Matrix4();
final _m2 = Matrix4();

class SceneUniformData {
  final Float32List sceneData = Float32List(16 + (4 * 16 * 4));
  final Scene scene;
  final List<Light>? activeLights;
  final ImpellerRenderer renderer;

  SceneUniformData(this.scene, this.renderer, this.activeLights){
    updateUniforms();
  }

  void updateUniforms() {
    final lightsList = activeLights ?? const [];
    final int totalCount = lightsList.length;

    final envMatrix = _m1.makeRotationFromEuler( scene.environmentRotation );
    final bgMatrix = _m2.makeRotationFromEuler( scene.backgroundRotation );

    for(int i = 0; i < 16; i++){
      sceneData[i] = bgMatrix.storage[i];
      sceneData[i+16] = envMatrix.storage[i];
    }

    int x = 32;

    sceneData[x++] = scene.backgroundIntensity;
    sceneData[x++] = scene.background is Texture && scene.background?.flipY != null?1:0;
    sceneData[x++] = scene.background == null?0:scene.background is CubeTexture?2:1;
    sceneData[x++] = scene.backgroundBlurriness;

    sceneData[x++] = scene.environmentIntensity;
    sceneData[x++] = scene.environment?.flipY != null?1:0;
    sceneData[x++] = scene.environment == null?0:scene.environment is CubeTexture?2:1;
    sceneData[x++] = totalCount.toDouble();

    sceneData[x++] = renderer.toneMapping.toDouble();
    sceneData[x++] = renderer.toneMappingExposure;
    sceneData[x++] = ColorSpace.fromString(renderer.outputColorSpace).index.toDouble();
    sceneData[x++] = 0;

    // [Offsets 40-43]: Fog Color
    final fogColor = scene.fog?.color ?? Color();
    sceneData[x++] = fogColor.red;
    sceneData[x++] = fogColor.green;
    sceneData[x++] = fogColor.blue;
    sceneData[x++] = fogColor.alpha;

    // [Offsets 44-47]: Fog Params
    sceneData[x++] = scene.fog?.isFogExp2 == false ? scene.fog?.near ?? 0.0 : 0.0;
    sceneData[x++] = scene.fog?.isFogExp2 == false ? scene.fog?.far ?? 0.0 : 0.0;
    sceneData[x++] = (scene.fog?.isFogExp2 == true ? scene.fog?.density : 0.0) ?? 0.0;
    sceneData[x++] = scene.fog?.isFogExp2 == true ? 1.0 : 0.0;

    // Base pointer coordinates for sequential parallel blocks
    final int positionsBase     = x;
    final int colorsBase        = x + (16 * 4);       // Offset 112
    final int attenuationBase   = x + (16 * 4 * 2);   // Offset 176
    final int extendedBase      = x + (16 * 4 * 3);   // Offset 240

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
      sceneData[positionsBase + stride]     = light.position.x;
      sceneData[positionsBase + stride + 1] = light.position.y;
      sceneData[positionsBase + stride + 2] = light.position.z;
      sceneData[positionsBase + stride + 3] = typeToken;

      // 2. Pack lightColors[16]
      sceneData[colorsBase + stride]     = light.color?.red ?? 1.0;
      sceneData[colorsBase + stride + 1] = light.color?.green ?? 1.0;
      sceneData[colorsBase + stride + 2] = light.color?.blue ?? 1.0;
      sceneData[colorsBase + stride + 3] = light.intensity;

      // 3. Pack lightAttenuationParams[16]
      sceneData[attenuationBase + stride]     = light.distance ?? 0.0;
      sceneData[attenuationBase + stride + 1] = light.decay ?? 2.0;
      sceneData[attenuationBase + stride + 2] = light.angle ?? 0.0;
      sceneData[attenuationBase + stride + 3] = light.penumbra ?? 0.0;

      // 4. Pack lightExtendedParams[16]
      if (typeToken == 4.0 && light.groundColor != null) {
        sceneData[extendedBase + stride]     = light.groundColor!.red;
        sceneData[extendedBase + stride + 1] = light.groundColor!.green;
        sceneData[extendedBase + stride + 2] = light.groundColor!.blue;
      } else if (typeToken == 5.0) {
        sceneData[extendedBase + stride]     = light.width ?? 1.0;
        sceneData[extendedBase + stride + 1] = light.height ?? 1.0;
        sceneData[extendedBase + stride + 2] = 0.0;
      } else {
        sceneData[extendedBase + stride]     = 0.0;
        sceneData[extendedBase + stride + 1] = 0.0;
        sceneData[extendedBase + stride + 2] = 0.0;
      }
      sceneData[extendedBase + stride + 3] = 0.0;
    }
  }
}

class UniformData {
  Object3D object;
  Camera camera;
  final data = Float32List(192);

  UniformData(this.object,this.camera){
    create();
  }

  void update(){
    create(false);
  }

  void create([bool forceUpdate = true]) {
    if(forceUpdate) object.updateMatrixWorld(true);
    
    final material = object.material!;
    final modelMatrix = material.uniforms['uvTransform']!=null?material.uniforms['uvTransform']:object.matrixWorld.storage;
    final projMatrix = camera.projectionMatrix.storage;
    final viewMatrix = camera.matrixWorldInverse.storage;
    
		if ( object is SkinnedMesh ) {
			object.skeleton?.update();
		}

    for (int i = 0; i < 16; i++) {
      data[i] = modelMatrix[i];
      data[i+16] = projMatrix[i];
      data[i+32] = viewMatrix[i];
      data[i+48] = object.bindMatrix?.storage[i] ?? 0.0;
      data[i+64] = object is SkinnedMesh?(object as SkinnedMesh).bindMatrixInverse.storage[i]:0.0;
    }

    int x = 80;

    // camera (vec4)
    data[x++] = camera.position.x;
    data[x++] = camera.position.y;
    data[x++] = camera.position.z;
    data[x++] = camera is OrthographicCamera?1:0;

    // baseColor (vec4)
    data[x++] = material.color.red;
    data[x++] = material.color.green;
    data[x++] = material.color.blue;
    data[x++] = material.opacity;

    // [Offsets 20-23]: emissiveColor & Intensity (vec4)
    data[x++] = material.emissive?.red ?? 0.0;
    data[x++] = material.emissive?.green ?? 0.0;
    data[x++] = material.emissive?.blue ?? 0.0;
    data[x++] = material.emissiveIntensity;

    // [Offsets 24-27]: pbrParams (vec4) -> roughness, metalness, flatShading, alphaTest
    data[x++] = material.roughness;
    data[x++] = material.metalness;
    data[x++] = (material.flatShading) ? 1.0 : 0.0;
    data[x++] = material.alphaTest;

    // [Offsets 28-31]: materialParams (vec4) -> shininess, clearcoat, clearcoatRoughness, wireframe
    data[x++] = material.shininess ?? 30;
    data[x++] = material.clearcoat;
    data[x++] = material.clearcoatRoughness ?? 0;
    data[x++] = (material.wireframe) ? 1.0 : 0.0;

    // [Offsets 32-35]: mapIntensities (vec4) -> bumpScale, envIntensity, lightMapIntensity, aoMapIntensity
    data[x++] = material.bumpScale ?? 1;
    data[x++] = material.envMapIntensity ?? 1.0;
    data[x++] = material.lightMapIntensity ?? 1;
    data[x++] = material.aoMapIntensity ?? 1;

    // [Offsets 36-39]: specularAndIOR (vec4)
    double specularIntensity = material.specularIntensity ?? 1;
    if (material.specularColor != null) {
      data[x++] = material.specularColor!.red * specularIntensity;
      data[x++] = material.specularColor!.green * specularIntensity;
      data[x++] = material.specularColor!.blue * specularIntensity;
    } else {
      data[x++] = specularIntensity;
      data[x++] = specularIntensity;
      data[x++] = specularIntensity;
    }
    data[x++] = material.ior ?? 1.5;

    // [Offsets 40-43]: sheenColorAndIntensity (vec4)
    if (material.sheenColor != null) {
      data[x++] = material.sheenColor!.red;
      data[x++] = material.sheenColor!.green;
      data[x++] = material.sheenColor!.blue;
    } else {
      data[x++] = 0.0;
      data[x++] = 0.0;
      data[x++] = 0.0;
    }
    data[x++] = material.sheen;

    // [Offsets 44-47]: physicalAdvancedParams (vec4)
    data[x++] = material.sheenRoughness;
    data[x++] = material.reflectivity ?? 0.5;
    data[x++] = material.attenuationDistance ?? 0;
    data[x++] = material.transmission;

    // [Offsets 48-51]: attenuationColorVec & prefilterMipCount (vec4)
    if (material.attenuationColor != null) {
      data[x++] = material.attenuationColor!.red;
      data[x++] = material.attenuationColor!.green;
      data[x++] = material.attenuationColor!.blue;
    } else {
      data[x++] = 0.0;
      data[x++] = 0.0;
      data[x++] = 0.0;
    }
    data[x++] = material.attenuationDistance ?? 0;//(material.prefilterMipCount).toDouble();

    // [Offsets 52-55]: lineParams (vec4)
    if(material is PointsMaterial){
      data[x++] = (material.size ?? 1);
      data[x++] = material.sizeAttenuation==true?1:0;
      data[x++] = (material.scale ?? 1)*250;
      data[x++] = 0;
    }
    else if(material is LineDashedMaterial){
      data[x++] = material.linewidth ?? 1.0;
      data[x++] = material.dashSize ?? 0;
      data[x++] = mapLineCap(material.linecap).toDouble();
      data[x++] = mapLineJoin(material.linejoin).toDouble();
    }
    else if(material is MeshPhongMaterial){
      data[x++] = material.ior ?? 0;
      data[x++] = material.thickness ?? 1;
      data[x++] = 1.0;
      data[x++] = 0;
    }
    else{
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
    }

    // [Offsets 56-59]: lineExtendedParams (vec4)
    data[x++] = material.gapSize ?? 0;
    data[x++] = material.scale ?? 1.0;
    data[x++] = 2; // ColorSpace field template fallback
    data[x++] = material.rotation;

    data[x++] = material.displacementScale ?? 0;
    data[x++] = material.displacementBias ?? 0;

    data[x++] = material.blending.toDouble();
    data[x++] = 0;

    // ========================================================
    // 3. CLIPPING PLANES (Offsets 68 - 91) -> 6 planes * vec4
    // ========================================================
    for (int i = 0; i < 6; i++) {
      if (i < (material.clippingPlanes?.length ?? 0)) {
        final plane = material.clippingPlanes![i];
        data[x++] = plane.normal.x;
        data[x++] = plane.normal.y;
        data[x++] = plane.normal.z;
        data[x++] = plane.constant;
      } else {
        data[x++] = 0.0;
        data[x++] = 0.0;
        data[x++] = 0.0;
        data[x++] = 0.0;
      }
    }

    // ========================================================
    // 4. TAILING SCALAR + PADDING (Offsets 92 - 95) -> vec4
    // ========================================================
    data[x++] = material.clippingPlanes?.length.toDouble() ?? 0; // material.clippingPlaneParams.x
    data[x++] = material.clipIntersection?material.clippingPlanes!.length.toDouble():0.0; // material.clippingPlaneParams.x
    data[x++] = material.alphaToCoverage?1.0:0.0; // material.clippingPlaneParams.x
    data[x++] = 0.0; //padding

    final double boneSize = object.skeleton?.boneTextureSize.toDouble() ?? 0;
    final double morphCount = object.geometry?.morphAttributes["position"]?.length.toDouble()??0;
    final double vertexCount = object.geometry?.attributes["position"]?.length.toDouble()??0;
    data[x++] = boneSize;
    data[x++] = morphCount;
    data[x++] = vertexCount;
    data[x++] = 0;

    // instanceTextureParm
    if (object is InstancedMesh) {
      data[x++] = 0;
      data[x++] = vertexCount; // This slot remains open for your structural features
      
      final int matrixFloats = object.instanceMatrix?.length ?? 0; // 16000
      final int colorFloats = object.instanceColor?.length ?? 0;   // 3000
      final int totalFloats = matrixFloats + colorFloats~/4;          // 19000
      final double calculatedTexHeight = (totalFloats).ceilToDouble();

      data[x++] = calculatedTexHeight; // boneTextureParm.z: Total True Height (1188.0)
      data[x++] = object.count?.toDouble() ?? 0.0; // boneTextureParm.w: Matrix Rows Cutoff (1000.0)
    }
    else if (object is BatchedMesh) {
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
    }
    else{
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
      data[x++] = 0;
    }

    // flag0 x
    bool hasBone = object.skeleton?.boneTexture != null;
    bool hasMorph = object.geometry?.morphAttributes["position"] != null;
    data[x++] = hasBone?1:hasMorph?2:0;
    flags(material,x);
  }

  void flags(Material material, int x){
    double checkMap(Texture? prop) => prop != null ? 1 : 0;

    data[x++]  = checkMap(material.map);                        // hasMap
    data[x++]  = checkMap(material.alphaMap);                   // hasAlphaMap
    data[x++]  = checkMap(material.aoMap);                      // hasAoMap
    
    data[x++]  = checkMap(material.specularMap);                // hasSpecularMap
    data[x++]  = checkMap(material.lightMap);                   // hasLightMap
    data[x++]  = checkMap(material.bumpMap);                    //hasBumpMap
    data[x++]  = checkMap(material.normalMap);                  //hasNormalMap
    
    data[x++] = material is MeshStandardMaterial || 
    material is MeshPhysicalMaterial || 
    material is MeshLambertMaterial || 
    material is MeshMatcapMaterial || 
    material is MeshNormalMaterial || 
    material is MeshToonMaterial || 
    material is MeshPhongMaterial?checkMap(material.displacementMap):0;            // 7: hasDisplacementMap
    data[x++] = checkMap(material.roughnessMap);               //hasRoughnessMap
    data[x++] = checkMap(material.metalnessMap);               //hasMetalnessMap
    data[x++] = checkMap(material.emissiveMap);                // hasEmissiveMap
    
    data[x++] = checkMap(material.clearcoatMap);               // hasClearcoatMap
    data[x++] = checkMap(material.clearcoatNormalMap);         // hasClearcoatNormalMap
    data[x++] = checkMap(material.clearcoatRoughnessMap);      // hasClearcoatRoughnessMap
    data[x++] = checkMap(material.sheenColorMap);              // hasSheenColorMap
    
    data[x++] = checkMap(material.sheenRoughnessMap);          // hasSheenRoughnessMap
    data[x++] = checkMap(material.transmissionMap);            // hasTransmissionMap
    data[x++] = checkMap(material.thicknessMap);               // hasThicknessMap
    data[x++] = checkMap(material.iridescenceMap);             // hasIridescenceMap
    
    data[x++] = checkMap(material.iridescenceThicknessMap);    //hasIridescenceThicknessMap
    data[x++] = checkMap(material.gradientMap);                //hasGradientMap
    data[x++] = checkMap(material.matcap);                     //hasMatcap
    
    // flag5 w
    if(object is BatchedMesh){
      data[x++] = 1;
    }
    else if(object is InstancedMesh){
      data[x++] = object.instanceColor!=null?3:2;
    }
    else{
      data[x++] = 0;
    } 
  }

  /// Maps WebGL linecap strings ('round', 'square', 'butt') to integer tokens.
  static int mapLineCap(String? cap) {
    if (cap == null) return LineCap.round.index;
    
    // Clean string inputs to handle accidental case variances
    final normalized = cap.toLowerCase().trim();
    
    if (normalized == 'square') return LineCap.square.index;
    if (normalized == 'butt') return LineCap.butt.index;
    
    return LineCap.round.index; // Default WebGL fallback
  }

  /// Maps WebGL linejoin strings ('round', 'bevel', 'miter') to integer tokens.
  static int mapLineJoin(String? join) {
    if (join == null) return LineJoint.round.index;
    
    final normalized = join.toLowerCase().trim();
    
    if (normalized == 'bevel') return LineJoint.bevel.index;
    if (normalized == 'miter') return LineJoint.miter.index;
    
    return LineJoint.round.index; // Default WebGL fallback
  }
}


