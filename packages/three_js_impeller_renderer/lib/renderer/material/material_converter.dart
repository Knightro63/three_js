import 'dart:ui';
import 'package:three_js_core/three_js_core.dart';
import '../../lighting/ibl/prefilter_mip_selector.dart';
import '../uniform_buffer_manager.dart';

class MaterialConverter {
  static MaterialUniformData convert(
    Material material,
    Camera camera,
    [int? mipCount]
  ){
    material.color.alpha = material.opacity;

    if (material is MeshBasicMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: material.envMapIntensity ?? 1.0, 
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        emissiveColor: material.emissive,
        emissiveIntensity: material.emissiveIntensity,
        reflectivity: material.reflectivity ?? 0.5,
        ior: material.ior ?? 1.5,
        clippingPlanes: material.clippingPlanes??[],
      );
    } 
    else if (material is MeshLambertMaterial || material is MeshGouraudMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0, // Lambert operates purely via diffuse profile scattering
        metalness: 0.0,
        envIntensity: material.envMapIntensity ?? 1.0,
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        emissiveColor: material.emissive,
        emissiveIntensity: material.emissiveIntensity,
        reflectivity: material.reflectivity ?? 0.5,
        aoMapIntensity: material.aoMapIntensity ?? 1.0,
        lightMapIntensity: material.lightMapIntensity ?? 1.0,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is LineBasicMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        linewidth: material.linewidth ?? 1.0,
        linecap: material.linecap ?? '',   
        linejoin: material.linejoin ?? '', 
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is ShaderMaterial || material is RawShaderMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is SpriteMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        rotation: material.rotation, // Optional expansion parameter
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is LineDashedMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0, 
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        linewidth: material.linewidth ?? 1.0,
        dashSize: material.dashSize ?? 3.0,
        gapSize: material.gapSize ?? 1.0,
        scale: material.scale ?? 1.0,
        linecap: material.linecap ?? '',
        linejoin: material.linejoin ?? '',
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is ShadowMaterial) {
      return MaterialUniformData(
        baseColor: material.color, // WebGL maps visibility tracking into opacity constraints
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is PointsMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        scale: material.size ?? 1.0, // Packs the particle size dimension directly
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshPhongMaterial) {
      final double phongShininess = material.shininess ?? 30.0;

      return MaterialUniformData(
        baseColor: material.color,
        // WebGL converts shininess into an inverse microfacet profile approximation
        roughness: clampDouble(1.0 - (phongShininess / 120.0), 0.03, 0.3),
        metalness: 0.0,
        envIntensity: material.envMapIntensity ?? 1.0,
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading, // Crucial for low-poly specular allocations
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        shininess: phongShininess, 
        specularColor: material.specular,
        specularIntensity: material.specularIntensity ?? 1.0,
        emissiveColor: material.emissive,
        emissiveIntensity: material.emissiveIntensity,
        bumpScale: material.bumpScale ?? 1.0,
        aoMapIntensity: material.aoMapIntensity ?? 1.0,
        lightMapIntensity: material.lightMapIntensity ?? 1.0,
        reflectivity: material.reflectivity ?? 0.5,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshMatcapMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        bumpScale: material.bumpScale ?? 1.0,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshDistanceMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: 1,
        flatShading: false,
        alphaTest: material.alphaTest,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshToonMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 3.0, // Step quantization threshold logic token
        envIntensity: 0.0,
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        bumpScale: material.bumpScale ?? 1.0,
        aoMapIntensity: material.aoMapIntensity ?? 1.0,
        lightMapIntensity: material.lightMapIntensity ?? 1.0,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshDepthMaterial || material is MeshNormalMaterial) {
      return MaterialUniformData(
        baseColor: material.color,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading,
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    } 
    else if (material is MeshStandardMaterial) {
      final double roughness = PrefilterMipSelector.clamp01(material.roughness);
      final emissive = material.emissive;
      
      // Extract custom parameters down into matching WebGL options safely
      final clearcoat = material.clearcoat;
      final clearcoatRoughness = material.clearcoatRoughness ?? 0.0;
      final sheen = material.sheen;
      final sheenRoughness = material.sheenRoughness;
      final transmission = material.transmission;
      final attenuationDistance = material.attenuationDistance ?? 0.0;
      final attenColor = material.attenuationColor;
      final ior = material.ior ?? 1.5;

      return MaterialUniformData(
        baseColor: material.color,
        roughness: roughness,
        metalness: material.metalness,
        envIntensity: material.envMapIntensity ?? 0,
        prefilterMipCount: mipCount ?? 1,
        flatShading: material.flatShading, // Ensures modern PBR handles flat derivatives correctly
        alphaTest: material.alphaTest,
        wireframe: material.wireframe,
        clearcoat: clearcoat,
        clearcoatRoughness: clearcoatRoughness,
        sheen: sheen,
        sheenRoughness: sheenRoughness,
        transmission: transmission,
        ior: ior,
        attenuationDistance: attenuationDistance,
        attenuationColor: attenColor,
        emissiveColor: emissive,
        emissiveIntensity: material.emissiveIntensity,
        bumpScale: material.bumpScale ?? 1.0,
        aoMapIntensity: material.aoMapIntensity ?? 1.0,
        lightMapIntensity: material.lightMapIntensity ?? 1.0,
        reflectivity: material.reflectivity ?? 0.5,
        clippingPlanes: material.clipping == true ?material.clippingPlanes??[]:[],
      );
    }
    else {
      throw ("Material ${material.runtimeType} has not been converted yet. Please use another Material.");
    }
  }

  static MeshBasicMaterial toGpuBasicFallback(MeshStandardMaterial material) {
    return MeshBasicMaterial()
      ..name = material.name
      ..color = material.color.clone()
      ..map = material.map
      ..transparent = material.transparent
      ..opacity = material.opacity
      ..vertexColors = material.vertexColors
      ..depthTest = material.depthTest
      ..depthWrite = material.depthWrite
      ..colorWrite = material.colorWrite
      ..side = material.side
      ..blending = material.blending
      ..wireframe = material.wireframe
      ..wireframeLinewidth = material.wireframeLinewidth
      ..needsUpdate = true;
  }
}